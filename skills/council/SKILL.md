---
description: Spawn a council of parallel agents to deeply explore a codebase area of interest
argument-hint: <area of interest> [n=number of agents, default 10]
---

# Council Mode - Parallel Deep Exploration

You are activating Council Mode to deeply explore a codebase around a specific area of interest using parallel agents.

## Input

Area of interest: $ARGUMENTS

## Instructions

### Phase 1: Initial Reconnaissance

First, perform a quick exploration of the codebase to understand:
- Project structure and architecture
- Key directories and file patterns related to the area of interest
- Important keywords, types, and patterns
- Entry points and core abstractions

Use Glob and Grep to quickly identify:
```
- Related file patterns (e.g., **/*service*.ts, **/*controller*.ts)
- Key imports and exports
- Type definitions and interfaces
- Configuration files
```

### Phase 2: Spawn the Council

Launch **10 parallel Task agents** (or the number specified) using the Explore subagent type. Each agent should investigate a different angle:

**CRITICAL: Launch ALL agents in a SINGLE message with multiple Task tool calls for true parallelism.**

#### Required Agent Angles (adjust based on area of interest):

1. **Architecture Agent** - Map the high-level architecture, dependencies, and data flow
2. **Entry Points Agent** - Find all entry points (APIs, exports, CLI commands, event handlers)
3. **Data Models Agent** - Explore database schemas, types, interfaces, and data structures
4. **Business Logic Agent** - Understand core business rules and domain logic
5. **Integration Agent** - Map external service integrations (APIs, databases, queues)
6. **Error Handling Agent** - Analyze error patterns, logging, and failure modes
7. **Testing Agent** - Review test coverage, test patterns, and test utilities
8. **Configuration Agent** - Find environment variables, feature flags, and config patterns

#### Variance Agents (for out-of-box insights):

9. **Security Agent** - Look for auth patterns, validation, sanitization, secrets handling
10. **Performance Agent** - Identify potential bottlenecks, caching, optimization opportunities

### Phase 3: Synthesize Findings

Once all agents complete, synthesize their findings into:

```markdown
## Council Report: [Area of Interest]

### Architecture Overview
- High-level structure
- Key components and their relationships
- Data flow diagram (text-based)

### Key Files
| File | Purpose | Importance |
|------|---------|------------|
| path/to/file | Description | High/Medium/Low |

### Patterns Discovered
- Design patterns in use
- Naming conventions
- Code organization patterns

### Integration Points
- External services
- Database interactions
- Event systems

### Potential Issues
- Technical debt
- Security considerations
- Performance concerns

### Recommendations
- Based on the area of interest, what should be done
- Priority order
- Dependencies between tasks
```

### Phase 4: Execute User Intent

Based on the synthesized information:
- If the user is in **plan mode**: Create a detailed implementation plan
- If the user wants **changes**: Proceed with implementation using the gathered context
- If the user wants **analysis**: Provide the comprehensive report

## Agent Prompt Template

When spawning agents, use this pattern:

```
Explore the codebase focusing on [SPECIFIC ANGLE] related to [AREA OF INTEREST].

Look for:
- [Specific patterns to find]
- [Key files or directories]
- [Important abstractions]

Report:
- File paths with line numbers for key findings
- Code patterns and conventions observed
- Relationships and dependencies
- Any concerns or opportunities

Be thorough but concise. Focus on actionable insights.
```

## Example Usage

```bash
# Explore payment processing
/council payment processing

# Deep dive into authentication with 15 agents
/council authentication n=15

# Understand the notification system
/council notifications and messaging

# Analyze API design
/council REST API endpoints and routing
```

## Key Principles

- **Parallelism**: Always launch agents in parallel for speed
- **Variance**: Include unconventional angles for unexpected insights
- **Depth**: Each agent should go deep, not surface-level
- **Synthesis**: The value is in combining diverse perspectives
- **Action**: Always conclude with actionable next steps
