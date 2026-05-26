---
allowed-tools: Bash
argument-hint:
description: Delete all bot and automated comments on the current branch's PR
model: haiku
---

# Clean PR Comments

Delete all bot and automated comments on the PR associated with the current branch, making it look like a fresh PR.

## Target accounts to delete

Delete comments from ANY of these accounts:
- `claude[bot]`
- `vercel[bot]`
- `codex[bot]`
- `github-actions[bot]`
- `sentry-io[bot]`
- `chatgpt-codex-connector[bot]`

Also delete comments from the authenticated user (`gh api user --jq '.login'`).

## Steps

1. **Get current branch and PR number**
   ```bash
   gh pr view --json number,url --jq '.number'
   ```
   If no PR is found, stop and tell the user.

2. **Get repo owner/name**
   ```bash
   gh repo view --json nameWithOwner --jq '.nameWithOwner'
   ```

3. **Delete issue comments from target accounts**
   List all issue comments, filter to target logins, then delete each:
   ```bash
   gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate --jq '[.[] | select(.user.login == "claude[bot]" or .user.login == "vercel[bot]" or .user.login == "codex[bot]" or .user.login == "github-actions[bot]" or .user.login == "sentry-io[bot]" or .user.login == "YOUR_USERNAME") | .id] | .[]'
   ```
   For each comment ID:
   ```bash
   gh api repos/{owner}/{repo}/issues/comments/{comment_id} -X DELETE
   ```

4. **Delete review comments from target accounts**
   List all review comments, filter to target logins, then delete each:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate --jq '[.[] | select(.user.login == "claude[bot]" or .user.login == "vercel[bot]" or .user.login == "codex[bot]" or .user.login == "github-actions[bot]" or .user.login == "sentry-io[bot]" or .user.login == "YOUR_USERNAME") | .id] | .[]'
   ```
   For each comment ID:
   ```bash
   gh api repos/{owner}/{repo}/pulls/comments/{comment_id} -X DELETE
   ```

5. **Report results**
   Print how many comments were deleted, broken down by account.
   If zero comments found, say "PR is already clean."
