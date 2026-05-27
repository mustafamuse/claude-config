---
name: gsuite-tools
description: Read, edit, comment on, and manage Google Docs, Sheets, Slides, Drive, Gmail, Calendar, and Tasks using the personal gsuite-tools stack installed on this Mac (rclone OAuth + gog CLI + gws + gdocs.py + gslides.py). Use when the user mentions Google Workspace work, names any of the tools (rclone gdrive, gog, gws, gdocs.py, gslides.py), or asks to read/edit/comment on Google documents, search Gmail, query Calendar, manage Drive files, or operate on personal-gsuite-cli GCP project.
---

# gsuite-tools — Personal Google Workspace stack

Single sign-on across Gmail, Calendar, Drive, Docs, Sheets, Slides, Tasks via a shared rclone-managed OAuth refresh token against `umpp101@gmail.com`. Installed 2026-05-26.

## Decision: which tool for which job

| Goal | Use | Why |
|---|---|---|
| Comments on a Doc/Sheet/Slide | `python3 $GDOCS_SCRIPT comments` | Drive comments API; works on any file type |
| Edit Doc content (text/tables/styling) | `python3 $GDOCS_SCRIPT` | 27 fine-grained subcommands |
| Edit Slides (shapes/text/tables/notes) | `python3 $GSLIDES_SCRIPT` | 46 subcommands; no equivalent in gog |
| Search/read Gmail | `gog gmail search` | Stable, fast, TSV/JSON output |
| Calendar events | `gog calendar events list` | Filter by `--time-min/--time-max` |
| Drive file search/metadata | `gog drive search` | Faster than gdocs.py for plain searches |
| Sheets read/write | `gog sheets` | Range-aware; supports values + formatting |
| Tasks | `gog tasks lists` / `gog tasks list <id>` | Resource-verb pattern |
| Forms / Chat / Meet / Apps Script / Analytics / Search Console / Ads / YouTube / Photos | `gws_run` shell function | Generic Discovery API bridge |

## Stack locations (canonical)

- `~/.config/rclone/rclone.conf` — `[gdrive]` section is the OAuth state of record (refresh token here). `[gphotos]` is a separate pre-existing remote — do not touch.
- `~/Library/Application Support/gogcli/credentials.json` + macOS Keychain entry `gogcli` — gog's parallel store.
- `~/.local/gsuite-tools/`
  - `gdocs/gdocs.py` — Docs/Drive Python CLI
  - `gslides/gslides.py` — Slides Python CLI
  - `shared/rclone_auth.py` — library; reads rclone.conf, refreshes tokens, writes back
  - `shared/gws_auth.py` — CLI wrapper that prints a fresh access token

Env vars loaded from `~/.zshrc` (block between `# --- gsuite-tools ---` markers):
- `$GSUITE_TOOLS` = `~/.local/gsuite-tools`
- `$GDOCS_SCRIPT`, `$GSLIDES_SCRIPT`, `$GWS_AUTH` — absolute script paths
- `$GOG_ACCOUNT` = `umpp101@gmail.com`
- `gws_run()` function — minted-token wrapper around `gws`

## gog v0.19.0 syntax (resource-verb pattern)

**Pattern:** `gog <service> <resource> <verb>`

Common commands that work:

```bash
# Calendar
gog calendar calendars                            # list calendars
gog calendar events list [calendarId]             # events (default = primary)
gog calendar events list --time-min "$(date -u +%Y-%m-%dT00:00:00Z)" \
                        --time-max "$(date -u +%Y-%m-%dT23:59:59Z)"

# Gmail
gog gmail search "in:inbox is:unread" --max 5
gog gmail messages <id>
gog gmail thread <id>

# Drive
gog drive search "query" [--json]
gog drive files list / get <id>

# Sheets
gog sheets get <sheet_id>
gog sheets range <id> "Sheet1!A1:C10"

# Tasks
gog tasks lists
gog tasks list <listId>
```

