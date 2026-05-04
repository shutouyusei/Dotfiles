---
name: create-slide
description: Create a new Marp slide deck from the lab template. Works from any project folder; output location is configurable.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob
---

Create a new Marp slide deck from the shared template at `~/tools/slide-tool/template.md`.

## Arguments

`$ARGUMENTS` is parsed as: `[date] [output_dir]`

- **date** (optional): `MM-DD`, `YYYY-MM-DD`, or empty (defaults to next Wednesday)
- **output_dir** (optional): where to create the deck (defaults to `$PWD/slides`)

Examples:
- `(empty)` → creates next Wednesday's deck under `./slides/`
- `05-14` → creates `./slides/2026-05-14/slides.md`
- `2026-05-14 ../shared-decks` → creates `../shared-decks/2026-05-14/slides.md`

## Steps

1. Resolve the date (next Wednesday if empty).
2. Resolve `output_dir` (default `$PWD/slides`). Create it if missing.
3. Create `<output_dir>/<YYYY-MM-DD>/` and an `images/` subfolder.
4. Copy `~/tools/slide-tool/template.md` → `<output_dir>/<YYYY-MM-DD>/slides.md`.
5. Update the title slide with the correct date and author "Yusei".
6. Report the absolute path of the created file.

## Rules

- All slide content MUST be written in English.
- Always use `~/tools/slide-tool/template.md` as the base — do not invent a template.
- Do NOT overwrite an existing `slides.md` — warn the user instead.
- Default folder convention inside `output_dir`: `<YYYY-MM-DD>/slides.md`.

## Tool paths

- Template: `~/tools/slide-tool/template.md`
- Theme: `~/tools/slide-tool/theme.css`
- Patterns library (reference for layout choices): `~/tools/slide-tool/patterns/`
