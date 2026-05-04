# Side-by-Side

Two-column layout for comparing items or pairing text with figures.

## Two text columns

```html
<div style="display: flex; gap: 32px; align-items: flex-start; margin-top: 12px;">

<div style="flex: 1;">

**Left Title**

- Point 1
- Point 2

</div>

<div style="flex: 1;">

**Right Title**

- Point A
- Point B

</div>

</div>
```

## Text + figure

```html
<div style="display: flex; gap: 32px; align-items: flex-start; margin-top: 12px;">

<div style="flex: 1;">

**Description**

Explanation text here

</div>

<div style="flex: 1; text-align: center;">

![w:480](assets/figure.png)

<div style="font-size: 0.75em; color: #7F7F7F; margin-top: 4px;">Caption</div>

</div>

</div>
```
