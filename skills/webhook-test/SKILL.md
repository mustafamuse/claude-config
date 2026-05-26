---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [event-type|--list|--replay]
description: Test Stripe webhooks locally
model: sonnet
---

# Webhook Testing

Test webhook: $ARGUMENTS

## Prerequisites Check

- Stripe CLI installed: !`which stripe || echo "Not installed - run: brew install stripe/stripe-cli/stripe"`
- Dev server running on port 3000

## Actions

### List Recent Events
If `$ARGUMENTS` is `--list`:
```bash
stripe events list --limit 10
```

### Forward Webhooks
Start webhook forwarding to local dev server:
```bash
stripe listen --forward-to localhost:3000/api/webhook
```

For Dugsi webhooks:
```bash
stripe listen --forward-to localhost:3000/api/webhook/dugsi
```

### Trigger Specific Event
If `$ARGUMENTS` is an event type:
```bash
stripe trigger $ARGUMENTS
```

**Common events to test:**
- `checkout.session.completed` - New subscription via checkout
- `customer.subscription.created` - Subscription created
- `customer.subscription.updated` - Subscription changed
- `customer.subscription.deleted` - Subscription canceled
- `invoice.payment_succeeded` - Successful payment
- `invoice.payment_failed` - Failed payment
- `invoice.finalized` - Invoice ready for payment

### Replay Event
If `$ARGUMENTS` is `--replay [event_id]`:
```bash
stripe events resend [event_id]
```

## Webhook Handler Locations

| Program | Route | Handlers |
|---------|-------|----------|
| Mahad | `/app/api/webhook/route.ts` | `lib/services/webhooks/event-handlers.ts` |
| Dugsi | `/app/api/webhook/dugsi/route.ts` | Same event handlers, different account |

## Testing Flow

1. Start dev server: `npm run dev`
2. Start webhook forwarding: `stripe listen --forward-to localhost:3000/api/webhook`
3. Copy webhook signing secret from CLI output
4. Trigger test event: `stripe trigger checkout.session.completed`
5. Check terminal logs for processing
6. Verify database changes in Prisma Studio

## Debugging Tips

- Check `WebhookEvent` table for processed events
- Look for idempotency skips in logs
- Verify Stripe account (Mahad vs Dugsi) is correct
- Check subscription/customer IDs match expected program
