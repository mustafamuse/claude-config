---
allowed-tools: Bash, Read, Grep
argument-hint: [error|webhook|action|service] [--recent]
description: Analyze application logs for debugging
model: sonnet
---

# Log Analysis

Analyze logs with filter: $ARGUMENTS

## Log Sources

This project uses Pino structured logging. Sources include:
- `webhook` - Stripe webhook processing
- `action` - Server action execution
- `service` - Business logic services
- `api` - API route handlers
- `database` - DB operations
- `cron` - Scheduled jobs

## Instructions

1. **Identify Log Location**
   - Local dev: Terminal output (npm run dev)
   - Production: Vercel logs (`vercel logs --follow`)
   - Sentry: Error tracking dashboard

2. **Filter by Source/Level**
   - Pino levels: 10=trace, 20=debug, 30=info, 40=warn, 50=error
   - Look for `"source":"$ARGUMENTS"` in structured logs
   - Look for `"level":50` for errors, `"level":40` for warnings

3. **Common Log Patterns**

   | Pattern | Meaning |
   |---------|---------|
   | `"source":"webhook"` | Stripe webhook processing |
   | `"source":"action"` | Server action execution |
   | `"eventId":"evt_xxx"` | Stripe event ID |
   | `"requestId":"xxx"` | Request correlation ID |
   | `"subscriptionId":"sub_xxx"` | Stripe subscription |

4. **Error Analysis**
   - Extract stack traces
   - Correlate by `requestId`
   - Check for Sentry error ID

## Common Issues

| Log Pattern | Likely Cause | Solution |
|-------------|--------------|----------|
| "No person found for checkout" | Missing profile link | Manual linking in admin |
| "Subscription not found" | Webhook order issue | Check subscription.created |
| "PrismaError P2002" | Unique constraint | Check duplicate data |
| "Invalid signature" | Wrong webhook secret | Verify STRIPE_WEBHOOK_SECRET |
| "Event already processed" | Idempotency working | Normal, no action needed |

## Sentry Integration

Errors are sent to Sentry with `requestId` correlation:
- Check Sentry dashboard for grouped errors
- Use requestId to trace across logs and Sentry
- Look for breadcrumbs showing request flow

## Quick Commands

```bash
# Tail Vercel logs
vercel logs --follow

# Filter local logs for errors
npm run dev 2>&1 | grep -E '"level":50'

# Filter by webhook source
npm run dev 2>&1 | grep '"source":"webhook"'
```
