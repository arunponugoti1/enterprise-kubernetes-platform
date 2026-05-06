const PUBSUB_TOPIC_ID   = process.env.PUBSUB_TOPIC_ID   || '';
const NOTIFICATION_URL  = process.env.NOTIFICATION_URL  || 'http://notification-service:8080/events';

let _topic;
async function getTopic() {
  if (_topic) return _topic;
  if (!PUBSUB_TOPIC_ID) return null;
  const { PubSub } = require('@google-cloud/pubsub');
  _topic = new PubSub().topic(PUBSUB_TOPIC_ID);
  return _topic;
}

async function publish(event) {
  try {
    const topic = await getTopic();
    if (topic) {
      await topic.publishMessage({
        data: Buffer.from(JSON.stringify(event)),
        attributes: { eventType: event.type },
      });
    } else {
      // Local docker-compose fallback.
      const res = await fetch(NOTIFICATION_URL, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(event),
      });
      if (!res.ok) console.error(`publish failed: ${res.status} ${await res.text()}`);
    }
  } catch (err) {
    console.error(`publish error: ${err.message}`);
  }
}

module.exports = { publish };
