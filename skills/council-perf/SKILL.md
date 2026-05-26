---
description: Deep performance analysis of a page or feature using parallel agents
argument-hint: <page or feature path> [n=number of agents, default 6]
---

# Council: Performance Deep Dive

Analyze performance characteristics of a page or feature from multiple angles using parallel agents.

## Input

Page or feature to analyze: $ARGUMENTS

## Instructions

### Phase 1: Identify the Target

Locate the target page/feature. Read the page component and trace its data flow:
- What components does it render?
- What data does it fetch?
- Which components are Server vs Client?

Use Glob and Grep to map the full component and data dependency tree.

### Phase 2: Spawn Performance Agents

Launch **6 parallel Task agents** (or the number specified) using the Explore subagent type. Each agent analyzes a different performance dimension:

**CRITICAL: Launch ALL agents in a SINGLE message with multiple Task tool calls for true parallelism.**

#### Agent Angles:

1. **Data Fetching Agent** - Analyze all database queries on the page. Look for:
   - N+1 query patterns (loops calling DB)
   - Missing `select` clauses (over-fetching columns)
   - Missing or excessive `include` (over-fetching relations)
   - Sequential queries that could be parallelized with `Promise.all`
   - Missing indexes for WHERE/ORDER BY clauses

2. **Component Tree Agent** - Analyze the component hierarchy. Look for:
   - Client components that could be Server components
   - Large client component trees (bundle size impact)
   - Components re-rendering unnecessarily
   - Missing Suspense boundaries for streaming
   - Props drilling that should use server-side data

3. **Bundle Size Agent** - Analyze client-side JavaScript impact. Look for:
   - `'use client'` directives and what they pull into the bundle
   - Heavy imports (date libraries, charting, etc.)
   - Dynamic imports that should be used but aren't
   - Shared component imports pulling in unnecessary deps

4. **Caching Agent** - Analyze caching strategy. Look for:
   - `revalidatePath` / `revalidateTag` usage patterns
   - Missing cache headers or fetch cache options
   - Stale data risks from aggressive caching
   - Over-invalidation (revalidating too broadly)
   - Opportunities for `unstable_cache` or React `cache()`

5. **Rendering Agent** - Analyze rendering performance. Look for:
   - Waterfall patterns (sequential async components)
   - Large list rendering without virtualization
   - Missing `loading.tsx` or Suspense for slow segments
   - Layout shifts from async content
   - Heavy computation in render path

6. **Network Agent** - Analyze network and API efficiency. Look for:
   - Server actions making external API calls (Stripe, etc.)
   - Missing error retries for flaky external services
   - Large payloads serialized between server/client
   - Redirect chains in routing

### Phase 3: Synthesize Performance Report

```markdown
## Performance Analysis: [Page/Feature]

### Component Tree
[Text diagram of server/client component hierarchy]

### Data Flow
[Text diagram showing queries and their dependencies]

### Issues Found
| # | Category | Severity | File:Line | Issue | Impact |
|---|----------|----------|-----------|-------|--------|
| 1 | Data | HIGH | path:42 | N+1 in loop | Adds ~Nms per item |
| 2 | Bundle | MEDIUM | path:10 | Heavy import | +50kb client JS |

### Optimization Opportunities
1. **[Issue]** - [What to change] - [Expected improvement]
2. ...

### Quick Wins (Low Effort, High Impact)
- [ ] Fix 1
- [ ] Fix 2

### Larger Improvements (Higher Effort)
- [ ] Improvement 1
- [ ] Improvement 2
```

## Key Principles

- **Measurable**: Quantify impact where possible (query count, bundle size, etc.)
- **Specific**: Point to exact file:line, not vague suggestions
- **Prioritized**: Severity based on real user impact
- **Practical**: Focus on fixes that are worth the effort
