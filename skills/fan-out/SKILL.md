---
name: fan-out
description: >-
  Size review by risk, tier a workflow's agents, and keep its results small. Use when writing a
  Workflow script, or when planning to review, verify or fix a change with several agents.
---

# Fan-out

Each agent of a workflow costs a prefix of 36-43k tokens, so spend one only where it finds
something a command would not.

## Review by risk

- Docs, a mechanical change, or one under 50 lines: a deterministic check, such as tests,
  linters or `git range-diff`, and no reviewer.
- Any other change: one combined reviewer.
- Security, concurrency or infrastructure: one reviewer a lens.

## Verify, then fix once

- Verify findings of medium severity or above, 5-10 to a checker, as a checker nears its
  compaction past 10.
- Escalate to `lean:expert` only where checkers disagree or the severity is high.
- Record the low findings, and fix none unasked.
- Fix once, then run the narrowest tests and linters that cover the fix, such as its package,
  module or test filter. CI runs the full suite. No model verifies the fix again.

## The script

- Each `agent()` names its role's agent, as `agentType: 'lean:checker'`, whose own model and effort
  apply. One with no agent type sets `model` and `effort`, or it takes the session's. The
  lean plugin's hook denies a call with none of the three.
- Give siblings the same prompt prefix, with what differs last, so they share the cache.
- A prompt passes paths and ids, never a bundle of earlier results. Each agent returns a schema
  with length caps.
- The script writes each full result to a file, and returns its path with a digest under 4k
  chars, as the notification of a run is cut near 8k.
- An agent that hits its turn limit returns `""`, with no mark. Treat `""` as a truncation, and
  record it.

## A run

- End a run within about 2 hours, with its state in a file. Before each serial unit, check that the
  base has not moved.
- A re-run keeps the earlier verdicts, and checks only the hunks changed since.
