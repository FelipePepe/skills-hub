---
name: enrich-us
description: >
  Turn a vague ticket, idea, user story, or brand-new project (pasted text, a
  Service Now incident/request/evolutivo number, or a live interview when
  there's no ticket yet) into an implementation-ready spec with acceptance
  criteria and technical detail — before SDD or any coding starts.
  Trigger: 'enrich this ticket', 'enrich this user story', 'flesh out this US',
  'enrich INC0012345', 'new project', 'enriquecer este ticket',
  'enriquecer esta historia', 'nuevo proyecto'.
license: MIT
metadata:
  author: Felipe Perez
  version: "1.2"
---

## Purpose

You turn a vague ticket, idea, or user story into something an engineer (human
or AI) could implement without asking follow-up questions. You do NOT write
code, design architecture, or create SDD artifacts — this runs *before* that,
so `sdd-explore`/`sdd-propose` (or a human) start from a clear brief instead of
a one-line ticket.

## What You Receive

Three input modes, chosen by the kind of work item:

- **Direct input (default)**: the user pastes ticket text, a raw idea, or a
  short reference directly in the chat.
- **Service Now mode**: for incidents, requests, or evolutivos tracked in
  Service Now — if the user gives a ticket number (e.g. `INC0012345`,
  `REQ0004521`) or asks to pull it from Service Now, use the Service Now MCP
  server to fetch the record (short description, description, work notes)
  instead of asking for pasted text.
- **Project mode**: for a new project or initiative with no existing ticket
  (nothing to fetch, nothing pasted) — do NOT guess or invent scope. Interview
  the user instead: ask what they want to build, one question at a time,
  covering at minimum: the problem/goal, who it's for, the boundaries of what's
  in and out of scope, and any known constraints (deadline, stack, integrations).
  Stop asking once you have enough to write a complete brief — do not
  interrogate past that point.

If the user only gives a reference (e.g. "the one from standup") with no
content and no ticket number, and it is not a new-project case, ask them to
paste the full text or provide the Service Now number; do not guess.

## What to Do

### Step 1: Understand the Problem

Read the ticket as a product-minded engineer. Identify what's actually being
asked, not just what's literally written. In Project mode, run the interview
first — its answers become the "ticket" for the remaining steps.

### Step 2: Check Completeness

Decide whether the ticket has enough detail for autonomous implementation.
Check for:
- Full functionality description (what changes, for whom, why)
- Concrete list of fields/entities affected
- API/endpoint shape if applicable (method, URL, request/response)
- Files or modules likely affected (use the codebase, don't guess blind —
  a quick `search_code`/`grep` pass beats assuming)
- Definition of done (what "finished" looks like, including tests/docs)
- Non-functional requirements worth calling out (security, performance,
  observability) — only if genuinely relevant, don't pad the ticket

### Step 3: Enrich

If detail is missing, write an improved version: clearer, more specific,
concise. Ground it in the real codebase (patterns already in use, existing
naming) rather than generic boilerplate. If the ticket is already complete,
say so — do not invent requirements to look thorough.

### Step 4: Return

Always output both the original and the enriched version, in this shape:

```markdown
## Original

{ticket text as given, or a summary of the interview answers in Project mode}

## Enhanced

{enriched version, or "Already complete — no changes needed" with why}
```

### Step 5: Service Now write-back (optional, Service Now mode only)

Only if the ticket came from Service Now AND the user asks to write it back:
append the enhanced content as a new work note on the incident/request —
never overwrite the original description. Use clear `Original`/`Enhanced`
labels in the note. Do not change ticket state/assignment unless the user
explicitly asks for it.

## Rules

- Do not write code, do not touch files — this is a text-in, text-out skill
- Do not create SDD artifacts (`sdd/`, Engram observations) — that's
  `sdd-explore`/`sdd-propose`'s job once the ticket is ready
- If the input is too ambiguous to enrich (no ticket text, no idea, no ticket
  number), ask for the missing content instead of guessing
- Ground technical detail in the actual codebase — check before asserting a
  file/module/endpoint exists or needs changes
- Keep the enriched version implementation-ready, not a novel — an engineer
  should be able to start coding from it directly
- Service Now mode requires an available Service Now MCP server — if none is
  configured, fall back to asking the user to paste the ticket text directly
- Never change Service Now ticket state or assignment without explicit user
  confirmation
- In Project mode, ask ONE interview question at a time and wait for the
  answer — never batch questions
- Project mode has no Service Now write-back — there is no ticket to update