**Stale spec patterns that DON'T work** (older docs / older gog versions had these):

| Stale | Use instead |
|---|---|
| `gog calendar today` | `gog calendar events list --time-min ... --time-max ...` |
| `gog gmail profile` | no bare profile; use `gog gmail search` for inbox sampling |
| `gog tasks` bare | `gog tasks lists` |
| `gog auth credentials -` | `gog auth credentials set -` |
| `brew install steipete/tap/gogcli` | `brew install gogcli` (Homebrew core) |

## Common patterns

**ID extraction from URLs** — Both Python scripts auto-extract Doc/Sheet/Slide IDs from full URLs. Paste the URL directly:

```bash
python3 $GDOCS_SCRIPT comments "https://docs.google.com/document/d/1ABC.../edit"
```

**Multi-tab Google Docs (2024+ feature)** — Docs can contain a tree of tabs (e.g., `2026 → May 25 → Retro H1`). `gdocs.py doc-get` on this install has been patched to support tabs: pass `--tab <tabId>` explicitly, OR paste a URL with `?tab=t.xxx` and it auto-detects. Available behaviors:

```bash
# Auto-detect tab from URL
python3 $GDOCS_SCRIPT doc-get --text \
  "https://docs.google.com/document/d/<docId>/edit?tab=t.2a0kcvw3gde"

# Explicit tab flag
python3 $GDOCS_SCRIPT doc-get --tab t.2a0kcvw3gde <docId>

# Invalid tab → error lists ALL tabs with IDs+titles (good for discovery)
python3 $GDOCS_SCRIPT doc-get --tab t.bogus <docId>
```

The patch adds `--tab`, `extract_tab_id`, `find_tab`, and threads `includeTabsContent=true` into the API call. Original (unpatched) behavior: returns only the root tab's content, silently ignoring any `?tab=...` URL param.

**Portable patch location:** `~/dev/claude-config/patches/gdocs-multi-tab-support.patch` (131 lines, tracked in the claude-config repo).

**Apply on a fresh install:**

```bash
cd ~/.local/gsuite-tools/gdocs
patch -p1 < ~/dev/claude-config/patches/gdocs-multi-tab-support.patch
# Verify:
python3 $GDOCS_SCRIPT doc-get --help | grep -- --tab    # should show the flag
```

**Verifying the patch is applied** on any machine:

```bash
grep -q "extract_tab_id" $GDOCS_SCRIPT && echo "patched" || echo "vanilla"
```

**Get a fresh access token for ad-hoc API calls:**

```bash
TOKEN=$(python3 $GWS_AUTH)
curl -sH "Authorization: Bearer $TOKEN" \
  "https://www.googleapis.com/drive/v3/about?fields=user"
```

**Quiet JSON pipeline:**

```bash
gog drive search "Q1" --json --results-only | jq '.[] | {name, id}'
```

**Calendar events for today (one-liner):**

```bash
gog calendar events list \
  --time-min "$(date -u +%Y-%m-%dT00:00:00Z)" \
  --time-max "$(date -u +%Y-%m-%dT23:59:59Z)"
```

## GCP project context

- **Project ID:** `personal-gsuite-cli` (project number 642973565245)
- **Owner / sole test user:** `umpp101@gmail.com`
- **Publishing status:** Testing (External user type, 100 user cap)
- **9 OAuth scopes registered:** `drive`, `documents`, `presentations`, `spreadsheets`, `gmail.modify`, `gmail.settings.basic`, `gmail.settings.sharing`, `calendar`, `tasks`. All except `drive` are Sensitive/Restricted.
- **8 APIs enabled:** Drive, Docs, Slides, Sheets, Gmail, Calendar, People, Tasks

## OAuth gotchas

**Refresh tokens for unverified Testing apps can expire after 7 days idle.** If anything errors with `invalid_grant`:

