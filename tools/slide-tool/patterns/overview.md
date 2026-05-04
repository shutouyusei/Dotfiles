# Overview

Goal → arrow → step cards flow. Use on the first content slide to show the presentation structure.

```html
<div class="overview">

<div class="goal">

**Last Week's Goal**

Goal description

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
```

## Step label colors

- `step-label blue` / `green` / `red` / `orange` — solid colored
- `step-label dashed` — dashed border, for "next" or "TBD"
