---
name: ddia-data-ethics
description: >
  Guides ethical review of data-intensive systems involving predictive
  analytics, bias, accountability, feedback loops, privacy, tracking, consent,
  surveillance risk, and data power. Trigger: when a task handles personal
  data, tracking, profiling, recommendation, risk scoring, automated decisions,
  ML/AI predictions, privacy policy, consent, or user-impacting analytics.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Reviewing systems that collect, infer, score, rank, recommend, or decide about people.
- Designing analytics with personal data, tracking, consent, or sensitive attributes.
- Evaluating feedback loops and harms from automated decisions.

## Scope Guard

- This is not legal advice; pair with privacy and compliance review when needed.
- Do not reduce ethics to checklist compliance.
- Pair with `eu-gdpr` when EU personal data may be involved.

## Core Rules

- Predictive systems can amplify historical bias and create unfair exclusion.
- Accountability must remain with people and organizations, not algorithms.
- Feedback loops can reinforce harmful outcomes.
- Privacy is about control, context, and power, not just secrecy.
- Consent must be meaningful, informed, and revocable to be ethically useful.

## Workflow

1. Identify who the data describes and who benefits from processing it.
2. List decisions or recommendations that affect people.
3. Check for protected traits, proxies, and biased historical labels.
4. Evaluate consent, choice, retention, and secondary use.
5. Identify feedback loops and unintended incentives.
6. Define appeal, correction, explanation, and accountability paths.

## Review Checklist

- Can a person contest or correct an automated outcome?
- Are proxy variables recreating prohibited discrimination?
- Is tracking necessary for the user benefit claimed?
- Could the system punish vulnerable groups or amplify inequality?
- Are data retention and reuse bounded by user expectations?

## Source Trace

- DDIA 2e Chapter 14: Doing the Right Thing, pages 585-601.
- Key sections: predictive analytics; bias; accountability; feedback loops; privacy and tracking; consent; data power.
