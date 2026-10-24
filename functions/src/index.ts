import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue, GeoPoint } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

initializeApp();
const db = getFirestore();

// Sends a data-only emergency alert to online responders. Client UI should show
// the alert and play the siren only after notification permission is granted.
// This is a broad first-stage fanout; production deployments should add geohash
// radius queries, rate limiting, abuse detection and delivery monitoring.
export const dispatchEmergencyAlert = onDocumentCreated('emergencies/{emergencyId}', async (event) => {
  const data = event.data?.data();
  if (!data || data.status !== 'open') return;
  const responders = await db.collection('responders').where('online', '==', true).limit(500).get();
  const tokens: string[] = [];
  responders.forEach((doc) => {
    const token = doc.get('fcmToken');
    if (typeof token === 'string' && token.length > 10) tokens.push(token);
  });
  if (!tokens.length) {
    logger.info('No online responder tokens for emergency', { emergencyId: event.params.emergencyId });
    return;
  }
  const loc = data.location as GeoPoint | undefined;
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    data: {
      kind: 'emergency', emergencyId: event.params.emergencyId,
      type: String(data.type ?? 'Emergency'), status: 'open',
      latitude: loc ? String(loc.latitude) : '', longitude: loc ? String(loc.longitude) : '',
    },
    android: { priority: 'high' },
  });
  logger.info('Emergency alert fanout completed', { emergencyId: event.params.emergencyId, successCount: response.successCount, failureCount: response.failureCount });
});

export const auditEmergencyStatus = onDocumentUpdated('emergencies/{emergencyId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  await db.collection('emergencies').doc(event.params.emergencyId).collection('audit').add({
    from: before.status ?? null, to: after.status ?? null,
    actorUid: event.authId ?? 'system', at: FieldValue.serverTimestamp(),
  });
});
