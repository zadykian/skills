---
name: wait
description: >-
  Wait on work without holding the turn or the cache: run it in the background, watch for a
  change of state, and bound a foreground wait. Use when starting a build, a test run, a CI run or a
  deploy, when about to poll, or when scheduling a wake-up.
---

# Wait

A foreground poll holds the turn, and a wait past the cache's life pays a rewrite of the whole
context. The 5-minute cache covers an agent, and the 1-hour cache the main session.

## Run it in the background

- Run what takes over a few seconds with `run_in_background: true`, unless the next step needs it,
  and go on. Its notification wakes Claude.
- Watch CI and deploys with a `Monitor` that prints only on a change of state, failures and
  timeouts included. Run its command once in the foreground first, to check its output.
- Build no dashboard or poller unless the user asks for one.

## Bound a foreground wait

- Bound it with `timeout 240`, inside the 5-minute cache, which leaves a minute for the call that
  reads the result. The lean plugin's hook denies a foreground poll that no such bound covers.
- Schedule a wake-up within 270 s, or after 1,200 s or more, never near 300 s. A wake-up under 270 s
  keeps the cache warm, and a later one pays the miss anyway, so it waits long enough to spread it.
- A workflow notifies as it ends: set no fallback wake-up.
- A subagent on the 5-minute cache waits 4 minutes at most, then writes a handoff and ends.

## Before and after a push

- Before a push, run the fast CI checks locally, such as linters and rule checks, with the tests
  that cover the change.
- After a failed run, tell a flake from a regression by its log, reproduce the failed target
  locally, and push once.
- Check a token's scopes before a plan relies on them.
