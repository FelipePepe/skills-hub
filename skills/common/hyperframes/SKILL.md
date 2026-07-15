---
name: hyperframes
description: Create video compositions, animations, title cards, overlays, captions, voiceovers, audio-reactive visuals, and scene transitions in HyperFrames HTML. Use when asked to build any HTML-based video content, add captions or subtitles synced to audio, generate text-to-speech narration, create audio-reactive animation (beat sync, glow, pulse driven by music), add animated text highlighting (marker sweeps, hand-drawn circles, burst lines, scribble, sketchout), or add transitions between scenes (crossfades, wipes, reveals, shader transitions). Covers composition authoring, timing, media, and the full video production workflow. For CLI commands (init, lint, preview, render, transcribe, tts) see the hyperframes-cli skill.
---

# HyperFrames

HTML is the source of truth for video. A composition is an HTML file with `data-*` timing attributes, CSS for appearance, and a GSAP timeline for animation.

## Approach

### Discovery (exploratory requests only)

For open-ended requests, clarify before choosing visuals:
- audience
- platform
- priority (speed, fidelity, motion quality, etc.)
- whether the user wants one direction or meaningful variations

For specific edit requests, skip discovery.

### Step 1: Design system

If `design.md` or `DESIGN.md` exists, read it first and treat it as the source of truth for:
- colors
- fonts
- constraints

If a specified font is missing locally, warn before authoring.

If no design file exists:
1. user named a mood/style → read `visual-styles.md`
2. user wants to browse visually → use `references/design-picker.md`
3. user wants speed → ask for minimal cues and use `house-style.md`

Important: `design.md` defines the brand, not the composition rules. Use:
- `references/video-composition.md`
- `house-style.md`

### Step 2: Prompt expansion

Run prompt expansion on almost every non-trivial composition so downstream work shares one grounded interpretation.

Read:
- `references/prompt-expansion.md`

### Step 3: Plan

Before writing HTML, define:
1. what the viewer should experience
2. structure (scenes, sub-compositions, tracks)
3. rhythm and energy pattern
4. timing anchors
5. final layout
6. motion plan

Build only what was asked. If additional scenes or layers would help, propose them instead of silently adding them.

**Hard gate:** before writing any composition HTML, confirm you already have a visual identity.

## Layout Before Animation

Use the layout-first rule from:
- `references/layout-before-animation.md`

Core rule:
- build the hero-frame layout statically first
- then animate into and out of that layout

## Data, Composition, and Timeline Contracts

Use the reference:
- `references/contracts.md`

Core rules:
- use `data-track-index`, not fake layering attributes
- register timelines in `window.__timelines`
- root compositions do not use `<template>`
- sub-compositions loaded from files do
- keep video muted and use separate audio tracks

## Rules (Non-Negotiable)

- deterministic output only; no time/random-dependent behavior without seeded control
- animate visual properties, not playback control or display toggles
- never animate the same property on the same element from conflicting timelines
- no `repeat: -1`; calculate finite repeats
- build timelines synchronously
- use `tl.set(...)` at the correct timeline position for later clips
- avoid `<br>` for automatic wrapping except deliberate display-title cases

## Scene Transitions (Non-Negotiable)

For multi-scene compositions:
- always use transitions between scenes
- always animate elements in
- do not animate scenes out before the transition, except on the final scene
- the final scene may fade to black or otherwise exit fully

Read transition guidance from:
- `references/transitions.md`
- `references/beat-direction.md`

## Animation Guardrails

- offset first animation slightly from `t=0`
- vary eases inside a scene
- avoid repetitive entrance patterns
- avoid banding-prone full-screen dark linear gradients
- size text for rendered video, not web UI
- use `font-variant-numeric: tabular-nums` for numeric columns

## Typography and Assets

- built-in fonts: specify them normally in CSS
- custom fonts: require local `.woff2` files and warn if missing
- add `crossorigin="anonymous"` to external media
- use `window.__hyperframes.fitTextFontSize(...)` for dynamic overflow-sensitive text
- root files live beside `index.html`; sub-compositions use relative paths accordingly

## Editing Existing Compositions

- read existing source files before changing them
- match real values from the composition instead of guessing
- only change what was requested
- preserve unrelated timing and structure

## Output Checklist

Use the detailed quality workflow from:
- `references/quality-checks.md`

Minimum expectation:
- `lint` and `validate` pass
- design adherence checked
- inspect/contrast/choreography checks run when the change warrants them

## References (loaded on demand)

Core references:
- `references/video-composition.md`
- `references/beat-direction.md`
- `references/motion-principles.md`
- `references/typography.md`
- `references/transitions.md`

Common feature references:
- `references/captions.md`
- `references/tts.md`
- `references/audio-reactive.md`
- `references/css-patterns.md`
- `references/techniques.md`
- `references/narration.md`
- `references/transcript-guide.md`
- `references/dynamic-techniques.md`
- `references/design-picker.md`

Local style references:
- `visual-styles.md`
- `house-style.md`
- `patterns.md`
- `data-in-motion.md`

Related skills:
- `hyperframes-cli` for CLI commands
- `/gsap` for GSAP-specific patterns and effects
