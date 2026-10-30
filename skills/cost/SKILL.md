---
name: cost
description: >-
  Report what Claude Code sessions cost, from their transcripts: by tier, model and context size,
  cache writes by idle gap, the largest tool results, foreground polls, and each workflow's real
  tokens. Run by hand, to measure a baseline and the change after.
disable-model-invocation: true
argument-hint: "[SESSION...]"
---

# Cost

Run the report on the sessions the user names, or on the project's latest, and show it whole:

```sh
sh "${CLAUDE_SKILL_DIR}/cost.sh" $ARGUMENTS
```

A SESSION is a transcript's path, or its ID in the current directory's project, and takes its
agents. Several give one report, so a baseline passes a span of weeks, as
`~/.claude/projects/DIR/*.jsonl`.

Read no transcript yourself, as the report holds what they show. Sum it up in three sentences at
most, by the largest shares.
