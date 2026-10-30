---
name: context
description: >-
  Keep a long session's context small: how to read, how to bound output, when to write a
  checkpoint and compact, and how long a report runs. Use in a session that reads many files,
  runs many commands, or has run for a long time.
---

# Context

Each call carries the whole context again, so every line that enters it costs again on every later
call. Keep it small.

## Reads

- Find with `rg -n`, then read a range. Read a whole file only to edit most of it.
- Never re-read an unchanged file. `git diff` shows what changed.
- Batch independent reads and commands into one message.
- Open the memory index first, then at most 2 memory files that match the task.

## Output

- Bound output at the source: filter for failures, use `tail`, or write the log to a file and read
  its end.
- Keep a scratch script in a file, not in a heredoc that runs again.
- Run the narrowest tests that cover a change, such as its package or test filter. CI runs the
  full suite.

## Thinking

- Think about a read-only or obvious command no longer than it takes.
- Plan once a phase, and keep one copy of the plan.

## Checkpoints

Write a checkpoint at the end of each phase, and before a wait longer than the cache lives: 5
minutes for an agent, an hour for the main session. It holds:

- the decisions made, and why;
- `file:line` pointers;
- the open questions;
- the next step.

Then compact, and read the checkpoint, not the files. Where the repository's CLAUDE.md has a
`# Compact instructions` section, compaction follows it.

## Reports

- Keep a final report to 1,500 chars and a plan to 400 words, with the details in a file.
- Give no reply to a notification that brings nothing new.
