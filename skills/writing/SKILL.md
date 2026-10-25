---
name: writing
description: >-
  The writing policy for code comments and docs: a comment gives a purpose or a reason, each fact
  lives in one place, and short sentences pass Vale's rules. Use when writing or editing comments,
  Markdown or other prose in a repository.
paths:
  - "**/*.md"
  - "**/*.go"
  - "**/*.py"
  - "**/*.sh"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.java"
  - "**/*.kt"
  - "**/*.cs"
  - "**/*.rs"
  - "**/*.c"
  - "**/*.h"
  - "**/*.cpp"
  - "**/*.rb"
  - "**/*.swift"
  - "**/*.php"
  - "**/*.yml"
  - "**/*.yaml"
  - "**/*.toml"
  - "**/Makefile"
  - "**/Dockerfile"
---

# Writing

How code comments and docs are written. Shorter, never poorer: each fact stays, in the one place
it belongs.

## The repository's rules

The policy below holds in every repository, with no cap, term or exception of a repository's
own. The repository's CLAUDE.md and `.claude/rules/` name facts alone:

- the gates to run on the files changed;
- which files Vale reads, such as the comments that the repository passes to it;
- the lists of names that its confidentiality checks keep out.

## Comments

- A comment gives a block's purpose in one or two sentences, or a reason the code cannot show,
  with the finding behind it: a probe, a source, an issue. It never narrates the code.
- A reason that a decision record holds becomes a pointer to it: "see decision N".
- A long comment's details move to the declarations they explain.
- A doc comment keeps the form its language sets.
- A linter directive keeps its reason beside it.

## Docs

- Each fact lives in one place: how the code works in its comments, a decision's reasons in its
  record, and what a user runs and sees in the docs. Other places link to it.
- A doc does not restate a command's help or the code. It says what they leave out, such as
  caveats, limits and steps taken by hand.
- Lists beat long sentences. Split a long one at its semicolons, dashes and colons.
- A heading that something links to keeps its name, or each link and comment that names it
  changes with it.
- In a public repository nothing secret goes in: no key, token or password, and no internal host,
  address or domain. Examples make values up, as documentation ranges and `example.test` do.

## The caps and Vale

- Sentences of 30 words or fewer, counted outside code spans (`Microsoft.SentenceLength`).
- Files of 300 lines or fewer, and prose wrapped at 100 columns, in Markdown and comments alike.
- No wordy phrase (`write-good.TooWordy`), such as `it is`, `however`, `multiple`, `in order to`,
  `additional`, `minimum` or `type of`.
- No needless variant (`proselint.Needless`), such as `administrate` for `administer`.
- No vague name or filler, as the `banned-terms` skill lists them.

Vale reads the Markdown, and the comments where the repository passes them to it, each rule an
error. A comment it does not read keeps to its rules all the same. Fix an alert by rewriting the
sentence, keeping its facts. Never add an exception, lower a level, leave a file out of a gate or
keep a baseline.
