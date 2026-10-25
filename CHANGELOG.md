# Changelog

The marketplace's versions, newest first, each with what changed in each bundle.
[The README](README.md#versions) says what each part of a version means.

## 3.0.0

Each rule of a skill now holds in every repository. A repository's CLAUDE.md and `.claude/rules/`
name its own facts alone, such as its gates and the checks to wait for, which add to a skill's
steps. Move a repository's overrides out of its CLAUDE.md, `.claude/rules/` and CONTRIBUTING.md:

- a narrowed list of types or scopes, or a header, body or pull request's form of its own;
- an issue's title, sections or word range of its own;
- a cap of its own, a term it adds or allows, or a Vale exception.

The skills read a repository's facts from its CLAUDE.md and `.claude/rules/`, not from
CONTRIBUTING.md: move them there.

### flow

- `atomic-commits`: the header's form, the types and scopes, the body, and the pull request's title
  and description hold in every repository. Its CLAUDE.md names facts alone, such as its build and
  test commands.
- `issue`: the title's form, the sections and the word range hold in every repository. Its
  CLAUDE.md names the checks a text passes before it goes out.
- `land`: a repository's CLAUDE.md names the checks to wait for, its known flakes, the gates before
  `/ff` and who tags a release. They change none of the skill's steps.

## 2.1.0

### flow

- `atomic-commits`: a pull request's description is `## Problem` and `## Changes`, with
  `## Stack` in a stack, in 200 words at most. It replaces What, Why and Testing.
- `atomic-commits`: names the actions that warn in CI on a pull request's commits, size, title
  and description.
- `land`: the `/ff` workflow's action is now zadykian/actions's `ff`, moved there from
  `zadykian/ff`.

### docs

- `writing`: it points to `banned-terms` for vague names and fillers.

### lint

- `banned-terms`, a new skill: it keeps vague names and fillers out of new code and prose, as
  `zadykian/actions/banned-terms` checks a pull request for them.

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
