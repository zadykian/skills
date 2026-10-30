---
name: delegate
description: >-
  Decide whether to hand work to a subagent, which agent takes it, how to write its brief, and
  how to read what it returns. Use before each spawn of an agent, and before a batch of them.
---

# Delegate

A spawn costs a prefix of about 40k tokens on its first call, and every later call of this
session carries each word that the agent hands back. So hand off work that earns that cost, and
keep the hand-back short.

## When

- Delegate a read too large for this context, work that is independent and runs in parallel, and
  a side quest whose steps this session does not need.
- Do a lookup of 3 calls or fewer inline, as the spawn costs more than the calls.

## To whom

Pick the `lean` agent of the role:

- `lean:scout` finds code and facts, and changes nothing.
- `lean:runner` runs builds, tests and CI waits, and returns the failures.
- `lean:checker` verifies a batch of 5–10 findings.
- `lean:implementer` carries out a change whose spec is written, and commits each step.
- `lean:expert` takes work that needs judgment: an analysis, an open design, research. Say in the
  brief why the work needs it. A spec'd change goes to `lean:implementer` instead.

A built-in agent takes `model` and `effort` on the call. Set both to the role's, as it runs on the
session's top model otherwise.

## The brief

Write the brief so that the agent needs nothing else. It gives:

- the goal, and what is ruled out, such as a path, an approach or a finding already known;
- the paths to read, and never their contents, as the agent reads them itself;
- the scope: what it may change, and what it leaves;
- the stop condition;
- the form of the report and its cap, 300 words, and the file for any detail.

## Results

- Spot-check one claim of the result against the source. Do not redo the work.
- Read a long result from its file with `jq` or `grep`, never `cat`.

## At once

- Run no more agents at once than `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` allows, or half the
  machine's cores where the variable is unset. The total has no cap.
- The Agent tool refuses a spawn past that cap, and queues none. Keep the queue yourself: start
  the next agent as one ends.
