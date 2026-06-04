---
name: eu-ai-act
description: >
  Detects and applies the EU Artificial Intelligence Act in projects with AI systems.
  Trigger: proactively when starting a project with AI/ML dependencies, detecting ML library
  imports, or when the user mentions AI, models, data, compliance, or regulation.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When to Use

- The project has AI/ML dependencies (OpenAI, Anthropic, LangChain, TensorFlow, PyTorch, etc.)
- The code uses language model or content generation APIs
- The user mentions AI, regulatory compliance, training data, or regulations
- ML/AI library imports are detected in the source code
- Working with biometrics, facial recognition, emotion inference, or scoring

## Scope Guard

- Do NOT use for projects without AI/ML components
- Do NOT use for general programming discussions without AI
- If there is no AI system, there are no AI Act obligations to apply

## Detection

At project start, proactively scan:

1. **Dependencies**: `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`
   - Keywords: `openai`, `anthropic`, `langchain`, `tensorflow`, `pytorch`, `transformers`, `replicate`, `ollama`, `groq`, `cohere`, `mistral`
2. **Code imports**: look for AI library import patterns
3. **External API calls**: calls to AI model endpoints
4. **Sensitive data**: processing of biometric, health, financial, or minor-related data

## Workflow

1. **Classify** the AI system risk using `references/risk-matrix.md`
2. **Evaluate** obligations based on risk level (prohibited / high-risk / transparency / none)
3. **Apply** the corresponding checklist from `references/compliance-checklist.md`
4. **Verify** applicable deadlines in `references/deadlines.md`
5. **Generate** a compliance summary at the end of development

## Critical Rules

- **Prohibited systems**: Never help implement unacceptable-risk functionality
- **High risk**: If the system qualifies as high-risk, code MUST include:
  - Integrated technical documentation (comments explaining the AI system)
  - Model decision logging
  - Human oversight mechanisms
  - Input data quality validation
- **Transparency**: Code MUST include metadata marks for AI-generated content (watermarking, labels)
- **Personal data**: Prioritize data minimization and anonymization
- **GPAI models**: If a general-purpose model is used, apply training transparency obligations

## Output contract

```
RISK:{unacceptable|high|limited|minimal}
OBLIGATIONS:{list separated by ;}
DEADLINE:{date|n/a}
VIOLATIONS:{n} RECOMMENDATIONS:{item1;item2|none}
```
No prose, no decorative separators. Fields on separate lines.

## Resources

- [`references/risk-matrix.md`](references/risk-matrix.md) — Detailed risk classification
- [`references/compliance-checklist.md`](references/compliance-checklist.md) — Actionable checklist by level
- [`references/deadlines.md`](references/deadlines.md) — Regulatory timeline
