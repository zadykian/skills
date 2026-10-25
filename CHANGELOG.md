# Changelog

The marketplace's versions, newest first, each with what changed in each bundle.
[The README](README.md#versions) says what each part of a version means.

## 2.1.0

### flow

- `atomic-commits`: a pull request's description is `## Problem` and `## Changes`, with
  `## Stack` in a stack, in 200 words at most. It replaces What, Why and Testing.
- `atomic-commits`: names the actions that warn in CI on a pull request's commits, size, title
  and description.

## 2.0.0

No skill reads a repository's notes, `.claude/skill-notes/NAME.md`, any longer: each runs as the
marketplace ships it. Move what a repository's notes held into its CLAUDE.md, CONTRIBUTING.md or
`.claude/rules/`, which win where they differ from a skill, and delete `.claude/skill-notes/`.

### flow

- `atomic-commits`, `issue` and `land`: they read no notes. Where a repository sets the header's
  form, an issue's title, the checks to wait for or who tags a release, its CLAUDE.md says so.

### docs

- `writing` and `trim`: they read no notes. A repository's caps, terms to keep out and prose
  checks go in its `.claude/rules/writing.md`.

### lint

- `split-file`: it reads no notes. A language's rules, the cap and the checks come from the
  repository's CLAUDE.md and `.claude/rules/`, and from its tools' configs.

## 1.0.0

### flow

- `atomic-commits`: the skill as first written on claude.ai, its Markdown wrapped at 100 columns,
  two phrases reworded for Vale, and a long command moved to a code block. Added: the
  repository's rules and notes win over sections 3 and 6, and a fast-forward needs the retarget
  alone.
- `issue` and `land`: the skills that cld, ikeward and ws each kept, as one. What each
  repository's copy added goes in its notes. The maintainer pushes a release's tag unless the
  notes for `land` say the skill does.

### docs

- `writing`: the writing policy that cld, ikeward and ws each kept in their rules, as one. Each
  repository keeps what is its own, such as a list of terms.
- `trim`: cld's skill, for any language. The language's rules go in the notes.

### lint

- The hooks that cld, ikeward and ws each kept, as one: `make lint-file` on each file Claude
  edits, and `make lint-tree` as it stops. They run where the maintainer's signed commits vouch
  for the gates' code.
- `split-file`: cld's skill, for any language. The language's rules go in the notes.
