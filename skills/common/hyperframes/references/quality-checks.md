# HyperFrames — quality checks

## Output checklist

Fast checks:
- `npx hyperframes lint`
- `npx hyperframes validate`
- design adherence verified when `design.md` exists

Slower checks:
- `npx hyperframes inspect`
- contrast warnings addressed
- choreography verified when animation changed substantially

## Visual inspect

Run:

```bash
npx hyperframes inspect
npx hyperframes inspect --json
```

Use it to catch:
- text spilling out of bubbles/cards
- clipping inside fixed boxes
- off-canvas text
- children escaping clipping containers

If overflow is intentional for animation, use `data-layout-allow-overflow` or `data-layout-ignore` as appropriate.

## Contrast

`hyperframes validate` includes contrast auditing.

If warnings appear:
- brighten text on dark backgrounds
- darken text on light backgrounds
- stay inside the chosen palette family
- rerun until clean

## Design adherence

If `design.md` exists, verify:
- colors match the declared palette
- typography matches the declared fonts/weights
- corners, spacing, and depth follow the design rules
- any avoidance rules are respected

If no `design.md` exists, verify:
- palette consistency across scenes
- no lazy defaults unless deliberately chosen

## Animation map

For new compositions or significant choreography changes, run:

```bash
node skills/hyperframes/scripts/animation-map.mjs <composition-dir> \
  --out <composition-dir>/.hyperframes/anim-map
```

Review:
- tween summaries
- ASCII timeline rhythm
- dead zones
- lifecycle oddities
- collision/offscreen/invisible flags
