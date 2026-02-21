---
name: kowalski-router
description: Analyze any incoming task and select the optimal AI model based on complexity, required capabilities, token budget, and latency needs. Use this skill BEFORE spawning any session or executing any task to maximize efficiency and minimize cost. Triggers on any use of sessions_spawn, or when planning multi-step workflows.
---

# Model Router Skill

Route every task to the cheapest model that can do it well.

## Core Philosophy

> **Don't use a cannon to kill a mosquito.**
> Most tasks don't need the most powerful model. The router's job is to find the
> *minimum viable model* for each task, then escalate only when needed.

## Quick Reference — Decision Tree

Use this flowchart for EVERY task before selecting a model:

```
START
  │
  ├─ STEP 0: CHECK MEMORY (references/routing-memory.md)
  │   Search routing-history.jsonl for same task_type + tags
  │   HIT (3+ records, avg score ≥ 6) → Use best model from memory ✅
  │   MISS → Continue to rules-based routing ↓
  │
  ├─ Is it a heartbeat/ping/status check?
  │   YES → gemini-2.0-flash-lite ⚡
  │
  ├─ Is it a trivial task? (greeting, simple lookup, format conversion, 
  │   short summary < 500 words, simple regex, basic math)
  │   YES → gemini-2.5-flash 🟢
  │
  ├─ Does it require IMAGE understanding or generation?
  │   YES → gemini-2.5-pro 🎨
  │
  ├─ Is it complex reasoning? (multi-step logic, code architecture,
  │   debugging subtle bugs, strategic planning, legal/financial analysis)
  │   YES → claude-opus-4-6 🧠
  │
  ├─ Is it medium complexity? (standard coding, writing, data analysis,
  │   summarization > 500 words, API integration, moderate debugging)
  │   YES → moonshot/kimi-k2.5 🌙 (default)
  │        └─ If Kimi unavailable → claude-sonnet-4-5
  │
  └─ Anything else / uncertain
      → moonshot/kimi-k2.5 🌙 (default)
```

> **IMPORTANT**: After EVERY execution, log the result to routing memory.
> See `references/routing-memory.md` for the full memory system.

## Token Optimization Strategy

### Before Execution
1. **Trim context**: Strip unnecessary conversation history before spawning
2. **Compress prompts**: Remove redundant instructions; be direct
3. **Set max_tokens wisely**: Match expected output length, don't leave defaults
4. **Batch similar tasks**: Group small tasks for a single model call instead of many

### Model-Specific Token Rules

| Model | Max Context | Sweet Spot | Avoid When |
|-------|-------------|------------|------------|
| `gemini-2.0-flash-lite` | 32k | < 1k tokens in/out | Output > 500 tokens |
| `gemini-2.5-flash` | 1M | < 8k tokens in/out | Needs deep reasoning |
| `moonshot/kimi-k2.5` | 256k | 2k–30k tokens in/out | Simple yes/no tasks |
| `claude-sonnet-4-5` | 200k | 2k–20k tokens in/out | Trivial tasks |
| `gemini-2.5-pro` | 1M | 5k–50k tokens in/out | No multimodal need |
| `claude-opus-4-6` | 200k | 5k–30k tokens in/out | Anything < complex |

### During Execution
- **Early stopping**: If model returns confident answer quickly, don't force elaboration
- **Streaming**: Use streaming for long outputs to detect quality early
- **Fallback chain**: If selected model fails or gives poor quality, escalate:
  `flash-lite → flash → kimi → sonnet → opus/pro`

### After Execution
- **Log token usage**: Track actual vs. estimated tokens per model per task type
- **Adjust routing**: If a cheaper model consistently handles a task type well, downgrade future routing

## How to Use This Skill

