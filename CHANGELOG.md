# Changelog

The marketplace's versions, newest first, each with what changed in each bundle.
[The README](README.md) says what each part of a version means.

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
