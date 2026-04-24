# /task — Task Analysis Check-in

Connect to Linear and analyze today's task status. Report as an AI manager.

---

## API Access

Use the Linear GraphQL API directly via `$LINEAR_API_KEY` (NOT MCP tools).

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_KEY" \
  -d '{"query": "<GRAPHQL_QUERY>"}'
```

Teams: RES (`02ad8dd4-39eb-4aaa-a905-2801f71763e8`), LIF (`d86a0a03-bd2d-4012-9960-e48f1bbde783`)

## Execution Steps

### Step 1: Fetch Data

Run these queries in parallel:

**Query 1 — Active cycles (both teams):**
```graphql
{ teams { nodes { key id cycles(filter: { isActive: { eq: true } }) { nodes { id name number startsAt endsAt progress } } } } }
```

**Query 2 — Issues per cycle** (one query per cycle ID from Query 1):
```graphql
{ cycle(id: "<CYCLE_ID>") { issues { nodes { id identifier title priority state { name type } dueDate updatedAt } } } }
```

**Query 3 — All issues with due dates in the next 30 days:**
```graphql
{ issues(filter: { dueDate: { gte: "<TODAY>" lte: "<TODAY+30>" } state: { type: { nin: ["completed" "canceled"] } } } first: 50) { nodes { id identifier title priority dueDate state { name type } team { key } updatedAt } } }
```

Note: Keep queries simple to avoid Linear's complexity limit (max 10,000). Never nest issues inside teams inside cycles — fetch cycles first, then issues per cycle separately.

### Step 2: Analyze

Analyze the fetched data across these dimensions:

**Cycle Analysis**
- Days remaining and completion rate (progress field, 0.0–1.0)
- Whether remaining issues can realistically be completed this week
- Issues with empty descriptions (undefined scope)

**Deadline Check (across all issues)**
- Due within 7 days → 🔴 Immediate action required
- Due in 8–14 days → 🟡 Decide on start this week
- Due in 15–30 days → 📥 Consider adding to next cycle

**Stagnation Detection**
- In Progress with no update for 3+ days → likely blocked
- Todo untouched for 1+ week → decide: start or move back to Backlog

### Step 3: Report

Output in the following format:

```
## 🤖 Check-in — {date}

### 🔴 Cycle: Incomplete (N days remaining)
| Issue | Priority | Status |
|---|---|---|

### 🟡 Upcoming Deadlines
| Issue | Due | Remaining | Status |
|---|---|---|---|

### ⚠️ Stagnating
[In Progress issues with no update for 3+ days]

### 📋 Suggested Actions for Today (max 3)
1. ...
2. ...
3. ...
```

### Step 4: Dialogue Mode

After reporting, enter dialogue mode. Update Linear immediately based on user instructions:

| User says | Action |
|---|---|
| "start" / "do it" | Move issue to In Progress via `mutation { issueUpdate(id: "...", input: { stateId: "..." }) { issue { id } } }` |
| "skip" / "delete" | Propose moving back to Backlog or deleting |
| "next cycle" | Move issue to next cycle via `mutation { issueUpdate(id: "...", input: { cycleId: "..." }) { issue { id } } }` |
| "details" | Fetch and display full issue details |
| "add" + content | Create a new issue via `mutation { issueCreate(...) { issue { id identifier } } }` |
| "done" | Verify Done criteria, then mark complete |

---

## Done Criteria Rule

Before marking any issue Done, always verify:
- experiment_run.md link is posted in comments (for experiment issues)
- Observations (divergence from predictions) are filled in

If not satisfied, warn the user before proceeding.

---

## Cycle Planning Mode

When the user says "plan next cycle":

1. Check the next cycle's date range
2. Propose high-priority / deadline-driven candidates from Backlog
3. Get user confirmation before assigning to the cycle
4. Check total scope to avoid overloading the cycle
