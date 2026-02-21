# Model Matrix — Detailed Reference

Last updated: 2026-02-18

## Model Profiles

---

### gemini-2.0-flash-lite ⚡
**Role**: Ultra-lightweight / Heartbeat  
**Provider**: Google  
**Context Window**: 32,768 tokens  
**Latency**: ~200-400ms  
**Cost Tier**: $ (cheapest)

**Best For**:
- Health checks, pings, status polling
- Boolean yes/no decisions
- Simple string extraction or formatting
- Heartbeat messages to keep connections alive
- Trivial math (2+2, unit conversions)

**Avoid For**:
- Any output > 500 tokens
- Tasks requiring reasoning or nuance
- Multi-step logic
- Code generation beyond one-liners

**Token Budget Guidance**:
- Input: Keep under 500 tokens
- Output: Expect 10-200 tokens
- max_tokens setting: 256-512

---

### gemini-2.5-flash 🟢
**Role**: Fast & Economic General Purpose  
**Provider**: Google  
**Context Window**: 1,048,576 tokens  
**Latency**: ~400-800ms  
**Cost Tier**: $$ (low)

**Best For**:
- Simple Q&A and lookups
- Text reformatting and conversion
- Short summaries (< 500 words)
- Template filling
- Basic data extraction from structured text
- Simple regex generation
- Translation of short texts
- Parsing JSON/XML responses

**Avoid For**:
- Complex reasoning chains
- Nuanced writing (tone-sensitive, persuasion)
- Multi-file code changes
- Tasks where subtle errors are costly

**Token Budget Guidance**:
- Input: Up to 8k tokens efficiently
- Output: 100-2000 tokens
- max_tokens setting: 512-2048

---

### moonshot/kimi-k2.5 🌙
**Role**: Default Workhorse  
**Provider**: Moonshot AI  
**Context Window**: 262,144 tokens  
**Latency**: ~1-3s  
**Cost Tier**: $$$ (moderate)

**Best For**:
- Standard coding (implement feature, fix bugs, write tests)
- Medium-length writing (blog posts, documentation, emails)
- Data analysis and summarization
- API integration and glue code
- Conversation and dialogue management
- Most day-to-day bot tasks

**Avoid For**:
- Trivial tasks (overkill, use flash instead)
- Tasks requiring frontier-level reasoning
- Image understanding
- Safety-critical code (use opus for review)

**Token Budget Guidance**:
- Input: 2k-30k tokens (sweet spot)
- Output: 500-8000 tokens
- max_tokens setting: 2048-8192

**Notes**:
- This is your default. When in doubt, use Kimi.
- 256k context is generous — good for large codebases
- If Kimi is down or rate-limited, fall back to claude-sonnet-4-5

---

### anthropic/claude-sonnet-4-5 🔵
**Role**: Balanced Fallback  
**Provider**: Anthropic  
**Context Window**: 200,000 tokens  
**Latency**: ~1-3s  
**Cost Tier**: $$$$ (moderate-high)

**Best For**:
- Kimi fallback for all medium-complexity tasks
- Nuanced writing where tone matters
- Code review with explanation
- Tasks requiring strong instruction-following
- Structured output generation (JSON, XML, specific formats)

**Avoid For**:
- Trivial tasks (still overkill)
- Pure multimodal tasks (gemini-pro is better)
- Budget-constrained batch operations

**Token Budget Guidance**:
- Input: 2k-20k tokens
- Output: 500-6000 tokens
- max_tokens setting: 2048-8192

**Notes**:
- Very reliable instruction follower
- Good at structured outputs
- Slightly better at nuanced writing than Kimi

---

### google/gemini-2.5-pro 🎨
**Role**: Multimodal Specialist  
**Provider**: Google  
**Context Window**: 1,048,576 tokens  
**Latency**: ~2-5s  
**Cost Tier**: $$$$ (high)

**Best For**:
- Image analysis and understanding
- Screenshot-to-code
- Diagram/chart interpretation
- Visual content description
- Tasks combining text + image reasoning
- Processing large documents with images

**Avoid For**:
- Text-only tasks (you're paying multimodal premium for nothing)
- Simple image tasks that flash could handle
- Real-time/low-latency needs

**Token Budget Guidance**:
- Input: 5k-50k tokens (images are token-heavy)
- Output: 500-8000 tokens
- max_tokens setting: 2048-8192

**Notes**:
- 1M context is huge — can process entire documents with images
- Image tokens are expensive, budget accordingly
- Use ONLY when the task actually involves visual input

---

### anthropic/claude-opus-4-6 🧠
**Role**: Heavy Reasoning / Critical Tasks  
**Provider**: Anthropic  
**Context Window**: 200,000 tokens  
**Latency**: ~3-10s  
**Cost Tier**: $$$$$ (highest)

**Best For**:
- Complex multi-step reasoning
- Architectural decisions and system design
- Debugging subtle/intermittent issues
- Security-sensitive code review
- Strategic planning and analysis
- Legal or financial document analysis
- Tasks where errors are very costly
- Evaluating other models' outputs

**Avoid For**:
- EVERYTHING ELSE. This is the expensive option.
- Simple coding tasks
- Basic writing
- Data formatting
- Anything a cheaper model can handle

**Token Budget Guidance**:
- Input: 5k-30k tokens
- Output: 1000-10000 tokens
- max_tokens setting: 4096-16384

**Notes**:
- Reserve for genuinely hard problems
- Excellent for "judge" role — evaluating other outputs
- Worth the cost for decisions with high impact
- If you're using this more than 10% of the time, your routing is wrong

---

## Quick Selection Matrix

| Task Type | Primary | Fallback |
|-----------|---------|----------|
| Heartbeat/Ping | flash-lite | flash |
| Simple lookup | flash | kimi |
| Format/Convert | flash | kimi |
| Short summary | flash | kimi |
| Standard code | kimi | sonnet |
| Writing (medium) | kimi | sonnet |
| Data analysis | kimi | sonnet |
| Image analysis | gemini-pro | opus (text desc.) |
| Complex debug | opus | sonnet |
| Architecture | opus | kimi (draft) → opus (review) |
| Security review | opus | sonnet |
| Evaluate outputs | opus | sonnet |

## Escalation Chain

When a model fails or produces poor quality:

```
flash-lite → flash → kimi → sonnet → opus
                              ↗
                    gemini-pro (if multimodal needed)
```

**Escalation Triggers**:
- Model returns error or timeout
- Output is clearly wrong or incomplete
- Confidence signals are low
- Task turns out more complex than initially classified
- User reports dissatisfaction with output quality

## Token Cost Estimation Formulas

Use these rough multipliers to estimate relative cost:

```
flash-lite:  input_tokens × 1   + output_tokens × 1
flash:       input_tokens × 3   + output_tokens × 3
kimi:        input_tokens × 8   + output_tokens × 8
sonnet:      input_tokens × 12  + output_tokens × 12
gemini-pro:  input_tokens × 15  + output_tokens × 15
opus:        input_tokens × 30  + output_tokens × 30
```

> These are relative estimates for routing decisions, not actual pricing.
> Check provider pricing pages for exact rates.