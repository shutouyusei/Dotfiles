# Card

Rounded rectangle with colored top accent bar. Use for parallel items (steps, categories, options).

## Single card

```html
<div class="card">

**Card Title**

Body text here

</div>
```

## Multiple cards in a row

```html
<div style="display: flex; gap: 24px; margin-top: 16px;">

<div class="card" style="flex: 1;">

**Step 1**

Description

</div>

<div class="card green" style="flex: 1;">

**Step 2**

Description

</div>

<div class="card orange" style="flex: 1;">

**Step 3**

Description

</div>

</div>
```

## Color variants

- `class="card"` — blue (default)
- `class="card green"` — green
- `class="card red"` — red
- `class="card orange"` — orange
