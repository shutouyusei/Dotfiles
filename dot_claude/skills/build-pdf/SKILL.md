---
name: build-pdf
description: Render a Marp slide deck to PDF using the shared lab theme. Use before meetings.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob
---

Render Marp slides to PDF using the toolchain at `~/tools/slide-tool/`.

## Arguments

`$ARGUMENTS` should be one of:
- A path to a specific `slides.md` file
- A directory containing `slides.md`
- A date folder name like `2026-05-14` (searches `$PWD/slides/` for that folder)
- Empty — finds the most recent date folder under `$PWD/slides/`

## Steps

1. Locate the target `slides.md` file.
2. Run Marp with the shared theme and config:
   ```bash
   "$HOME/tools/slide-tool/node_modules/.bin/marp" \
     <slides_dir>/slides.md \
     -o <slides_dir>/slides.pdf \
     --theme "$HOME/tools/slide-tool/theme.css" \
     --config-file "$HOME/tools/slide-tool/marp.config.mjs" \
     --allow-local-files \
     --html
   ```
3. Verify the PDF was created and report its absolute path and file size.

## Notes

- Theme: `~/tools/slide-tool/theme.css`
- Config: `~/tools/slide-tool/marp.config.mjs` (sets `allowLocalFiles: true`, `html: true`)
- Marp binary: `~/tools/slide-tool/node_modules/.bin/marp` (installed by the dotfiles `install-deps` script)
- If the binary is missing, run `cd ~/tools/slide-tool && npm install`.
- If the build fails, check that referenced images exist relative to the slides file.
