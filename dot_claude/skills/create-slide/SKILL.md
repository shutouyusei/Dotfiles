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
- **Avoid jargon when drafting slide content.** If a technical term must be used, define it in one line on its first appearance — do not assume the audience knows it. This applies to *every* slide drafted in conversation after the scaffold is created, not just the title slide.
- Always use `~/tools/slide-tool/template.md` as the base — do not invent a template.
- Do NOT overwrite an existing deck file — warn the user instead.
- Filename convention: `<title-slug>.md` directly under `output_dir` (no date subfolder).

## Visual content (SVGs)

Prefer visuals over walls of text. When a slide carries **data**, a **process**, or a **comparison**, draft an SVG to carry the message rather than describing it in bullets. A chart shows magnitude; a table forces the eye to compute. A diagram shows a pivot; bullets describe one.

**Use SVGs for:**

- **Result data** → bar chart / line chart, not a markdown table.
- **Before / after, abandoned / pursued, decisions** → two-panel comparison diagram.
- **Multi-step processes, hypothesis forks, contributions** → flowchart or numbered-arrow diagram.
- **Anything more graphical than an icon.** Author it as a standalone file, not inline HTML, so `slides.md` stays readable and the SVG is easy to iterate on.

**Authoring rules:**

- Save SVGs as standalone files in `<output_dir>/images/<name>.svg`. The `images/` directory is created during scaffolding (step 3 above).
- Embed via Marp width syntax: `![w:NNN](images/<name>.svg)`. Width 700–900 typically fits a content slide.
- Stay on-theme. Use the lis-lab palette:
  - **Accent / primary** — `#4A90D9` (blue)
  - **De-emphasis / failure** — `#D9534F` (red)
  - **Highlight / success** — `#5BA876` (green)
  - **Text primary** — `#262626`; **secondary** — `#666666`
  - **Font** — system sans-serif (`-apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif`)
- **One SVG = one message.** Don't pack three diagrams into one file.

See `~/tools/slide-tool/template.md` for the "Full-width external SVG" embedding convention and `~/tools/slide-tool/patterns/` for additional layout examples.

## Tool paths

- Template: `~/tools/slide-tool/template.md`
- Theme: `~/tools/slide-tool/theme.css`
- Patterns library (reference for layout choices): `~/tools/slide-tool/patterns/`
