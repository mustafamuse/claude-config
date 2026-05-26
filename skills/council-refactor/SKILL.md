---
description: Assess refactoring feasibility of a codebase area using parallel agents
argument-hint: <area to refactor> [n=number of agents, default 6]
---

# Council: Refactoring Feasibility Analysis

Assess the feasibility, risk, and approach for refactoring a codebase area using parallel agents.

## Input

Area to refactor: $ARGUMENTS

## Instructions

### Phase 1: Scope the Refactor

Identify what the user wants to refactor. Read the target code and understand:
- Current implementation and its problems
- All files that touch this code (callers, importers, tests)
- Why refactoring is needed (duplication, complexity, wrong abstraction, etc.)

Use Glob and Grep to map the full dependency graph of the target area.

### Phase 2: Spawn Refactoring Agents

Launch **6 parallel Task agents** (or the number specified) using the Explore subagent type. Each agent evaluates a different dimension of the refactor:

**CRITICAL: Launch ALL agents in a SINGLE message with multiple Task tool calls for true parallelism.**

#### Agent Angles:

1. **Coupling Agent** - Map all dependencies of the target code. Find:
   - Every file that imports from the target
   - Every file the target imports from
   - Shared types, interfaces, and constants
   - Database models and queries involved
   - Count the total blast radius (number of files affected)

2. **Pattern Agent** - Analyze current patterns and the ideal target state. Find:
   - What pattern does the current code follow?
   - What pattern should it follow (based on codebase conventions)?
   - Specific examples of the target pattern already in the codebase
   - Gaps between current and target implementation

3. **Risk Agent** - Identify what could go wrong. Find:
   - Implicit contracts or assumptions in the current code
   - Edge cases handled by current implementation
   - External integrations that depend on current behavior (webhooks, Stripe, etc.)
   - Race conditions or timing dependencies
   - Areas with no test coverage (highest risk)

4. **Test Coverage Agent** - Assess test safety net. Find:
   - Existing tests for the target area (file paths, test count)
   - What behavior is tested vs untested
   - Tests that would break during refactor
   - Tests that need to be written BEFORE refactoring
   - Related test patterns to follow

5. **Migration Path Agent** - Design the incremental approach. Find:
   - Can this be done incrementally or is it all-or-nothing?
   - What's the smallest safe first step?
   - Can old and new code coexist during migration?
   - What shared interfaces allow parallel implementations?
   - Feature flags or gradual rollout opportunities

6. **Effort Agent** - Estimate the work involved. Find:
   - Number of files to create, modify, or delete
   - Number of functions/components to change
   - New abstractions or patterns to introduce
   - Required test changes or additions
   - Categorize: S (< 5 files), M (5-15 files), L (15+ files)

### Phase 3: Synthesize Feasibility Report

```markdown
## Refactoring Feasibility: [Area]

### Current State
[Brief description of what exists and why it needs refactoring]

### Target State
[Description of the desired end result, with pattern references from codebase]

### Blast Radius
- Files directly affected: X
- Files indirectly affected: X
- Test files affected: X
- Total: X files

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Break X | Medium | High | Write tests first |

### Test Safety Net
- Current coverage: [description]
- Tests needed before refactoring: [list]
- Tests that will break: [list]

### Migration Strategy
**Approach:** [Incremental / Big Bang]

Step 1: [Smallest safe change]
Step 2: [Next change]
...

### Effort Estimate
- Size: S / M / L
- Files to change: X
- New files: X
- Deleted files: X

### Recommendation
**[GO / CAUTION / STOP]** - [One sentence rationale]

### Prerequisites
- [ ] Write tests for [untested area]
- [ ] Extract [shared interface]
- [ ] ...
```

## Key Principles

- **Honest**: If the refactor is too risky or costly, say so
- **Incremental**: Always prefer small safe steps over big rewrites
- **Test-first**: Identify test gaps before recommending changes
- **Grounded**: Reference real files and patterns, not theoretical ideals
