---
name: review-content
description: Review slide content for logical consistency, clarity, and presentation quality. Use to improve slides before a meeting.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

Review slide content for quality and logical consistency.

## Arguments

`$ARGUMENTS` should be one of:
- A path to a specific `slides.md` file
- A directory containing `slides.md`
- A date folder name like `2026-05-14` (searched under `$PWD/slides/`)
- Empty — reviews the most recent slide deck under `$PWD/slides/`

## Review Criteria

1. **Logical flow**: Do slides follow a coherent narrative? Flag contradictions between slides.
2. **Consistency**: Are claims in results slides supported by the discussion? Do conclusions match the evidence presented?
3. **Clarity**: Is each slide's message clear? Flag slides that try to convey too many points.
4. **Jargon (hard rule)**: Every technical term must either already be in the audience's working vocabulary OR get a one-line definition on its first appearance. Flag every undefined or under-defined term, even ones that "everyone in the lab obviously knows" — that defense is not sufficient. List each flagged term with its slide / line number.
5. **Emphasis**: Is `***bold italic***` (blue highlight) used effectively for key findings?
6. **Completeness**: Are there gaps in the story? (e.g., methods shown but no results, results without discussion)
7. **Conciseness**: Flag slides with too much text that could overflow.

## Output

For each issue found:
- Slide number and title
- The problem
- A specific suggestion for improvement

End with an overall assessment and top 3 priority improvements.

## Reference

Layout patterns are documented in `~/tools/slide-tool/patterns/` — refer to these when suggesting structural changes.
