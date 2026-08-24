# Viewer spec — Phase 3

The viewer is `assets/viewer.template.html`, already built and verified. Render
it by replacing its single placeholder `__ARCHITECTURE_JSON__` with the contents
of `architecture.json`, and write the result to `docs/archscope/index.html`.

Never hand-write the HTML and never edit the copy in `docs/`. If the viewer must
change, change the template so every future run inherits the fix. This is what
keeps "same input → same output" a property of the tool rather than a hope.

```bash
python3 - <<'EOF'
from pathlib import Path
tpl = Path('<skill>/assets/viewer.template.html').read_text()
data = Path('docs/archscope/architecture.json').read_text()
assert tpl.count('__ARCHITECTURE_JSON__') == 1
Path('docs/archscope/index.html').write_text(tpl.replace('__ARCHITECTURE_JSON__', data))
EOF
```

## What the template already guarantees

Three zones: CANVAS left (~65%), SCENARIOS right-top, STEPS right-bottom.

- **Layout is deterministic and fixed.** Columns are the six lanes in the order
  `client → frontend → backend → infra → data → external`, only those with
  nodes. Within a lane, nodes are sorted by `id`. Positions depend on the input
  alone, so selecting a flow can never move a card.
- Rectangular cards, 1px border, monospaced label, dimmed subtitle.
- `lane: data` nodes are distinguished by a doubled left edge — **shape, not
  colour**, so the amber accent stays reserved for selection state.
- No selection: every node at opacity 0.35 and **no edge drawn at all**.
- Active flow: participants at opacity 1 with an accent border; everything else
  dims but does not move.
- Only the active flow's edges are drawn, curved, each with a circular numbered
  badge at the curve midpoint matching the step number. Same-lane edges bow
  through the left gutter and fan out with vertical distance so sibling badges
  never stack.
- Write edges and the step's `call` are marked distinctly from reads.
- Hovering a step highlights its edge and its two nodes; hovering a node
  highlights the steps that touch it. `Esc` and "Clear selection" reset.
- A collapsible bottom panel is always accessible; its header shows the gap
  count and the resolved-access percentage before it is even opened, because
  the holes are part of the deliverable, not a footnote.

Aesthetics: near-black `#0d0d0f`, amber accent `#f5b301`, monospaced, no shadows
or gradients, high density.

Constraints: zero external dependencies (SVG + vanilla JS), zero localStorage,
works when opened over `file://`.

## Checking a rendered viewer

Headless Chromium is enough and needs no extension:

```bash
chromium --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
  --virtual-time-budget=3000 --window-size=1500,900 \
  --screenshot=out.png "file://$PWD/docs/archscope/index.html"
```

Add `--dump-dom` instead of `--screenshot` to assert structure: nodes carry
`class="node"` plus `act`/`hot`, drawn edges carry `class="edge"` and a
`.bnum` per step. Confirm the unselected state draws zero edges.