```bash
# Option 1 — refresh rclone (drive scope only)
rclone authorize drive <client_id> <client_secret>
# then update [gdrive].token in ~/.config/rclone/rclone.conf

# Option 2 — refresh gog (all 7 services in one flow)
gog auth add umpp101@gmail.com \
  --services drive,docs,slides,sheets,gmail,calendar,tasks
```

The client_id and client_secret are stored in `~/.config/rclone/rclone.conf` under `[gdrive]` — extract with:

```bash
python3 -c "import configparser, pathlib; c=configparser.ConfigParser(); c.read(pathlib.Path.home()/'.config/rclone/rclone.conf'); print(c.get('gdrive','client_id')); print(c.get('gdrive','client_secret'))"
```

**Adding a new Google API** (e.g., Maps, Translate):
1. Enable the API at `https://console.cloud.google.com/apis/library?project=personal-gsuite-cli`
2. Add the scope(s) at `https://console.cloud.google.com/auth/scopes?project=personal-gsuite-cli` — use the "Manually add scopes" textarea for bulk paste
3. Re-run `gog auth add umpp101@gmail.com --services drive,docs,slides,sheets,gmail,calendar,tasks,<new_service>`

## Safety conventions

- **`gog --gmail-no-send`** blocks Gmail send operations. Use for scripting/agent contexts where an accidental send would be harmful. Set as default with `alias gog='gog --gmail-no-send'` if needed.
- **Never auto-send/auto-create/auto-share without explicit user confirmation.** Drive scope grants delete authority on every file in the user's Drive. Treat all write operations as confirmation-required unless the user has authorized the specific scope in this turn.
- **`--dry-run` / `-n`** flag is supported on most gog commands — use it to preview destructive operations.

## Quick reference: daily-use one-liners

```bash
# What's unread in my inbox?
gog gmail search "in:inbox is:unread" --max 10

# What's on my calendar today?
gog calendar events list \
  --time-min "$(date -u +%Y-%m-%dT00:00:00Z)" \
  --time-max "$(date -u +%Y-%m-%dT23:59:59Z)"

# All my calendars
gog calendar calendars

# Find a Drive file
gog drive search "report" --json

# Read comments on a Doc
python3 $GDOCS_SCRIPT comments <doc_url_or_id>

# Read a Doc (root tab) as plain text
python3 $GDOCS_SCRIPT doc-get --text <doc_url_or_id>

# Read a specific tab in a multi-tab Doc (auto-detects from ?tab=... in URL)
python3 $GDOCS_SCRIPT doc-get --text "https://docs.google.com/document/d/<id>/edit?tab=t.xxx"
python3 $GDOCS_SCRIPT doc-get --text --tab t.xxx <doc_id>

# Add a comment to a Doc
python3 $GDOCS_SCRIPT comment-add <doc_url_or_id> "Looks good — minor nit on para 3"

# Replace text in a Doc (case-sensitive global)
python3 $GDOCS_SCRIPT doc-replace <doc_url_or_id> "draft" "final"

# List all slides in a presentation
python3 $GSLIDES_SCRIPT pres-slides <pres_url_or_id>

# Insert text on a specific slide
python3 $GSLIDES_SCRIPT text-insert <pres_id> <slide_id> "New text"

# Call any other Google API via gws
gws_run forms forms get --params '{"formId":"<id>"}'
gws_run chat spaces list

# Browse all subcommands
python3 $GDOCS_SCRIPT --help
python3 $GSLIDES_SCRIPT --help
gog --help
gws --help
```

## When NOT to use this stack

- **Workspace admin operations** (groups, directory, audit logs) — these need a service account with domain-wide delegation against a Workspace tenant, not personal OAuth
- **Programmatic mass operations** crossing other users' data — personal OAuth only sees this user's stuff
- **Public-facing apps** — Testing mode caps lifetime users at 100; not a distribution path
