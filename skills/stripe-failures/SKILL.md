---
allowed-tools: Bash, Read, Grep, Glob, Agent
argument-hint: [dugsi|mahad|donation|all] [YYYY-MM]
description: Investigate all failed Stripe payments for a month with root cause diagnosis
---

# Stripe Payment Failures Investigation

Investigate: $ARGUMENTS

## Setup

Parse arguments:
- **Account**: first arg — `dugsi`, `mahad`, `donation`, or `all` (default: `all`)
- **Month**: second arg — `YYYY-MM` format (default: current month)

Account-to-key mapping:
- `dugsi` → `STRIPE_DUGSI_SECRET_KEY_LIVE`
- `mahad` → `STRIPE_MAHAD_SECRET_KEY_LIVE`
- `donation` → `STRIPE_DONATION_SECRET_KEY_LIVE`
- `all` → run for all three accounts

## Step 1: Load API Keys

Try the Stripe CLI first. If it fails (expired auth), fall back to curl with `.env.local` keys.

**Check CLI auth:**
```bash
stripe charges list --limit=1 2>&1
```

If the CLI works (no auth error), use `stripe` commands for all API calls in subsequent steps.

If the CLI returns an auth error (expired key, "run `stripe login`"), fall back to curl:
```bash
DUGSI_KEY=$(grep '^STRIPE_DUGSI_SECRET_KEY_LIVE=' .env.local | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d '\r\n')
MAHAD_KEY=$(grep '^STRIPE_MAHAD_SECRET_KEY_LIVE=' .env.local | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d '\r\n')
DONATION_KEY=$(grep '^STRIPE_DONATION_SECRET_KEY_LIVE=' .env.local | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d '\r\n')
```

For the rest of this command, "API call" means:
- **CLI mode**: `stripe [resource] list --limit=N ...`
- **curl mode**: `curl -s -G -u "$KEY:" "https://api.stripe.com/v1/[resource]" -d "limit=N" -d "param=value"`
- IMPORTANT: Always use `-G` with `-d` params for GET requests. Never put `[gte]` brackets directly in URLs — the shell eats them.

## Step 2: Calculate Date Range

Convert the target month to Unix timestamps for Stripe API filtering:
```python
import calendar, datetime
year, month = YYYY, MM
start = int(datetime.datetime(year, month, 1).timestamp())
end = int(datetime.datetime(year, month, calendar.monthrange(year, month)[1], 23, 59, 59).timestamp())
```

## Step 3: Fetch All Charges (Successes + Failures)

For each target account, fetch ALL charges for the month:

**curl mode:**
```bash
curl -s -u "$KEY:" "https://api.stripe.com/v1/charges?limit=100&created[gte]=$START&created[lte]=$END"
```

Count total charges and separate into `succeeded` vs `failed`.
Record the success/fail ratio for the report header.

Also fetch open/past-due invoices:
- Endpoint: `/v1/invoices?status=open&limit=100&created[gte]=$START&created[lte]=$END`

## Step 4: Deep Investigation Per Failure

For EACH failed charge/payment, gather:

1. **Payment Intent** — `GET /v1/payment_intents/{pi_id}`
   - Status, amount, error code, decline code, network advice
2. **Customer** — `GET /v1/customers/{cus_id}`
   - Name, email, delinquent status
3. **Subscription** — `GET /v1/subscriptions?customer={cus_id}`
   - Status (active/past_due/canceled), plan, amount
4. **Invoice** — from payment_details.order_reference or latest_invoice
   - Attempt count, next retry date, hosted payment URL
5. **Payment Method** — from last_payment_error.payment_method
   - Card brand, last4, expiration, funding type

**If there are 3+ failures, use the Agent tool to investigate in parallel** — one agent per failure cluster (group by customer).

## Step 5: Root Cause Classification

Classify each failure into one of these categories:

| Category | Error Codes | Likely Cause | Action Needed |
|----------|------------|--------------|---------------|
| Card Replaced | `incorrect_number` | Card reissued with new number | Customer must update payment method |
| Card Expired | `expired_card` | Card past expiration date | Customer must update payment method |
| Insufficient Funds | `insufficient_funds`, `card_declined` | Not enough balance | May resolve on retry, or customer needs to add funds |
| Bank Decline | `do_not_honor`, `generic_decline` | Bank refused for unspecified reason | Customer should contact their bank |
| Authentication Required | `authentication_required` | SCA/3DS needed | Customer must complete authentication |
| Processing Error | `processing_error` | Temporary Stripe/bank issue | Will likely resolve on retry |
| Fraud Suspected | `fraudulent`, `stolen_card` | Bank flagged as suspicious | Customer must contact bank |

