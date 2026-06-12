# HyperFrames — data and timeline contracts

## Data attributes

### All clips

| Attribute | Required | Notes |
|---|---|---|
| `id` | Yes | unique identifier |
| `data-start` | Yes | seconds or clip reference |
| `data-duration` | For img/div/compositions | media can infer duration |
| `data-track-index` | Yes | same-track clips cannot overlap |
| `data-media-start` | No | trim offset in seconds |
| `data-volume` | No | `0..1` |

`data-track-index` is not visual layering; use CSS `z-index` for that.

### Composition clips

| Attribute | Required | Notes |
|---|---|---|
| `data-composition-id` | Yes | unique composition id |
| `data-start` | Yes | root composition uses `0` |
| `data-duration` | Yes | takes precedence over GSAP duration |
| `data-width` / `data-height` | Yes | explicit pixel dimensions |
| `data-composition-src` | No | external HTML path |

## Composition structure

Sub-compositions loaded with `data-composition-src` use a `<template>` wrapper.

Standalone root compositions do **not** use `<template>`; they put the `data-composition-id` element directly in `<body>`.

## Video and audio

- video must be `muted playsinline`
- audio should be a separate `<audio>` element
- never use video as the audio carrier

## Timeline contract

- all timelines start with `{ paused: true }`
- register each one in `window.__timelines`
- framework handles nesting; do not manually nest sub-timelines
- duration comes from `data-duration`
- do not create fake tweens just to set duration
