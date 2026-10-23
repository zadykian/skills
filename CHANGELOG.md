# Changelog

The marketplace's versions, newest first, each with what changed in each bundle.
[The README](README.md#versions) says what each part of a version means.

## 2.0.0

No skill reads a repository's notes, `.claude/skill-notes/NAME.md`, any longer: each runs as the
marketplace ships it. Move what a repository's notes held into its CLAUDE.md, CONTRIBUTING.md or
`.claude/rules/`, which win where they differ from a skill, and delete `.claude/skill-notes/`.

### flow

- `atomic-commits`, `issue` and `land`: they read no notes. Where a repository sets the header's
  form, an issue's title, the checks to wait for or who tags a release, its CLAUDE.md says so.

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
