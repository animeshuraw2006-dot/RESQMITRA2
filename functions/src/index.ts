import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

initializeApp();
const db = getFirestore();
const categories = new Set(['General SOS', 'Women SOS', 'Child SOS', 'HIGH ALERT SOS']);
const bloodGroups = new Set(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Any blood group']);
const activeStatuses = new Set(['pending', 'accepted', 'en_route', 'arrived']);

function requireUid(request: { auth?: { uid: string } | null }): string {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in before submitting or managing an SOS.');
  return request.auth.uid;
}
function text(value: unknown, field: string, max: number): string {
  if (typeof value !== 'string' || value.length > max) throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  return value.trim();
}
function validLocation(data: Record<string, unknown>): boolean {
  const lat = data.latitude; const lng = data.longitude;
  return lat === null || lat === undefined || lng === null || lng === undefined ||
    (typeof lat === 'number' && typeof lng === 'number' && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180);
}

/** Creates an incident once per request ID. Private notes and exact coordinates are kept separately. */
export const createSos = onCall({ enforceAppCheck: false, timeoutSeconds: 15 }, async (request) => {
  const uid = requireUid(request);
  const data = request.data as Record<string, unknown>;
  const requestId = text(data.requestId, 'requestId', 100);
  const category = text(data.category, 'category', 40);
  const emergencyType = text(data.emergencyType, 'emergencyType', 100);
  const instructions = text(data.instructions ?? '', 'instructions', 2000);
  const bloodGroup = text(data.bloodGroup ?? 'Any blood group', 'bloodGroup', 20);
  if (!categories.has(category)) throw new HttpsError('invalid-argument', 'Unsupported SOS category.');
  if (!bloodGroups.has(bloodGroup)) throw new HttpsError('invalid-argument', 'Unsupported blood group.');
  if (!validLocation(data)) throw new HttpsError('invalid-argument', 'Invalid location coordinates.');
  if (category === 'General SOS' && emergencyType.toLowerCase().includes('other') && !instructions) {
    throw new HttpsError('invalid-argument', 'Please describe the emergency.');
  }
  const publicRef = db.collection('sosRequests').doc(requestId);
  const privateRef = db.collection('sosPrivate').doc(requestId);
  const urgency = data.highAlert === true ? 'high_alert' :
    /danger|medical|blood|fire|accident/i.test(emergencyType) ? 'critical' :
    category === 'Women SOS' || category === 'Child SOS' ? 'high' : 'normal';
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(publicRef);
    if (existing.exists) {
      if (existing.data()?.requesterId !== uid) throw new HttpsError('already-exists', 'Request ID already used.');
      return; // Idempotent replay by the same owner.
    }
    const location = typeof data.latitude === 'number' && typeof data.longitude === 'number' ? {
      latitude: data.latitude, longitude: data.longitude,
      accuracyMeters: typeof data.accuracyMeters === 'number' ? data.accuracyMeters : null,
      capturedAt: Timestamp.now(),
    } : null;
    tx.create(publicRef, {
      requesterId: uid, category, emergencyType, urgency, highAlert: data.highAlert === true,
      status: 'pending', acceptedResponderIds: [], createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(), expiresAt: Timestamp.fromDate(new Date(Date.now() + 2 * 60 * 60 * 1000)), schemaVersion: 2,
    });
    tx.create(privateRef, {
      requesterId: uid, instructions, doNotCall: data.doNotCall === true,
      bloodGroup, audioRequested: data.audioRequested === true, location,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { incidentId: requestId, status: 'server_accepted' };
});

/** Atomically assigns one verified, active responder to a pending incident. */
export const claimSos = onCall({ timeoutSeconds: 15 }, async (request) => {
  const uid = requireUid(request);
  const incidentId = text(request.data?.incidentId, 'incidentId', 100);
  const responderRef = db.collection('responders').doc(uid);
  const incidentRef = db.collection('sosRequests').doc(incidentId);
  await db.runTransaction(async (tx) => {
    const responder = await tx.get(responderRef);
    const incident = await tx.get(incidentRef);
    if (!responder.exists || responder.data()?.verified !== true || responder.data()?.active !== true) {
      throw new HttpsError('permission-denied', 'A verified active responder account is required.');
    }
    if (!incident.exists) throw new HttpsError('not-found', 'Incident not found.');
    const data = incident.data()!;
    const accepted = Array.isArray(data.acceptedResponderIds) ? data.acceptedResponderIds as string[] : [];
    if (data.status !== 'pending' || accepted.length > 0) {
      if (accepted.includes(uid)) return; // Idempotent claim retry.
      throw new HttpsError('failed-precondition', 'This incident has already been claimed or is no longer open.');
    }
    tx.update(incidentRef, { status: 'accepted', acceptedResponderIds: [uid], claimedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  });
  return { incidentId, status: 'accepted' };
});

/** Enforces owner cancellation and responder-only progression on the server. */
export const updateSosStatus = onCall({ timeoutSeconds: 15 }, async (request) => {
  const uid = requireUid(request);
  const incidentId = text(request.data?.incidentId, 'incidentId', 100);
  const status = text(request.data?.status, 'status', 30);
  const allowed = new Set(['en_route', 'arrived', 'cancelled', 'safe', 'resolved']);
  if (!allowed.has(status)) throw new HttpsError('invalid-argument', 'Unsupported status transition.');
  const incidentRef = db.collection('sosRequests').doc(incidentId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(incidentRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Incident not found.');
    const data = snap.data()!;
    const owner = data.requesterId === uid;
    const responders = Array.isArray(data.acceptedResponderIds) ? data.acceptedResponderIds as string[] : [];
    const responder = responders.includes(uid);
    if (owner && !['cancelled', 'safe'].includes(status)) throw new HttpsError('permission-denied', 'Owners may only cancel or mark themselves safe.');
    if (!owner && !responder) throw new HttpsError('permission-denied', 'Only the owner or assigned responder can update this incident.');
    if (responder && !owner && !['en_route', 'arrived', 'resolved'].includes(status)) throw new HttpsError('permission-denied', 'Invalid responder transition.');
    if (!activeStatuses.has(String(data.status))) throw new HttpsError('failed-precondition', 'Incident is no longer active.');
    if (owner) {
      if (status === 'cancelled' && data.status === 'arrived') throw new HttpsError('failed-precondition', 'Contact the assigned responder before cancelling an incident after arrival.');
    } else {
      const transitions: Record<string, string[]> = { accepted: ['en_route', 'arrived', 'resolved'], en_route: ['arrived', 'resolved'], arrived: ['resolved'] };
      if (!(transitions[String(data.status)] ?? []).includes(status)) throw new HttpsError('failed-precondition', 'Invalid incident state transition.');
    }
    tx.update(incidentRef, { status, updatedAt: FieldValue.serverTimestamp() });
  });
  return { incidentId, status };
});
