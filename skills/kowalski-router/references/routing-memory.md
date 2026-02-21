# Routing Memory System

The router keeps a persistent log of every model decision it makes.
Over time, this log becomes a **decision intelligence layer** — the router
stops guessing and starts *knowing* which model works best for each task type.

## How It Works

```
Task arrives → Check memory for similar tasks → Route with confidence
                                                       │
                                                   Execute task
                                                       │
                                              Score the result
                                                       │
                                              Save to memory ←──┐
                                                                 │
                                          Next similar task uses this data
```

## Memory File: `routing-history.jsonl`

Each routing decision is ONE line in a `.jsonl` file (JSON Lines format).
One line = one decision. Easy to append, easy to parse, no corruption risk.

**Location**: Store alongside your bot's data directory.
Example: `data/routing-history.jsonl`

### Record Schema

```json
{
  "id": "rt_20260218_143022_a7f3",
  "timestamp": "2026-02-18T14:30:22Z",
  "task_type": "code_debug",
  "task_summary": "Fix null pointer in auth middleware",
  "complexity_estimate": "medium",
  "model_selected": "moonshot/kimi-k2.5",
  "model_was_fallback": false,
  "fallback_from": null,
  "tokens_in": 2340,
  "tokens_out": 1856,
  "latency_ms": 2100,
  "score": 8,
  "score_reason": "Fixed bug correctly, clean code, no issues",
  "escalated": false,
  "tags": ["code", "debug", "auth", "middleware"]
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique ID: `rt_YYYYMMDD_HHmmss_xxxx` |
| `timestamp` | ISO 8601 | When the decision was made |
| `task_type` | string | Category (see Task Types below) |
| `task_summary` | string | One-line description of the task (< 100 chars) |
| `complexity_estimate` | enum | `trivial` / `simple` / `medium` / `complex` |
| `model_selected` | string | Full model identifier used |
| `model_was_fallback` | bool | Was this a fallback from a cheaper model? |
| `fallback_from` | string? | Which model failed before this one |
| `tokens_in` | int | Actual input tokens consumed |
| `tokens_out` | int | Actual output tokens generated |
| `latency_ms` | int | Response time in milliseconds |
| `score` | int (1-10) | Quality score of the result |
| `score_reason` | string | Brief explanation of the score |
| `escalated` | bool | Did the task need a more powerful model? |
| `tags` | string[] | Searchable keywords about the task |

### Scoring Guide

```
Score 10 — Perfect. Output exceeded expectations.
Score 8-9 — Great. Minor improvements possible but task completed well.
Score 6-7 — Acceptable. Got the job done but with some issues.
Score 5   — Borderline. Needed manual corrections.
Score 3-4 — Poor. Significant errors or missing parts.
Score 1-2 — Failed. Wrong output, needed full redo or escalation.
```

**Scoring rules:**
- Score is based on OUTPUT QUALITY relative to the task, not the model
- If model was escalated (fallback), the FAILED attempt gets score 1-3
- If model was overkill (opus for a simple task), deduct 1 point for waste
- Auto-score when possible (tests pass = 8+, tests fail = 3-)

## Task Type Taxonomy

Standardize task types so memory lookups work:

```
heartbeat          — Ping, status check, keep-alive
lookup             — Simple data retrieval, fact check
format             — Convert, reformat, template fill
summary            — Summarize text or data
translate          — Language translation
code_generate      — Write new code
code_debug         — Fix bugs
code_review        — Review code quality/security
code_refactor      — Restructure existing code
code_test          — Write or run tests
write_short        — Short writing (< 500 words)
write_long         — Long writing (> 500 words)
data_analysis      — Analyze data, find patterns
data_extract       — Pull structured data from unstructured
api_call           — Make or parse API calls
image_analyze      — Understand image content
planning           — Strategic or architectural planning
evaluate           — Judge quality of another output
conversation       — Chat, dialogue management
other              — Doesn't fit categories above
```

## Querying Memory — Decision Logic

### Before Every Routing Decision

```python
def select_model(task_type, complexity, tags=[]):
    # 1. Search memory for similar past tasks
    history = search_history(
        task_type=task_type,
        complexity=complexity,
        tags=tags,
        limit=20  # last 20 similar tasks
    )
    
    if len(history) >= 3:
        # 2. We have enough data — use it
        return route_from_memory(history)
    else:
        # 3. Not enough data — use decision tree from SKILL.md
        return route_from_rules(task_type, complexity)


