---
name: create-slide
description: Create a new Marp slide deck from the lab template. Works from any project folder; output location is configurable.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob
---

Create a new Marp slide deck from the shared template at `~/tools/slide-tool/template.md`.

## Before you start (required)

Slides are conversation-first, not file-first. Do **not** create any files until the following are settled with the user:

1. **Audience & venue** — lab meeting, advisor 1:1, conference rehearsal, etc. Determines how much background to assume.
2. **Time budget** — minutes available. Drives slide count.
3. **The headline** — the *one thing* the audience should remember. Surface 2–3 candidate headlines from the source material and ask the user to pick one.
4. **Structure** — mirror the source document, or reorganize for the talk (e.g. lead with the conclusion, then justify with evidence)?

Only after these four are agreed, run the steps below.

## Arguments

`$ARGUMENTS` is parsed as: `[output_dir]` (optional)

The slide title and presentation date are determined during the conversation-first discovery (above), **not** from args. The filename is derived from the agreed title via slugification (lowercase, hyphens, no special characters).

- **output_dir** (optional): where to create the deck (defaults to `$PWD/slides`)

Examples:
- `(empty)` → creates `./slides/<title-slug>.md`
- `Projects/VLA/BlindVLA/` → creates `Projects/VLA/BlindVLA/<title-slug>.md`

## Steps

1. From the conversation, derive a title slug (lowercase, hyphens, no special chars). Confirm the slug with the user before writing.
2. Resolve `output_dir` (default `$PWD/slides`). Create it if missing.
3. Ensure `<output_dir>/images/` exists.
4. Copy `~/tools/slide-tool/template.md` → `<output_dir>/<title-slug>.md`.
5. Update the title slide with the agreed title, presentation date, and author "Yusei".
6. Report the absolute path of the created file.

## Rules

- All slide content MUST be written in English.
- Always use `~/tools/slide-tool/template.md` as the base — do not invent a template.
- Do NOT overwrite an existing deck file — warn the user instead.
- Filename convention: `<title-slug>.md` directly under `output_dir` (no date subfolder).

## Tool paths

- Template: `~/tools/slide-tool/template.md`
- Theme: `~/tools/slide-tool/theme.css`
- Patterns library (reference for layout choices): `~/tools/slide-tool/patterns/`