Check the `advice_code` field:
- `do_not_try_again` — retries will fail, customer action required
- `try_again_later` — transient, may resolve on retry

## Step 6: Churn Risk Assessment

Beyond failed charges this month, identify at-risk subscriptions:

### 6a. Past-Due Subscriptions
Fetch subscriptions with `status=past_due` for each account:
```bash
curl -s -u "$KEY:" "https://api.stripe.com/v1/subscriptions?status=past_due&limit=100"
```
Include these even if they had no failed charge this month (e.g. customer removed their card before a charge attempt).

### 6b. Stale Subscriptions (No Payment in 7+ Days)
For active subscriptions, check if the latest invoice is paid:
```bash
curl -s -G -u "$KEY:" "https://api.stripe.com/v1/subscriptions" -d "status=active" -d "limit=100"
```

For each active subscription with latest_invoice `status != "paid"`, fetch the invoice and check:
1. **Invoice age**: Calculate `now - invoice.created`. If less than 7 days, this is likely a normal ACH payment still in transit — do NOT flag it.
2. **Payment intent/charge exists**: If `payment_intent` is null and `charge` is null, the payment hasn't been attempted yet (ACH scheduling delay) — do NOT flag it.
3. **Failed charge**: If there IS a payment_intent with `status = requires_payment_method` or a failed charge, this IS a problem — flag it.

IMPORTANT: ACH bank payments take 4-7 business days to settle. A freshly created "open" invoice with no charge attached is NORMAL for ACH, not a failure. Only flag invoices that are open AND older than 7 days AND have either a failed charge or no payment attempt after 7 days.

Also check for invoices marked `uncollectible` — these are always a problem regardless of age.

Combine 6a and 6b into a "Churn Risk" section in the report.

## Step 7: Database Cross-Reference

For each affected customer, check the local database:

```bash
npx prisma db execute --stdin <<SQL
SELECT ba.id, ba."stripeCustomerId", p.name, p.email
FROM "BillingAccount" ba
JOIN "Profile" p ON ba."profileId" = p.id
WHERE ba."stripeCustomerId" = 'cus_XXX';
SQL
```

Check if there are active BillingAssignments for the subscription.

## Step 8: Output Summary

Sort all failures by **amount descending** (highest dollar risk first).

### Header
```
## Stripe Payment Failures Report — [Month Year]
**Account:** [Dugsi/Mahad/Donation/All]
**Period:** [Start] to [End]
**Payment success rate:** [X] of [Y] payments succeeded ([Z]%)
**Total failures:** [N]
**Total amount at risk:** $[sum]
```

### Per-Failure Detail
For each failure:

```
### [N]. [Customer Name] — $[amount] ([account: Dugsi/Mahad/Donation])
| Field | Value |
|-------|-------|
| Customer | [Name] ([email]) |
| Customer ID | [cus_xxx] |
| Amount | $[amount] |
| Card | [brand] ending [last4], exp [MM/YYYY] |
| Error | [error_code] — [message] |
| Decline Code | [decline_code] (network: [network_code]) |
| Network Advice | [retry/do_not_retry] |
| Subscription | [sub_id] — [status] |
| Invoice Attempts | [N] |
| Next Retry | [date or "none scheduled"] |
| Payment Link | [hosted_invoice_url if available] |
| **Root Cause** | **[classification from Step 5]** |
| **Action Required** | **[specific action]** |
```

### Churn Risk Section
```
## Churn Risk

| Customer | Account | Subscription | Status | Last Successful Payment | Days Overdue | Amount/mo |
|----------|---------|-------------|--------|------------------------|--------------|-----------|
| [Name] | [Dugsi/Mahad] | [sub_id] | past_due | [date] | [N] days | $[X] |
```

### Action Summary
```
## Action Summary

| Action Needed | Count | Customers | Total $/mo |
|---------------|-------|-----------|------------|
| Customer must update card | N | [names] | $X |
| Will likely resolve on retry | N | [names] | $X |
| Customer must contact bank | N | [names] | $X |
| At risk of churn (past_due) | N | [names] | $X |
| Stale (no payment 30+ days) | N | [names] | $X |
```

## Important Notes

- Use LIVE keys only (not test keys)
- Never log or display full API keys
- Handle pagination if >100 results (use `has_more` + `starting_after`)
- If Stripe returns rate limit errors, wait 1 second and retry once
- Group multiple failures for the same customer together
- Sort by amount descending (highest risk first)
- NEVER truncate hosted_invoice_url links — always output the full URL so they are clickable and functional
- Include the Stripe account label (Dugsi/Mahad/Donation) on every failure so it's clear which account it belongs to
