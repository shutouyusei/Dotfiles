# Setup Project for Autonomous Task Execution

Initialize the current project for the Claude Code autonomous task workflow.

## Procedure

### 1. Verify Prerequisites
Check that the shared infrastructure exists:
```
test -f ~/.claude/commands/execute.md && echo "OK: execute.md" || echo "MISSING: execute.md"
test -f ~/.claude/commands/create-task.md && echo "OK: create-task.md" || echo "MISSING: create-task.md"
test -f ~/.claude/hooks/safety-check.sh && echo "OK: safety-check.sh" || echo "MISSING: safety-check.sh"
test -f ~/.claude/scripts/run-task.sh && echo "OK: run-task.sh" || echo "MISSING: run-task.sh"
```
If any are missing, inform the user and stop. These must be set up first.

### 2. Verify Git Repository
```
git remote get-url origin
```
If not a git repo or no remote, inform the user and stop.

### 3. Analyze Project
Read the project structure and key files to understand:
- Programming languages used
- Frameworks and tools
- Build system
- Directory structure
- Any existing CLAUDE.md or README

### 4. Generate CLAUDE.md
Create `CLAUDE.md` at the project root with:

```markdown
# <Project Name> — <One-line description>

## Project Overview
<2-3 sentences based on analysis>

## Tech Stack
<List of languages, frameworks, tools found>

## Repository Structure
<Key directories and their purposes>

## GitHub
- Repository: <owner/repo>

## Rules for Claude
- All commit messages in English, format: `<type>: <description>`
- Types: feat, fix, refactor, docs, test, chore
- One logical change per commit
- <Project-specific rules — ASK the user what rules to add>
```

**ASK the user** to review and confirm before writing.

### 5. Add GitHub Actions Workflows
Create three workflow files in `.github/workflows/`:

#### 5a. `.github/workflows/resume-task.yml` — Resume on Issue comment
```yaml
name: Resume Task on Issue Comment

on:
  issue_comment:
    types: [created]

jobs:
  resume:
    if: |
      !github.event.issue.pull_request &&
      contains(github.event.issue.labels.*.name, 'auto-task') &&
      github.event.comment.user.login == github.repository_owner
    runs-on: [self-hosted, claude]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Execute task
        env:
          DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
        run: |
          echo "Resuming task #$ISSUE_NUMBER"
          ~/.claude/scripts/run-task.sh "$ISSUE_NUMBER"
```

#### 5b. `.github/workflows/notify-progress.yml` — Discord notification on push
```yaml
name: Notify Task Progress

on:
  push:
    branches:
      - 'task/**'

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Send Discord notification
        env:
          DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
        run: |
          BRANCH="${GITHUB_REF#refs/heads/}"
          ISSUE_NUMBER="${BRANCH#task/}"
          COMMIT_MSG=$(echo '${{ github.event.head_commit.message }}' | head -1)
          COMMIT_URL="${{ github.event.head_commit.url }}"

          curl -s -X POST "$DISCORD_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"📝 Task #${ISSUE_NUMBER} progress\\nCommit: ${COMMIT_MSG}\\n${COMMIT_URL}\"}"
```

#### 5c. `.github/workflows/run-next-task.yml` — Auto-run dependent tasks on PR merge
```yaml
name: Run Next Task on PR Merge

on:
  pull_request:
    types: [closed]

jobs:
  run-next:
    if: github.event.pull_request.merged == true
    runs-on: [self-hosted, claude]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Find and run next task
        env:
          DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
          GH_TOKEN: ${{ github.token }}
        run: |
          PR_BODY="${{ github.event.pull_request.body }}"
          CLOSED_ISSUE=$(echo "$PR_BODY" | grep -oP 'Closes #\K[0-9]+' | head -1)

          if [ -z "$CLOSED_ISSUE" ]; then
            echo "No linked issue found in PR body. Skipping."
            exit 0
          fi

          echo "PR merged for Issue #$CLOSED_ISSUE"

          NEXT_ISSUES=$(gh issue list --label "auto-task" --state open --json number,body -q \
            ".[] | select(.body | test(\"#$CLOSED_ISSUE must be completed\")) | .number")

          if [ -z "$NEXT_ISSUES" ]; then
            echo "No dependent tasks found."
            exit 0
          fi

          for NEXT in $NEXT_ISSUES; do
            DEPS=$(gh issue view "$NEXT" --json body -q '.body' | grep -oP '#\K[0-9]+(?= must be completed)' || true)
            ALL_RESOLVED=true

            for DEP in $DEPS; do
              STATE=$(gh issue view "$DEP" --json state -q '.state')
              if [ "$STATE" != "CLOSED" ]; then
                echo "Issue #$NEXT still blocked by #$DEP ($STATE)"
                ALL_RESOLVED=false
                break
              fi
            done

            if [ "$ALL_RESOLVED" = true ]; then
              echo "All dependencies resolved for #$NEXT. Starting execution."
              ~/.claude/scripts/run-task.sh "$NEXT"
            fi
          done
```

### 6. Create Label
```
gh label create "auto-task" --description "Auto-generated task for Claude Code" --color "0E8A16"
```
If it already exists, skip.

### 7. Set GitHub Secret
Check if DISCORD_WEBHOOK_URL secret already exists:
```
gh secret list | grep DISCORD_WEBHOOK_URL
```
If not set:
```
gh secret set DISCORD_WEBHOOK_URL --body "$DISCORD_WEBHOOK_URL"
```
If the environment variable is not available, ask the user for the URL.

### 8. Check Runner
```
gh api repos/<owner>/<repo>/actions/runners --jq '.total_count'
```
If 0 runners, display setup instructions:
```
The self-hosted runner "local-worker" is not registered for this repository.

If you already have a runner on another repo, you can add this repo by
re-registering or using an Organization runner.

To register for this repo:
  cd ~/actions-runner
  TOKEN=$(gh api -X POST repos/<owner>/<repo>/actions/runners/registration-token --jq '.token')
  ./config.sh --url https://github.com/<owner>/<repo> --token $TOKEN --name "local-worker" --labels "self-hosted,claude" --unattended
  sudo ./svc.sh install
  sudo ./svc.sh start
```

### 9. Update .gitignore
Append common patterns if not already present:
- `__pycache__/`, `*.pyc`, `*.pyo` (Python)
- `.vscode/`, `.idea/` (IDE)
- `.DS_Store`, `Thumbs.db` (OS)

Only add patterns relevant to the detected tech stack. Do not remove existing entries.

### 10. Commit and Push
```
git add CLAUDE.md .github/workflows/ .gitignore
git commit -m "chore: setup autonomous task execution workflow"
git push
```

### 11. Summary
Display the result:
```
Setup complete for <owner>/<repo>

  ✓ CLAUDE.md created
  ✓ .github/workflows/resume-task.yml created (resume on Issue comment)
  ✓ .github/workflows/notify-progress.yml created (Discord progress notifications)
  ✓ .github/workflows/run-next-task.yml created (auto-run dependent tasks on PR merge)
  ✓ DISCORD_WEBHOOK_URL secret set
  ✓ auto-task label created
  ✓ Runner: <status>
  ✓ .gitignore updated

Available commands:
  /create-task <description>  — Create a GitHub Issue from conversation
  /execute <issue_number>     — Execute a task interactively
  run-task.sh <issue_number>  — Execute a task in background (unattended)
```
