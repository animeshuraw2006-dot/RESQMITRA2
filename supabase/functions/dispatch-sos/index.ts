import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'Authentication required' }, 401);
    const url = Deno.env.get('SUPABASE_URL');
    const anon = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID');
    const oneSignalRestApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY');
    if (!url || !anon || !serviceKey) return json({ error: 'Supabase server secrets are missing' }, 500);
    if (!oneSignalAppId || !oneSignalRestApiKey) return json({ error: 'OneSignal server secrets are missing. Configure ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY.' }, 500);

    const authClient = createClient(url, anon, { global: { headers: { Authorization: authHeader } } });
    const { data: { user }, error: authError } = await authClient.auth.getUser();
    if (authError || !user) return json({ error: 'Invalid session' }, 401);
    const body = await req.json();
    const category = String(body.category ?? '').toLowerCase();
    const priority = String(body.priority ?? 'normal');
    const lat = body.latitude == null ? null : Number(body.latitude);
    const lng = body.longitude == null ? null : Number(body.longitude);
    if (!['general', 'women', 'child'].includes(category)) return json({ error: 'Invalid category', received_category: category }, 400);
    if (!['normal', 'high_alert'].includes(priority)) return json({ error: 'Invalid priority' }, 400);
    if ((lat === null) !== (lng === null) || (lat !== null && (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng < -180 || lng > 180))) return json({ error: 'Invalid coordinates' }, 400);
    const clientRequestId = String(body.client_request_id ?? '');
    if (clientRequestId.length < 8 || clientRequestId.length > 160) return json({ error: 'Invalid request ID' }, 400);

    const service = createClient(url, serviceKey);
    const { data: dispatch, error: dispatchError } = await service.rpc('dispatch_emergency', {
      p_requester_id: user.id,
      p_client_request_id: clientRequestId,
      p_category: category,
      p_emergency_type: String(body.emergency_type ?? 'Emergency').slice(0, 120),
      p_priority: priority,
      p_instructions: String(body.instructions ?? '').slice(0, 2000),
      p_do_not_call: body.do_not_call === true,
      p_blood_group: String(body.blood_group ?? '').slice(0, 30),
      p_audio_requested: body.audio_requested === true,
      p_latitude: lat,
      p_longitude: lng,
      p_accuracy_meters: body.accuracy_meters == null ? null : Math.max(0, Math.min(Number(body.accuracy_meters), 100000)),
    });
    if (dispatchError) throw dispatchError;
    const emergencyId = String(dispatch?.id ?? '');
    if (!emergencyId) return json({ error: 'SOS was not created by database dispatch', dispatch }, 500);

    const { data: assignments, error: assignmentError } = await service
      .from('responder_assignments').select('responder_id').eq('emergency_id', emergencyId).eq('status', 'assigned');
    if (assignmentError) throw assignmentError;
    const responderIds = [...new Set((assignments ?? []).map((row) => row.responder_id).filter((id) => typeof id === 'string'))];
    if (responderIds.length === 0) {
      await service.from('notification_dispatch_logs').insert({
        emergency_id: emergencyId, status: 'no_eligible_responders', responder_count: 0,
        error_detail: { message: 'No verified and available responders were assigned.' },
      });
      return json({ ...dispatch, push_status: 'no_eligible_responders', push_sent: false, responder_count: 0, message: 'SOS saved, but no verified and available responders are assigned. Check responder_profiles.' }, 200);
    }

    const title = priority === 'high_alert' ? '🚨 RESQ-MITRA HIGH ALERT' : 'RESQ-MITRA Emergency nearby';
    const pushResponse = await fetch('https://api.onesignal.com/notifications?c=push', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Key ${oneSignalRestApiKey}` },
      body: JSON.stringify({
        app_id: oneSignalAppId,
        target_channel: 'push',
        // Created natively by MainActivity with high importance, vibration, and
        // the bundled high_alert_siren.ogg sound. Reinstall/update channel if needed.
        android_channel_id: 'resq_sos_alerts_v1',
        include_aliases: { external_id: responderIds },
        headings: { en: title },
        contents: { en: `${String(body.emergency_type ?? 'Emergency').slice(0, 120)}. Open RESQ-MITRA to view and accept the request.` },
        data: { type: 'sos', emergency_id: emergencyId, priority },
      }),
    });
    const pushBody = await pushResponse.json().catch(() => ({}));
    if (!pushResponse.ok) {
      console.error('OneSignal notification request failed', pushResponse.status, JSON.stringify(pushBody));
      await service.from('notification_dispatch_logs').insert({
        emergency_id: emergencyId, status: 'failed', responder_count: responderIds.length,
        error_detail: { http_status: pushResponse.status, provider_response: pushBody },
      });
      return json({ ...dispatch, push_status: 'failed', push_sent: false, responder_count: responderIds.length, notification_error: pushBody }, 200);
    }
    const recipients = Number(pushBody.recipients ?? 0);
    const pushStatus = recipients > 0 ? 'accepted_by_provider' : 'accepted_no_recipients';
    await service.from('notification_dispatch_logs').insert({
      emergency_id: emergencyId, status: pushStatus, responder_count: responderIds.length,
      provider_recipient_count: recipients, provider_notification_id: pushBody.id ?? null,
      error_detail: recipients > 0 ? null : { message: 'OneSignal accepted the request but reported zero recipients. Check device subscriptions and external IDs.' },
    });
    return json({ ...dispatch, push_status: recipients > 0 ? 'sent' : 'accepted_by_onesignal_no_confirmed_recipients', push_sent: recipients > 0, responder_count: responderIds.length, onesignal_recipients: recipients, onesignal_notification_id: pushBody.id ?? null }, 200);
  } catch (e) {
    console.error('dispatch-sos error', e);
    return json({ error: 'Unable to dispatch SOS', detail: String(e?.message ?? e) }, 400);
  }
});
function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
}
