# HyperFrames — Layout Before Animation

## Principle

Position each element where it should appear at its most visible moment first. Build that static HTML/CSS layout before adding motion.

Why:
- prevents guessing final positions from offscreen start states
- exposes overlaps early
- makes entrances and exits describe motion instead of layout

## Process

1. Identify the hero frame of the scene.
2. Write static CSS for that frame.
3. Use `gsap.from()` for entrances to the CSS position.
4. Use `gsap.to()` for exits from the CSS position.

## Container rule

The `.scene-content` container should normally fill the scene:

```css
.scene-content {
  width: 100%;
  height: 100%;
  padding: 120px 160px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  box-sizing: border-box;
}
```

Use padding to push content inward. Avoid absolute-positioning full content containers unless the layout truly requires it. Reserve `position: absolute` mainly for decoratives.

## Example flow

```js
tl.from(".title", { y: 60, opacity: 0, duration: 0.6, ease: "power3.out" }, 0);
tl.from(".subtitle", { y: 40, opacity: 0, duration: 0.5, ease: "power3.out" }, 0.2);
tl.to(".title", { y: -40, opacity: 0, duration: 0.4, ease: "power2.in" }, 3);
```

## Shared-space rule

If two elements share space at different times, both still need correct CSS positions for their own hero frames. Timeline ordering prevents coexistence; layout correctness prevents accidental overlap.

## Intentional overlap

Allowed examples:
- glows behind text
- depth layers
- card stacks
- decorative z-stacked motifs

The goal is to catch accidental overlap, not to ban layered design.
