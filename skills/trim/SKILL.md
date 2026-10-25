---
name: trim
description: >-
  Trim a repository's code comments or Markdown docs to the writing policy and its Vale rules,
  keeping every fact. Use on files that fail Vale or the policy's caps, or that restate the code or
  the help.
argument-hint: FILE...
---

# Trim comments and docs

Trim `$ARGUMENTS` to the writing policy. Shorter, never poorer: each fact stays in the one place
it belongs.

## The repository's rules

The `writing` skill holds the policy: what a comment and a doc say, the caps and Vale's rules.
Read it first. It holds in every repository. The repository's CLAUDE.md and `.claude/rules/` name
facts alone, such as the checks to run and the files that Vale reads, as `.vale.ini` sets them.

## Comments

- Keep a block's purpose in one or two sentences, or a reason the code cannot show. Delete
  sentences that narrate what the code does.
- A reason that a decision records becomes a link: "see decision N".
- Hold each block to the policy's caps. Move the details of a long file or module comment to the
  declarations they explain.
- Keep a doc comment in the form its language sets.
- Change the comments only, never the code. Keep each linter directive with its reason.

## Docs

- Delete what restates a command's help or the code; link to the help or the decision instead.
- A fact found in two places stays in the one it belongs to, and the other links there.
- Split long sentences at their semicolons, dashes and colons. Lists beat long sentences.
- Keep every link, and keep code spans, commands and names as they are.
- Keep headings that something links to. Where one must change, so does each link and comment
  that names it: a link check reads the anchors of Markdown alone.

## Vale

Each rule `.vale.ini` sets to `error` is one. Fix each alert by rewriting the sentence; never add
an exception, lower a level, or leave a file out of a gate or in a baseline. Where Vale reads no
comments, hold them to its rules by reading.

## Before you delete

For each sentence you remove, find where its fact lives: the code, a decision, the guide or the
help. Where it lives nowhere else, keep it, or move it to where it belongs.

## Check

- Run the checks the repository names, on the files changed. Wrap prose at the policy's width.
- Commit as `docs(scope): ...` for docs, or `refactor(scope): ...` for comments.
- Report the files changed, each fact moved and where to, and whatever still fails, with its
  reason.
