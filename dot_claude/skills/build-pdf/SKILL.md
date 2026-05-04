---
name: build-pdf
description: Render a Marp slide deck to PDF using the shared lab theme. Use before meetings.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob
---

Render any Marp deck to PDF using the toolchain at `~/tools/slide-tool/`. Output filename mirrors the input (`<title-slug>.md` → `<title-slug>.pdf`) so this works with the title-based filenames produced by `create-slide`.

## Arguments

`$ARGUMENTS` should be one of:

- A path to a specific Marp `.md` deck file (e.g., `Projects/VLA/BlindVLA/blind-vla-evaluation.md`)
- A directory containing exactly one Marp `.md` deck
- Empty — finds the most recently modified Marp `.md` deck under `$PWD` (recursive)

## Steps

1. Locate the target deck file. If the resolved directory contains multiple Marp `.md` files, ask the user which one.
2. Derive the output path by swapping the `.md` extension for `.pdf`, keeping the same directory.
3. Run Marp with the shared theme and config:
   ```bash
   "$HOME/tools/slide-tool/node_modules/.bin/marp" \
     <deck_path> \
     -o <pdf_path> \
     --theme "$HOME/tools/slide-tool/theme.css" \
     --config-file "$HOME/tools/slide-tool/marp.config.mjs" \
     --allow-local-files \
     --html
   ```
4. Verify the PDF was created and report its absolute path and file size.

## Notes

- Theme: `~/tools/slide-tool/theme.css`
- Config: `~/tools/slide-tool/marp.config.mjs` (sets `allowLocalFiles: true`, `html: true`)
- Marp binary: `~/tools/slide-tool/node_modules/.bin/marp` (installed by the dotfiles `install-deps` script)
- If the binary is missing, run `cd ~/tools/slide-tool && npm install`.
- If the build fails, check that referenced images exist relative to the deck file.
- To produce HTML or PPTX instead of PDF, swap the `.pdf` extension in the `-o` argument — Marp picks format from the output extension.
