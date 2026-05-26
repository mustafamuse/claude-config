---
description: Decompose a task into atomic, implementable work units using parallel agents
argument-hint: <task description> [n=number of agents, default 6]
---

# Council: Task Decomposition

Decompose a task into atomic, implementation-ready work units using parallel specialist agents.

## Input

Task to decompose: $ARGUMENTS

## Instructions

### Phase 1: Understand the Task

Quickly scan the codebase to understand:
- Current state of related code (what exists, what's stubbed, what's missing)
- Existing patterns and conventions that must be followed
- Dependencies and integration points

Use Glob and Grep to identify relevant files and patterns.

### Phase 2: Spawn Decomposition Agents

Launch **6 parallel Task agents** (or the number specified) using the Explore subagent type. Each agent decomposes the task from a different layer:

**CRITICAL: Launch ALL agents in a SINGLE message with multiple Task tool calls for true parallelism.**

#### Agent Angles:

1. **Schema/DB Agent** - What database changes are needed? New models, migrations, indexes, relations. List exact fields and constraints.
2. **Query Layer Agent** - What query functions are needed? List each function signature, parameters, includes, and which file it belongs in. Follow the DatabaseClient parameter pattern.
3. **Service Layer Agent** - What business logic is needed? List each service function, its validation rules, error cases, and transaction boundaries.
4. **Action Layer Agent** - What server actions are needed? List each action with its Zod schema, ActionResult return type, revalidation paths, and error handling.
5. **UI Component Agent** - What components are needed? List each component (server vs client), its props, state management, and which actions it calls.
6. **Test Agent** - What tests are needed? List test files, test cases per file, mocking strategy, and edge cases to cover.

Each agent should produce a **numbered checklist** of atomic work items with:
- Exact file path (new or existing)
- Function/component name
- Dependencies (what must exist first)
- Estimated complexity (S/M/L)

### Phase 3: Synthesize into Build Order

Combine all agent outputs into a single ordered build plan:

```markdown
## Task Decomposition: [Task Description]

### Layer 1: Schema & Database
- [ ] Item 1 (file, description, dependencies: none)
- [ ] Item 2 (file, description, dependencies: Item 1)

### Layer 2: Query Functions
- [ ] Item 3 (file, description, dependencies: Layer 1)

### Layer 3: Service Logic
- [ ] Item 4 (file, description, dependencies: Layer 2)

### Layer 4: Server Actions
- [ ] Item 5 (file, description, dependencies: Layer 3)

### Layer 5: UI Components
- [ ] Item 6 (file, description, dependencies: Layer 4)

### Layer 6: Tests
- [ ] Item 7 (file, description, dependencies: all layers)

### Dependency Graph
[Text-based DAG showing which items block others]

### Risk Areas
- Items with highest complexity or most dependencies
- Items requiring changes to shared code
```

### Phase 4: Deliver

Present the decomposition as a ready-to-execute checklist. Each item should be small enough to implement in a single focused session.

## Key Principles

- **Atomic**: Each item is independently implementable and testable
- **Ordered**: Build order respects dependencies (schema first, tests last)
- **Complete**: Nothing is missing - the checklist IS the implementation plan
- **Grounded**: Every item references real files and follows existing patterns
