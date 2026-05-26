---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [subscriptions|customers|--check]
description: Sync Stripe data with local database
model: sonnet
---

# Stripe Data Sync

Sync entity: $ARGUMENTS

## Current State

Check database subscription counts and Stripe CLI availability.

## Actions

### `--check` (default)
Compare Stripe and database states:

1. **List Stripe Subscriptions**
   ```bash
   stripe subscriptions list --status=active --limit=100
   ```

2. **Query Local Database**
   - Check Subscription table records
   - Compare counts and statuses

3. **Identify Discrepancies**
   - Missing in DB (orphaned in Stripe)
   - Status mismatches
   - Missing BillingAssignments

### `subscriptions`
Sync subscription data:
1. Fetch all active subscriptions from Stripe
2. Compare with local Subscription records
3. Show diff before applying changes
4. Update statuses, amounts, periods

### `customers`
Sync customer data:
1. Fetch Stripe customers
2. Match to BillingAccount records by stripeCustomerId
3. Verify email/name matches
4. Report unmapped customers

## Stripe CLI Commands Reference

```bash
# List subscriptions
stripe subscriptions list --status=active
stripe subscriptions list --status=canceled --limit=50

# Get specific subscription
stripe subscriptions retrieve sub_xxxxx

# List customers
stripe customers list --limit=100

# Get customer details
stripe customers retrieve cus_xxxxx

# List recent events
stripe events list --type=customer.subscription.updated
```

## Safety Notes

- Always show diff before making changes
- Log all sync operations
- Never delete local records - only update status
- Check program (Mahad vs Dugsi) before syncing

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Subscription in Stripe, not in DB | Webhook missed | Manual create or replay webhook |
| Status mismatch | Webhook processing failed | Update status manually |
| Missing BillingAssignment | Checkout had no profile match | Use admin UI to link |
| Wrong program | Customer in wrong Stripe account | Check stripeCustomerId prefix |
