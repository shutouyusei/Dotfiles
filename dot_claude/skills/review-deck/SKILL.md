---
name: review-deck
description: Run a parallel multi-agent review of a Marp slide deck — visual, factual + argument validity, and narrative + time-fit dispatched concurrently. Use after the deck is drafted but before the talk.
disable-model-invocation: true
allowed-tools: Read, Bash, Agent
---

Run a parallel multi-agent review of a Marp slide deck. Three independent reviewers fan out concurrently; the orchestrator synthesizes their reports into a single prioritized punch list.

## When to use this skill

- After a deck draft exists and before the talk.
- Use this for **independent eyes** across orthogonal dimensions (visual / factual / narrative). Single-agent review tends to bias the next pass.
- Complements (does **not** replace):
  - `validate-slides` — mechanical Marp linting (frontmatter, asset refs, language)
  - `review-content` — single-agent narrative review (lighter, faster)

If you only want a quick narrative pass, prefer `review-content`. Use `review-deck` when the deck is content-stable enough to justify multi-angle review.

## Arguments

`$ARGUMENTS` should be one of:

- A path to a specific deck file (e.g., `Projects/VLA/BlindVLA/blind-vla-evaluation.md`)
- A directory containing exactly one Marp `*.md` deck file
- Empty — defaults to the most recently modified Marp `*.md` under `$PWD`

## Pre-flight (required)

Before dispatching any agents, gather the context the reviewers need to judge fit. Do **not** dispatch without these:

1. **Audience & venue** — lab meeting, advisor 1:1, conference rehearsal, etc.
2. **Time budget** — minutes of speaking time.
3. **Headline** — the *one thing* the audience should remember.
4. **Source material path** *(if any)* — the report / paper / data the deck is based on. Auto-detect: if the deck folder contains a `report.md` or similar, propose it; otherwise ask. The factual reviewer needs this; if there is no source, tell the factual reviewer to skip the cross-check and only verify internal consistency.

## Steps

1. Resolve the deck path (per Arguments). Verify the file exists and is readable.
2. Confirm the four pre-flight items with the user. If any are missing, ask before proceeding.
3. **Dispatch all three review agents in a single tool-use block (parallel)** — sequential dispatch defeats the purpose:
   - Visual → `slide-designer` agent
   - Factual + argument-validity → `tech-validator` agent
   - Narrative + one-message-per-slide + time-fit → `general-purpose` agent (with canonical prompt below)
4. Wait for all three reports to return.
5. **Synthesize**, do not concatenate. Group findings as **Convergence / Critical / Important / Polish** (see Output format).
6. Present the synthesis to the user and ask which items to apply.
7. Apply only what the user confirms. Hold any headline-altering items for explicit approval.

## Canonical agent prompts

Substitute the bracketed placeholders from pre-flight. Each prompt includes a word cap to keep results legible.

### Visual review — `slide-designer`

```
Review the Marp slide deck at <deck_path> for visual design consistency with the lis-lab theme.

Context:
- Audience: <audience>
- Time budget: <time_budget>
- Theme CSS: ~/tools/slide-tool/theme.css
- Patterns library: ~/tools/slide-tool/patterns/

Check:
- Layout, spacing, alignment consistency across slides
- Color / emphasis usage (bold, blockquote, accent-blue ***...***) — overused or off-theme?
- Slide density relative to <time_budget> — any single slide overloaded?
- Theme adherence — anything that would render off-theme?

Flag concrete issues with line numbers and brief suggested fixes. Do NOT review words / argument / numbers — other reviewers handle those. Report under 250 words.
```

### Factual + argument-validity review — `tech-validator`

```
Validate the Marp deck at <deck_path> against its source material at <source_path>.
(If <source_path> is "(none)", skip cross-checking and verify only internal consistency.)

Two jobs:

1. **Factual accuracy** — Do the numbers, citations, and paraphrased claims match the source exactly? Flag mismatches with line numbers.

2. **Argument validity (most important)** — For each conclusion the deck draws, does it actually follow from the evidence shown? Specifically:
   - Are field-level or population-level claims stated as conclusions of an n=1 experiment?
   - Are alternative explanations for the observed result silently dismissed?
   - Is the headline ("<headline>") supported by what the slides actually show, or asserted on top of them?

A deck can have all true facts but draw an unsupported conclusion — that is the failure mode that survives factual review and embarrasses the speaker in Q&A. Catch it.

Do NOT review layout / design or general writing style — other reviewers handle those. Report under 250 words.
```

### Narrative + time-fit — `general-purpose`

```
Review the narrative coherence of a <time_budget> Marp slide deck at <deck_path>.

Context:
- Audience: <audience>
- Headline: <headline>

Assess and cite slide / line numbers for each issue:

1. **Flow** — does each slide set up or pay off the next? Where does the thread break?
2. **Headline support** — is "<headline>" demonstrated by the slides or asserted on top of them?
3. **Listener gaps** — what would a member of <audience> ask "wait, what?" about? (undefined terms, unjustified leaps)
4. **One slide, one message** — does each slide carry exactly one idea, or are some carrying two-plus?
5. **Time fit** — estimate speaking time per slide at ~120 wpm. Does the total fit the <time_budget>? Flag overweight slides.
6. **Discussion seed** — if the final slide poses a question, is it strong enough to generate real engagement, or is it bait that invites reassurance?
7. **Cuts / missing** — any dead weight to cut? Anything load-bearing that's missing?

Do NOT review layout / design or numerical accuracy — other reviewers handle those. Report under 300 words.
```

## Output format

After all three reports return, present:

```
## Convergence (highest confidence — flagged by ≥2 reviewers)
- <issue> — flagged by <reviewer A> and <reviewer B> [slide / line]

## Critical (the talk fails without these)
- ...

## Important
- ...

## Polish
- ...
```

Each line: cite slide / line numbers and the originating reviewer in parentheses.

End with two questions:
- Which items to apply now? (Default suggestion: all of Critical + Important; Polish optional.)
- Any items to hold for discussion before applying? (Especially headline-altering ones.)

## Rules

- Dispatch the three agents **in parallel** (one tool-use block with three Agent calls). Sequential dispatch loses the independence that makes multi-agent review valuable.
- Pre-flight context is mandatory. Without audience / time / headline, the reviewers cannot judge fit.
- **Synthesize across reports.** Convergence between reviewers (same issue flagged by ≥2) is the highest-signal finding — surface it first.
- Do **not** apply fixes automatically. Reviewers report → user decides → orchestrator applies on confirmation.
- If the deck has no source material (e.g., a vision talk, not derived from a report), tell the factual reviewer to skip cross-checking and only verify internal consistency. Do not skip the agent.

## Tool paths

- Theme: `~/tools/slide-tool/theme.css`
- Patterns library: `~/tools/slide-tool/patterns/`
- Related skills: `validate-slides`, `review-content`, `build-pdf`
