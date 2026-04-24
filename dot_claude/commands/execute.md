# Execute GitHub Issue

Execute the GitHub Issue specified by `$ARGUMENTS` autonomously.

## Workflow

### 1. Load Issue
```
gh issue view $ARGUMENTS
```
Read the issue body carefully. It contains:
- Task description
- Implementation direction
- Acceptance criteria
- Dependencies (other issue numbers)

### 2. Check Dependencies
If the issue references dependency issues, verify they are all closed:
```
gh issue view <dep_number> --json state
```
If any dependency is open, **stop immediately** and notify via Discord:
```
curl -X POST "$DISCORD_WEBHOOK_URL" -H "Content-Type: application/json" \
  -d '{"content": "🛑 Task #$ARGUMENTS blocked: dependency #<dep> is still open."}'
```

### 3. Create or Resume Working Branch
Check if a branch already exists (may be resuming after max-turns):
```
git branch --list "task/$ARGUMENTS"
```
- If the branch exists: `git checkout task/$ARGUMENTS` (resume from where it left off)
- If not: `git checkout -b task/$ARGUMENTS` (start fresh)

Also check if a PR already exists:
```
gh pr list --head "task/$ARGUMENTS" --json number,url
```
If a PR exists, you are resuming — continue working and push to the same branch.

### 4. Implement
- Follow the implementation direction described in the issue
- Read existing code before modifying
- Make commits at logical checkpoints with clear messages
- Each commit message should explain **why**, not just what
- Keep commits appropriately sized — one logical change per commit
- **Push after every commit** to make progress visible:
  ```
  git push -u origin task/$ARGUMENTS
  ```

### 5. Self-Verify
Before finishing, verify your work:
- Re-read the acceptance criteria from the issue
- Run any relevant tests or build commands
- Check that no unintended files were modified (`git diff --stat`)

### 6. Create Pull Request
```
gh pr create --title "<concise title>" --body "Closes #$ARGUMENTS\n\n## Changes\n<summary>"
```

### 7. Notify Completion
```
curl -X POST "$DISCORD_WEBHOOK_URL" -H "Content-Type: application/json" \
  -d '{"content": "✅ Issue #$ARGUMENTS completed.\nPR: <pr_url>"}'
```

## Safety Rules

- **NEVER** run destructive commands (rm -rf, git push --force, etc.)
- **NEVER** modify files outside the project directory
- **NEVER** commit secrets, API keys, or credentials
- If build/test commands are needed, use `docker exec` when a container is available

## When You Are Stuck

If you encounter a situation where you cannot proceed:
- Same error 3 times in a row → stop and notify
- Ambiguous requirement → stop and notify
- Need user decision → stop and notify

Notification format:
```
curl -X POST "$DISCORD_WEBHOOK_URL" -H "Content-Type: application/json" \
  -d '{"content": "⚠️ Issue #$ARGUMENTS needs your input.\nQuestion: <specific question>\nContext: <what you tried>"}'
```
After sending the notification, **stop all work**. Do not continue or guess.

## Commit Guidelines

- Commit at each logical checkpoint, not just at the end
- Message format: `<type>: <description>` (e.g., `feat: add README with setup instructions`)
- Types: feat, fix, refactor, docs, test, chore
- Keep each commit focused on one logical change
