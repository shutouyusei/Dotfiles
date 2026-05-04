# marp-lab-theme

Marp theme and slide template for lab weekly meetings, with Claude Code skills for automated slide workflow.

## Setup

```bash
git clone git@github.com:shutouyusei/marp-lab-theme.git
cd marp-lab-theme
npm install
```

## Preview & Build

```bash
# Live preview
npx marp -s slides

# Build single slide
npx marp slides/syncmap/03-18/title.md -o slides/syncmap/03-18/slides.pdf --allow-local-files --html --theme theme.css

# Build all
npm run build:pdf
```

## Theme

`theme.css` — Custom Marp theme (`lis-lab`) based on a lab presentation template.

- Font: Noto Sans JP (Google Fonts)
- Accent colors: blue `#2E5B96`, green `#3E9288`, red `#C03936`, orange `#ED7D31`
- `**bold**` renders in dark text, `***bold italic***` renders in accent blue for emphasis

### Slide Classes

| Directive | Usage |
|---|---|
| `<!-- _class: title -->` | Title slide with left blue border |
| `<!-- _class: divider -->` | Section divider with centered text |
| `<!-- _class: end -->` | Closing slide |

## Template

`template.md` — Slide template with common layout patterns:

- **Overview** — Goal card → arrow → result cards
- **Side-by-Side** — Two figures with captions
- **Centered Table** — Table wrapped in flex container
- **Figure with Caption** — Centered image + one-line caption
- **Discussion** — Bullet-point analysis
- **Next Steps** — Two-column task cards

## Folder Structure

```
slides/
  {project_name}/
    {date-or-title}/
      {date-or-title}.md      # Slide deck (filename matches folder)
      assets/                  # Images and other files
```

Example:
```
slides/
  syncmap/
    03-18/
      03-18.md
      assets/
  robustness/
    soft-robotics-direction/
      soft-robotics-direction.md
      assets/
```

## Claude Code Skills

Requires [Claude Code](https://claude.ai/code). Skills are invoked as slash commands.

| Command | Description |
|---|---|
| `/create-slide [project] [MM-DD]` | Create a new slide deck from template |
| `/build-pdf [path]` | Build PDF from slides |
| `/validate-slides [path]` | Check language, image refs, and formatting |
| `/review-content [path]` | Review logical consistency and clarity |

## Claude Code Agents

Subagents are automatically invoked by Claude when relevant.

| Agent | Description |
|---|---|
| `slide-designer` | Reviews visual design consistency with the theme |
| `tech-validator` | Checks technical content accuracy (formulas, metrics, algorithms) |

## License

ISC
