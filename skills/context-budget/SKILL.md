---
description: Show token cost per loaded skill, MCP server, rule, and plugin. Wraps /usage with a "what's heavy and what could be trimmed" summary. Use when sessions feel slow or you're hitting context limits.
allowed-tools: Bash, Read
---

# /context-budget

Inventory what's loaded in this session and what it costs in tokens. Useful for trimming bloat.

## Process

1. Run `/usage` (built-in v2.1.149+) to get per-category breakdown
2. List currently enabled plugins from `~/.claude/settings.json` `enabledPlugins`
3. For each enabled plugin, count the skills it contributes (already-visible in the skills list)
4. List active MCP servers and their tool counts (`/mcp` or session-start MCP block)
5. Read `~/.claude/CLAUDE.md` and project `CLAUDE.md`, count tokens (1 token ≈ 4 chars)
6. Read `.claude/rules/*.md` files attached to current `git diff` paths, count tokens

## Output format

```
## Context Budget — <date>

**Total context used**: <X> / <Y> tokens (<pct>%)

### Heaviest contributors
1. <plugin/source> — ~<N> tokens (<reason>)
2. <plugin/source> — ~<N> tokens (<reason>)
3. <plugin/source> — ~<N> tokens (<reason>)

### Always-on (loaded every session)
- ~/.claude/CLAUDE.md — ~XXX tokens
- project CLAUDE.md — ~XXX tokens
- Skill list (visible names + descriptions): ~XXX tokens
- MCP tool definitions: ~XXX tokens (deferred via ToolSearch by default — see ENABLE_TOOL_SEARCH)

### Trim candidates
- Plugins not used this session: <list>
- Skills never invoked: <list>
- Rules that don't match any file in current diff: <list>

### Recommendation
<one-sentence: keep as-is / trim X / disable Y>
```

## Gotchas

- `/usage` shows what's been consumed; it doesn't predict future cost
- MCP tool definitions are normally deferred (only names load) via `ENABLE_TOOL_SEARCH=true` — full schemas hit context only when ToolSearch fetches them. Don't suggest disabling plugins just because they have many tools unless `alwaysLoad: true` is set
- Skill descriptions DO count against context every session, even unused — they're in the always-loaded skill list
- CLAUDE.md edits don't take effect mid-session (cache stays) — change requires `/clear` or new session to apply
- Disabling a plugin via `/plugin disable` reduces tokens **next session**, not this one

## When to act

| Symptom | Probable cause | Action |
|---------|----------------|--------|
| Slow first response | Heavy CLAUDE.md or many always-on skills | Trim CLAUDE.md, disable unused plugins |
| Bloated tool-search results | Too many MCP servers | Disable unused ones |
| Compaction triggering early | `CLAUDE_CODE_AUTO_COMPACT_WINDOW` too low or session genuinely long | Raise the env var or `/clear` |
| Skill list overwhelmingly long | 20+ plugins all enabled | Audit enabledPlugins; disable per-project ones at user level |

## Reference

- Anthropic /costs doc: https://code.claude.com/docs/en/costs
- Context engineering post: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