### Pattern 1 — Single Task Routing
```python
# 1. Classify the task
task = "Fix this null pointer exception in my auth middleware"
# 2. Apply decision tree → medium complexity, code, no images
# 3. Route
sessions_spawn(
    task=task,
    model="moonshot/kimi-k2.5",
    max_tokens=4096  # Expected: moderate code fix output
)
```

### Pattern 2 — Multi-Step Workflow Routing
```python
# Each step gets its own optimal model
workflow = [
    {"task": "Check if API is up",        "model": "gemini-2.0-flash-lite", "max_tokens": 100},
    {"task": "Parse response JSON",       "model": "gemini-2.5-flash",      "max_tokens": 500},
    {"task": "Analyze data patterns",     "model": "moonshot/kimi-k2.5",    "max_tokens": 4000},
    {"task": "Write strategic report",    "model": "claude-opus-4-6",       "max_tokens": 8000},
]
for step in workflow:
    sessions_spawn(**step)
```

### Pattern 3 — Adaptive Routing with Fallback
```python
# Try cheap first, escalate if quality is poor
result = sessions_spawn(task=task, model="gemini-2.5-flash", max_tokens=2000)
if result.quality_score < threshold or result.error:
    result = sessions_spawn(task=task, model="moonshot/kimi-k2.5", max_tokens=4000)
    if result.quality_score < threshold:
        result = sessions_spawn(task=task, model="claude-opus-4-6", max_tokens=8000)
```

## Task Classification Guide

When in doubt, use these signals to classify:

### Simple (→ flash / flash-lite)
- Single-step operation
- Clear input → clear output
- No ambiguity in instructions
- Pattern matching or template filling
- Keywords: "check", "convert", "format", "list", "count"

### Medium (→ kimi / sonnet)
- Multi-step but well-defined
- Standard coding tasks
- Writing with specific requirements
- Data processing with some logic
- Keywords: "implement", "write", "analyze", "summarize", "create"

### Complex (→ opus)
- Ambiguous or open-ended requirements
- Multi-file code changes with architectural decisions
- Debugging without clear reproduction steps
- Strategic/creative planning
- Keywords: "design", "architect", "debug this weird issue", "optimize", "why does this..."

### Multimodal (→ gemini-2.5-pro)
- Any task involving images as INPUT
- Screenshot analysis
- Diagram interpretation
- Visual content generation guidance

## Cost Tiers (Relative)

```
flash-lite  █░░░░░░░░░  $     (1x baseline)
flash       ██░░░░░░░░  $$    (~3x)
kimi-k2.5   ████░░░░░░  $$$   (~8x)
sonnet      █████░░░░░  $$$$  (~12x)
gemini-pro  ██████░░░░  $$$$  (~15x)
opus        ██████████  $$$$$ (~30x)
```

> **Rule of thumb**: If a $1 model can do the job, don't spend $30.

## Integration Checklist

When implementing this skill in your bot:

- [ ] Read this SKILL.md before every `sessions_spawn` call
- [ ] **Check routing memory first** — search `routing-history.jsonl` for similar past tasks
- [ ] If no memory hit, classify task complexity using the decision tree above
- [ ] Set `max_tokens` based on expected output (don't use defaults)
- [ ] **After execution, ALWAYS log the result** with a score (1-10)
- [ ] Log model selection + actual token usage for future optimization
- [ ] Implement fallback chain for failed/poor-quality responses
- [ ] Review `references/model-matrix.md` for detailed model capabilities
- [ ] Review `references/routing-memory.md` for the memory/scoring system
- [ ] Run weekly stats report to catch bad routing patterns

## Anti-Patterns to Avoid

1. **Always using the default model** — defeats the purpose of routing
2. **Using opus for everything "just to be safe"** — wastes 10-30x tokens/cost
3. **Not setting max_tokens** — lets models ramble, wastes output tokens
4. **Sending full conversation history** — trim to relevant context only
5. **Retrying same model on failure** — escalate to next tier instead
6. **Using multimodal model for text-only tasks** — pay premium for nothing