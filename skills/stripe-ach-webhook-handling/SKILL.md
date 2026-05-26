---
name: stripe-ach-webhook-handling
description: Stripe ACH and card payment error handling with webhooks. Use when implementing webhook endpoints, handling ACH microdeposit verification, processing payment failures, or setting up idempotent event handling. Covers signature verification, retry mechanisms, and ACH-specific error codes.
---

# Stripe ACH & Webhook Error Handling

Handle ACH payments, card payments, and webhook events with proper error handling and idempotency.

## When to Apply

- Setting up webhook endpoints for payment processing
- Handling ACH microdeposit verification failures
- Implementing idempotent event processing
- Processing `setup_intent.succeeded` for ACH payments

## Critical Rules

**Webhook Signature Verification**: Always verify signatures to prevent malicious requests

```javascript
// WRONG - No signature verification
app.post('/webhook', (req, res) => {
  const event = req.body;
  // Process event directly - vulnerable to attacks
});

// RIGHT - Verify signature first
app.post('/webhook', express.raw({type: 'application/json'}), (req, res) => {
  const signature = req.headers['stripe-signature'];
  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    return res.sendStatus(400);
  }
  // Now process verified event
});
```

**Idempotent Event Processing**: Prevent duplicate processing with status tracking

```javascript
// WRONG - Process every event
if (event.type === 'payment_intent.succeeded') {
  fulfillOrder(paymentIntent.id);
}

// RIGHT - Check processing status first
if (event.type === 'payment_intent.succeeded') {
  if (is_processing_or_processed(event)) {
    console.log(`skipping event ${event.id}`);
  } else {
    mark_as_processing(event);
    fulfillOrder(paymentIntent.id);
    mark_as_processed(event);
  }
}
```

**ACH Microdeposit Error Codes**: Handle specific verification failures

```javascript
// Handle microdeposit verification failure
if (error.code === 'payment_method_microdeposit_verification_amounts_mismatch') {
  // Customer entered wrong amounts - show retry form
  showMicrodepositRetry(error.message);
}
```

## Key Patterns

### Webhook Event Handler

```javascript
app.post('/webhook', express.raw({type: 'application/json'}), (req, res) => {
  const signature = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body, 
      signature, 
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.log(`Webhook signature verification failed: ${err.message}`);
    return res.sendStatus(400);
  }

  switch (event.type) {
    case 'setup_intent.succeeded':
      handleSetupIntentSucceeded(event.data.object);
      break;
    case 'payment_intent.succeeded':
      handlePaymentSuccess(event.data.object);
      break;
    case 'payment_intent.payment_failed':
      handlePaymentFailure(event.data.object);
      break;
  }

  res.sendStatus(200);
});
```

### ACH Setup Intent Handler

```javascript
function handleSetupIntentSucceeded(setupIntent) {
  const customerId = setupIntent.customer;
  const paymentMethodId = setupIntent.payment_method;

  // Set as default payment method for ACH
  stripe.customers.update(customerId, {
    invoice_settings: {
      default_payment_method: paymentMethodId
    }
  });
}
```

### ACH Payment with Microdeposit Verification

```javascript
// Create PaymentIntent requiring microdeposits
const paymentIntent = await stripe.paymentIntents.create({
  amount: 1099,
  currency: 'usd',
  customer: customerId,
  payment_method_types: ['us_bank_account'],
  payment_method_options: {
    us_bank_account: {
      verification_method: 'microdeposits'
    }
  }
});

// Handle verification status
stripe.confirmUsBankAccountPayment(clientSecret)
  .then(({paymentIntent, error}) => {
    if (paymentIntent?.next_action?.type === 'verify_with_microdeposits') {
      showMicrodepositForm();
    } else if (paymentIntent?.status === 'processing') {
      showSuccessMessage();
    }
  });
```

### Idempotent Processing Functions

```javascript
function is_processing_or_processed(event) {
  // Check database for event status
  return db.events.findOne({
    stripe_event_id: event.id,
    status: { $in: ['processing', 'processed'] }
  });
}

function mark_as_processing(event) {
  db.events.upsert(
    { stripe_event_id: event.id },
    { status: 'processing', created_at: new Date() }
  );
}

function mark_as_processed(event) {
  db.events.update(
    { stripe_event_id: event.id },
    { status: 'processed', processed_at: new Date() }
  );
}
```

## Common Mistakes

- **Missing signature verification** — Always verify webhook signatures in production
- **No idempotency handling** — Events can be delivered multiple times
- **Wrong microdeposit error handling** — Check specific error codes like `payment_method_microdeposit_verification_amounts_mismatch`
- **Not handling ACH timing** — ACH payments take 1-4 business days to complete
- **Ignoring `setup_intent.succeeded`** — Required to set default payment methods for ACH