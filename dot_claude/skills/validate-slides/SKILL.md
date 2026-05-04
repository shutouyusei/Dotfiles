---
name: validate-slides
description: Validate Marp slides for formatting, language, and asset references. Use to check slides before a meeting.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash
---

Validate Marp slides for common issues.

## Arguments

`$ARGUMENTS` should be one of:

- A path to a specific Marp `.md` deck file (e.g., `Projects/VLA/BlindVLA/blind-vla-evaluation.md`)
- A directory containing exactly one Marp `.md` deck
- Empty — finds the most recently modified Marp `.md` deck under `$PWD` (recursive)

If the resolved directory contains multiple Marp `.md` files, ask the user which one to validate.

## Checks

1. **Language**: All content must be in English. Flag any Japanese text found in slide content (ignore HTML attributes and CSS).
2. **Frontmatter**: Verify `marp: true`, `theme: lis-lab`, `paginate: true` are present.
3. **Image references**: Every `![...](<path>)` must point to an existing file. Report missing images.
4. **Slide separators**: Ensure `---` separators are properly placed (blank lines before and after).
5. **Empty slides**: Flag any slides with no content between separators.
6. **Title slide**: Verify the first slide has `<!-- _class: title -->` and contains a date.

## Output

Report results as a checklist:
- Pass/fail for each check
- Specific issues with slide numbers and line numbers
- Suggestions for fixes

## Reference

- Theme: `~/tools/slide-tool/theme.css`
- Patterns: `~/tools/slide-tool/patterns/`
