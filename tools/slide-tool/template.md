---
marp: true
theme: lis-lab
paginate: true
math: katex
---

<!-- _class: title -->
<!-- _paginate: false -->

# Weekly Progress Report

## Topic Title

Author Name — Month DD, YYYY

---

<!-- header: Overview -->

# Overview

<div class="overview">

<div class="goal">

**Last Week's Goal**

Goal description here

</div>

<div class="goal-arrow">→</div>

<div class="results">

<div class="step">
<div class="step-label blue">Step 1</div>
<div class="step-detail">Detail line 1<br/>Detail line 2</div>
</div>

<div class="arrow">→</div>

<div class="step">
<div class="step-label green">Step 2</div>
<div class="step-detail">Detail line 1<br/>Detail line 2</div>
</div>

<div class="arrow">→</div>

<div class="step">
<div class="step-label red">Step 3</div>
<div class="step-detail">Detail line 1<br/>Detail line 2</div>
</div>

<div class="arrow">→</div>

<div class="step">
<div class="step-label dashed">Next?</div>
<div class="step-detail">Today's<br/>discussion</div>
</div>

</div>

</div>

---

<!-- header: Background -->

# Side-by-Side Layout

<div style="display: flex; gap: 32px; align-items: flex-start; margin-top: 12px;">

<div style="flex: 1; text-align: center;">

**Left Title**

![w:480](assets/left_figure.png)

<div style="font-size: 0.75em; color: #7F7F7F; margin-top: 4px;">Caption for left figure</div>

</div>

<div style="flex: 1; text-align: center;">

**Right Title**

![w:480](assets/right_figure.png)

<div style="font-size: 0.75em; color: #7F7F7F; margin-top: 4px;">Caption for right figure</div>

</div>

</div>

---

<!-- header: Method -->

# Centered Table

<div style="display: flex; justify-content: center;">

| | Column A | Column B |
|---|---|---|
| **Row 1** | Data | Data |
| **Row 2** | Data | Data |
| **Row 3** | Data | Data |

</div>

- Additional note below the table
- Another note if needed

---

<!-- header: Results -->

# Figure with Caption

<div style="text-align: center;">

![w:900](assets/result_figure.png)

</div>

<div style="text-align: center; margin-top: 8px; font-size: 0.85em;">

One-line caption describing ***the key finding***

</div>

---

<!-- header: Figure + Text -->

# Image + Commentary (side-by-side)

<div style="display: flex; gap: 24px; align-items: center; justify-content: center; margin-top: 8px;">

<div style="flex-shrink: 0;">

![w:420](assets/main_figure.png)

</div>

<div style="flex-shrink: 0;">

![w:500](assets/commentary.svg)

</div>

</div>

<div style="margin-top: 12px; color: #888888; font-size: 0.78em; text-align: right;">Figure: Source / citation</div>

---

<!-- header: External SVG -->

# Full-width external SVG

For anything more graphical than icons (flowcharts, hypothesis forks, numbered contributions), author the illustration as a standalone file in `assets/` and embed it. This keeps `slide.md` readable and the SVG easy to iterate on.

![w:1020](assets/my_diagram.svg)

---

<!-- header: Discussion -->

# Discussion

- **Finding 1** provides evidence of X
- **Finding 2** shows Y, but this alone is insufficient to confirm Z
- **Finding 3** suggests W, but fluctuates without converging
- Overall, the results demonstrate A, but ***open issue B*** remains

---

<!-- header: Next Steps -->

# Next Steps

<div style="display: flex; gap: 24px; margin-top: 16px;">

<div class="card" style="flex: 1;">

**Task 1 Title**

Description of what will be done next

</div>

<div class="card green" style="flex: 1;">

**Task 2 Title**

Description of another planned task

</div>

</div>
