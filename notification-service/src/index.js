const express = require('express');

const app = express();
app.use(express.json());

const PORT = Number(process.env.PORT || 8080);
const PUBSUB_SUBSCRIPTION_ID = process.env.PUBSUB_SUBSCRIPTION_ID || '';

const recent = [];
const MAX_RECENT = 100;

app.get('/healthz', (_req, res) => res.json({ status: 'ok' }));
app.get('/readyz',  (_req, res) => res.json({ status: 'ready' }));

// HTTP endpoint retained for local docker-compose development.
app.post('/events', (req, res) => {
  const event = req.body || {};
  dispatch(event);
  recent.unshift({ received_at: new Date().toISOString(), event, source: 'http' });
  if (recent.length > MAX_RECENT) recent.pop();
  res.status(202).json({ status: 'accepted' });
});

app.get('/notifications', (_req, res) => res.json(recent));

function dispatch(event) {
  switch (event.type) {
    case 'transaction.completed':
      console.log(`[NOTIFY] OK   ${JSON.stringify(event)}`);
      break;
    case 'transaction.failed':
      console.log(`[NOTIFY] FAIL ${event.reason} ${JSON.stringify(event)}`);
      break;
    default:
      console.log(`[NOTIFY] event ${JSON.stringify(event)}`);
  }
}

async function startPubSubPull() {
  if (!PUBSUB_SUBSCRIPTION_ID) return;
  const { PubSub } = require('@google-cloud/pubsub');
  const subscription = new PubSub().subscription(PUBSUB_SUBSCRIPTION_ID);

  subscription.on('message', (msg) => {
    try {
      const event = JSON.parse(msg.data.toString());
      dispatch(event);
      recent.unshift({ received_at: new Date().toISOString(), event, source: 'pubsub' });
      if (recent.length > MAX_RECENT) recent.pop();
    } catch (err) {
      console.error('bad pubsub message:', err.message);
    } finally {
      msg.ack();
    }
  });

  subscription.on('error', (err) => console.error('pubsub error:', err.message));
  console.log(`Pub/Sub pull active: ${PUBSUB_SUBSCRIPTION_ID}`);
}

async function main() {
  await startPubSubPull();
  app.listen(PORT, () => console.log(`notification-service listening on ${PORT}`));
}

main();
