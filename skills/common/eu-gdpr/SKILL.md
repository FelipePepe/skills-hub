---
name: eu-gdpr
description: >
  Detects and applies the EU General Data Protection Regulation (GDPR) in projects
  that handle personal data of EU citizens. Trigger: proactively when detecting
  personal data, user fields, cookies, tracking, profiles, or when the user
  mentions privacy, personal data, consent, or data regulations.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When to Use

- The project stores, processes, or transmits personal data (name, email, IP, location, etc.)
- Registration/login forms with user data are implemented
- There is tracking, analytics, cookies, or user profiles
- The user mentions privacy, personal data, consent, cookies, GDPR
- Sensitive data is handled (health, biometrics, political opinions, sexual orientation)
- Data is transferred outside the EU/EEA

## Scope Guard

- Do NOT use for projects without personal data (e.g. generic public data without identification)
- Do NOT use for backend-only projects with no EU user interaction
- If there is no personal data — GDPR does not apply

## Detection

At project start, proactively scan:

1. **Database schema**: fields with `email`, `phone`, `address`, `name`, `ip`, `geo`
2. **Forms/inputs**: registration, login, profile, contact forms
3. **Analytics/cookies**: `analytics.js`, `gtag.js`, `facebook pixel`, `hotjar`, `mixpanel`
4. **External APIs**: services that send data outside the EU (Stripe, Sentry, New Relic)
5. **Keywords in code**: `consent`, `cookie_policy`, `privacy`, `data_subject`, `right_to_erasure`
6. **Authentication**: JWT tokens, session cookies, OAuth providers

## Workflow

1. **Classify** data according to `references/data-categories.md`
2. **Evaluate** legal basis for processing (Art. 6) from `references/legal-basis.md`
3. **Apply** the corresponding checklist from `references/compliance-checklist.md`
4. **Generate** a compliance summary at the end of development

## Critical Rules

- **Sensitive data**: Never store special-category data without specific legal basis (Art. 9)
- **Consent**: Must be freely given, specific, informed, and unambiguous. Not pre-checked. Not silent.
- **Data subject rights**: Code MUST support: access, rectification, erasure, portability, objection, restriction
- **Privacy by design**: Data minimization, limited retention, encryption by default
- **International transfers**: Only to countries with adequacy decision or appropriate safeguards
- **DPO**: Mandatory for large-scale processing of sensitive data or systematic surveillance
- **Data breach**: Notify authority within 72 hours; notify data subjects without undue delay if high risk

## Output contract

```
DATA:{personal|special|children}
LEGAL_BASIS:{consent|contract|legal_obligation|legitimate_interest}
LOCATIONS:{eu-only|international}
RIGHTS:{list of supported rights}
VIOLATIONS:{n} RECOMMENDATIONS:{item1;item2|none}
```
No prose, no decorative separators. Fields on separate lines.

## Resources

- [`references/data-categories.md`](references/data-categories.md) — Data categories and protection level
- [`references/legal-basis.md`](references/legal-basis.md) — Legal bases for processing
- [`references/compliance-checklist.md`](references/compliance-checklist.md) — Actionable checklist by type
- [`references/dsar.md`](references/dsar.md) — Data Subject Rights guide