def route_from_memory(history):
    # Group by model, calculate average score
    model_scores = {}
    for record in history:
        model = record["model_selected"]
        if model not in model_scores:
            model_scores[model] = {"scores": [], "tokens": [], "latency": []}
        model_scores[model]["scores"].append(record["score"])
        model_scores[model]["tokens"].append(record["tokens_in"] + record["tokens_out"])
        model_scores[model]["latency"].append(record["latency_ms"])
    
    # Calculate efficiency score: quality / cost
    best_model = None
    best_efficiency = 0
    
    for model, data in model_scores.items():
        avg_score = sum(data["scores"]) / len(data["scores"])
        avg_tokens = sum(data["tokens"]) / len(data["tokens"])
        cost_multiplier = get_cost_multiplier(model)  # from model-matrix
        
        # Skip models that consistently score below 6
        if avg_score < 6:
            continue
        
        # Efficiency = quality / relative_cost
        efficiency = avg_score / cost_multiplier
        
        if efficiency > best_efficiency:
            best_efficiency = efficiency
            best_model = model
    
    return best_model


def search_history(task_type, complexity, tags, limit=20):
    """Search routing-history.jsonl for similar past decisions."""
    matches = []
    with open("data/routing-history.jsonl", "r") as f:
        for line in reversed(f.readlines()):  # most recent first
            record = json.loads(line)
            # Match by task_type first (strongest signal)
            if record["task_type"] == task_type:
                matches.append(record)
            # Also match by tags (weaker signal)
            elif set(tags) & set(record.get("tags", [])):
                matches.append(record)
            if len(matches) >= limit:
                break
    return matches
```

### After Every Execution — Log the Result

```python
def log_routing_decision(task_type, task_summary, complexity, model, 
                         tokens_in, tokens_out, latency_ms, score, 
                         score_reason, tags=[], was_fallback=False, 
                         fallback_from=None):
    record = {
        "id": f"rt_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:4]}",
        "timestamp": datetime.now().isoformat() + "Z",
        "task_type": task_type,
        "task_summary": task_summary[:100],
        "complexity_estimate": complexity,
        "model_selected": model,
        "model_was_fallback": was_fallback,
        "fallback_from": fallback_from,
        "tokens_in": tokens_in,
        "tokens_out": tokens_out,
        "latency_ms": latency_ms,
        "score": score,
        "score_reason": score_reason,
        "escalated": was_fallback,
        "tags": tags
    }
    
    with open("data/routing-history.jsonl", "a") as f:
        f.write(json.dumps(record) + "\n")
```

## Memory Maintenance

### Auto-Cleanup (Monthly)
```python
def cleanup_old_records(max_age_days=90, keep_min=100):
    """Remove records older than 90 days, but keep at least 100."""
    # Keeps memory fresh without losing all institutional knowledge
```

### Weekly Stats Report
Generate a summary to review routing performance:

```python
def weekly_report():
    """
    Output:
    - Total tasks routed this week
    - Model distribution (% per model)
    - Average score per model
    - Top 3 task types by volume
    - Worst routing decisions (score < 5) — review these!
    - Token savings estimate vs. "always use opus"
    """
```

Example output:
```
=== Routing Report: Week of 2026-02-10 ===
Tasks routed: 247
 
Model Usage:
  flash-lite    38%  (94 tasks)   avg score: 9.1
  flash         22%  (54 tasks)   avg score: 8.4
  kimi          28%  (69 tasks)   avg score: 8.0
  sonnet         5%  (12 tasks)   avg score: 8.7
  opus           4%  (10 tasks)   avg score: 9.3
  gemini-pro     3%   (8 tasks)   avg score: 8.1

Estimated savings vs all-opus: 78% fewer tokens, ~$142 saved
Bad decisions (score < 5): 3 tasks — all were flash on medium tasks
  → Recommendation: raise complexity threshold for code_debug
```

## Integration with SKILL.md

Update the decision tree in SKILL.md to add memory lookup as STEP ZERO:

```
START
  │
  ├─ STEP 0: Check routing memory for this task_type + tags
  │   HIT (3+ similar records, avg score ≥ 6) → Use best model from memory
  │   MISS → Continue to decision tree...
  │
  ├─ Is it a heartbeat/ping? → flash-lite
  ├─ Is it trivial? → flash
  │   ... (rest of tree)
```

## Key Principles

1. **Memory is append-only** — never edit past records, only add new ones
2. **3 records minimum** — don't trust memory until you have 3+ data points
3. **Score honestly** — inflated scores corrupt future decisions
4. **Review bad scores** — a score < 5 means the routing was wrong, learn from it
5. **Efficiency > raw quality** — a score-8 from flash beats a score-9 from opus
6. **Recency bias** — weight recent records more than old ones
7. **Keep it lightweight** — JSONL file, no database needed, grep-friendly