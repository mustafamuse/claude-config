---
description: Audit consistency of a pattern across the codebase using parallel agents
argument-hint: <pattern to audit> [n=number of agents, default 6]
---

# Council: Pattern Consistency Audit

Audit how consistently a specific pattern is applied across the codebase using parallel agents.

## Input

Pattern to audit: $ARGUMENTS

## Instructions

### Phase 1: Identify the Pattern

Determine what pattern the user wants to audit. Common examples:
- "ActionResult" - Do all server actions return ActionResult<T>?
- "DatabaseClient" - Do all queries accept a DatabaseClient parameter?
- "Zod validation" - Do all actions validate input with Zod?
- "error handling" - Do all actions use logError + ActionError?
- "webhook handler" - Do all webhooks use createWebhookHandler?
- "revalidatePath" - Do all mutations revalidate cache?

Use Glob and Grep to find ALL instances of the pattern and identify the canonical/correct implementation.

### Phase 2: Spawn Audit Agents

Launch **6 parallel Task agents** (or the number specified) using the Explore subagent type. Divide the codebase by feature area so each agent audits a different section:

**CRITICAL: Launch ALL agents in a SINGLE message with multiple Task tool calls for true parallelism.**

#### Agent Assignment Strategy:

Divide by top-level feature directories. For this codebase, typical splits:
1. **Mahad Admin Agent** - Audit pattern in `app/admin/mahad/` and `lib/services/mahad/`
2. **Dugsi Admin Agent** - Audit pattern in `app/admin/dugsi/` and `lib/services/dugsi/`
3. **Shared Services Agent** - Audit pattern in `lib/services/shared/` and `lib/services/webhooks/`
4. **Query Layer Agent** - Audit pattern in `lib/db/queries/`
5. **API/Webhook Agent** - Audit pattern in `app/api/` routes
6. **Utilities Agent** - Audit pattern in `lib/utils/`, `lib/validations/`, `lib/mappers/`

Each agent should:
- Find every instance where the pattern IS correctly applied (with file:line)
- Find every instance where the pattern SHOULD be applied but ISN'T (with file:line)
- Find variations or deviations from the canonical pattern
- Rate compliance: COMPLIANT, PARTIAL, MISSING, N/A

### Phase 3: Synthesize Audit Report

```markdown
## Pattern Consistency Audit: [Pattern Name]

### Canonical Pattern
[Show the correct implementation with file reference]

### Compliance Summary
| Area | Total | Compliant | Partial | Missing | Score |
|------|-------|-----------|---------|---------|-------|
| Mahad | X | X | X | X | X% |
| Dugsi | X | X | X | X | X% |
| ... | | | | | |
| **Total** | **X** | **X** | **X** | **X** | **X%** |

### Deviations Found
| File:Line | Status | Issue | Fix |
|-----------|--------|-------|-----|
| path:42 | PARTIAL | Missing error code | Add ERROR_CODES.X |
| path:88 | MISSING | No Zod validation | Add schema.parse() |

### Patterns of Non-Compliance
- Common reasons why the pattern is skipped
- Areas with lowest compliance

### Recommended Fixes (Priority Order)
1. [Highest impact fix]
2. [Next fix]
```

## Key Principles

- **Exhaustive**: Check EVERY instance, not a sample
- **Binary**: Each instance is compliant or not - no ambiguity
- **Actionable**: Every deviation has a specific fix
- **Prioritized**: Rank deviations by risk/impact
