# Create Task

Create a GitHub Issue from the task agreed upon in conversation.

`$ARGUMENTS` contains the task summary in natural language (Japanese or English).

## Procedure

### 1. Extract Task Details from Conversation
Review the current conversation and identify:
- What was agreed upon
- Implementation direction discussed
- Any constraints or decisions made

### 2. Determine Repository
Use the current working directory's git remote:
```
git remote get-url origin
```
Extract owner/repo from the URL.

### 3. Check for Duplicate Issues
```
gh issue list --label "auto-task" --state open
```
If a similar issue already exists, ask the user before creating a duplicate.

### 4. Create Issue in English
Use the following format strictly:

```
gh issue create \
  --title "<type>: <concise description>" \
  --label "auto-task" \
  --body "$(cat <<'EOF'
## Objective
<What this task achieves — 1-2 sentences>

## Background
<Why this task is needed — context from conversation>

## Implementation Direction
<Agreed approach — specific files, patterns, or strategies>

## Acceptance Criteria
- [ ] <Criterion 1>
- [ ] <Criterion 2>
- [ ] <Criterion 3>

## Dependencies
- None | #<issue_number> must be completed first

## Scope
- **In scope**: <what to do>
- **Out of scope**: <what NOT to do>

## Estimated Size
S / M / L
EOF
)"
```

### Title Types
- `feat`: New feature or functionality
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code restructuring without behavior change
- `test`: Adding or updating tests
- `chore`: Maintenance, config, tooling

### 5. Confirm to User
After creation, display:
- Issue number and URL
- Title
- Brief summary of what was registered

## Rules
- All issue content MUST be in English
- Title under 70 characters
- Each acceptance criterion must be independently verifiable
- Implementation direction must be specific enough for autonomous execution
- If the conversation lacks enough detail for any section, ASK the user before creating
- Do not invent requirements that were not discussed
