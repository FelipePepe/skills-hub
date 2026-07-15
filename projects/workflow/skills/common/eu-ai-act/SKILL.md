---
name: eu-ai-act
description: >
  Detects and applies the EU Artificial Intelligence Act (AI Act) in projects with
  artificial intelligence systems. Proactively when starting a project with AI
  dependencies, detecting ML library imports, or when the user mentions AI, models,
  data, compliance, or regulation.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- The project has AI/ML dependencies (OpenAI, Anthropic, LangChain, TensorFlow, PyTorch, etc.)
- The code uses language model or content generation APIs
- The user mentions AI, regulatory compliance, training data, or regulations
- ML/AI library imports are detected in the source code
- The project works with biometrics, facial recognition, emotion inference, or scoring

## Scope Guard

- Do NOT use for projects without AI/ML components
- Do NOT use for general programming topics without AI
- If there is no AI system, there are NO applicable AI Act obligations

## Detection

When starting the project, proactively scan:

1. **Dependencies**: `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`
   - Keywords: `openai`, `anthropic`, `langchain`, `tensorflow`, `pytorch`, `transformers`, `replicate`, `ollama`, `groq`, `cohere`, `mistral`
2. **Imports in code**: look for AI library import patterns
3. **External API usage**: calls to AI model endpoints
4. **Sensitive data**: processing of biometric, health, financial, or children's data

## Workflow

1. **Classify** the AI system risk using `references/risk-matrix.md`
2. **Evaluate** obligations according to the risk level (prohibited / high risk / transparency / none)
3. **Apply** the corresponding checklist from `references/compliance-checklist.md`
4. **Verify** applicable deadlines in `references/deadlines.md`
5. **Generate** a compliance summary at the end of development

## Critical Rules

- **Prohibited systems**: Never help implement unacceptable-risk functionality
- **High risk**: If the system qualifies as high-risk, the code MUST include:
  - Integrated technical documentation (comments explaining the AI system)
  - Model decision logging
  - Human oversight mechanisms
  - Input data quality validation
- **Transparency**: The code MUST include metadata marks for AI-generated content (Watermarking, labels)
- **Personal data**: Prioritize data minimization and anonymization
- **GPAI models**: If using a general-purpose model, apply training transparency obligations

## Output

When reviewing code with AI, provide:

```
🇪🇺 EU AI Act Compliance Report
────────────────────────────────────
Risk Level: [unacceptable / high / limited / minimal]
Applicable Obligations: [list]
Deadline: [date or N/A]
Violations Found: [count]
Recommendations:
  1. [actionable item]
  2. [actionable item]
────────────────────────────────────
```

## Resources

- [`references/risk-matrix.md`](references/risk-matrix.md) — Detailed risk classification
- [`references/compliance-checklist.md`](references/compliance-checklist.md) — Actionable checklist by level
- [`references/deadlines.md`](references/deadlines.md) — Regulatory timeline
