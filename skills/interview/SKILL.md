---
allowed-tools: Read, Edit, Write, AskUserQuestion
argument-hint: [plan-file-path]
description: Interview user to flesh out a plan with detailed requirements
model: opus
---

# Plan Interview

Flesh out plan: $ARGUMENTS

## Instructions

1. **Read the Plan**
   - Read the plan file specified in arguments
   - Identify all items that need clarification
   - Note any "TBD" or "Open Questions" sections

2. **Conduct Structured Interview**
   Use AskUserQuestion tool to gather information about:

   ### Priority & Scope
   - Which items are blockers vs nice-to-have?
   - What is the time constraint (if any)?
   - Are there items that can be deferred?

   ### Technical Decisions
   - For each ambiguous implementation choice, ask for preference
   - Clarify testing requirements
   - Ask about backwards compatibility concerns

   ### Risk Assessment
   - What could go wrong with each change?
   - Are there production concerns?
   - What needs manual testing?

3. **Update the Plan**
   After gathering responses:
   - Fill in "TBD" sections with user answers
   - Add implementation order based on priorities
   - Document any decisions made
   - Add testing requirements

## Interview Strategy

Ask questions in batches of 2-4 related questions using multi-select where appropriate.

### Question Templates

**Priority Question:**
```
Which fixes are absolute blockers for merging?
Options: [list items from plan]
multiSelect: true
```

**Implementation Question:**
```
For [specific item], which approach do you prefer?
Options: [concrete implementation choices]
```

**Scope Question:**
```
Should we handle [edge case] now or defer it?
Options: Fix now / Defer to follow-up PR / Skip entirely
```

## Output

Update the plan file with:
1. Prioritized implementation order
2. Specific implementation decisions
3. Testing requirements
4. Items explicitly deferred
