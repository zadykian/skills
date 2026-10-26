---
name: split-file
description: >-
  Split a source file over the line cap into files by responsibility, in its package or module
  and with its API unchanged. Use when a size check reports a file over its cap.
argument-hint: FILE
---

# Split a file

Split `$ARGUMENTS` into files within the line cap. The package or module, its
exported names, their signatures and their behaviour stay as they are: callers and tests change
nothing.

## The repository's rules

What each language needs comes from the repository, as facts: its CLAUDE.md and `.claude/rules/`,
the configs of its formatters and linters, and its build. They give the package or module clause a
file takes, the directives that go with a declaration, the linters' limits, and how to build and
test narrowly. They add to the steps that follow and change none of them. The cap is 300 lines, as
the `writing` skill sets it.

## Plan

1. Read the file.
2. Group its declarations by responsibility: what a reader looks for together, such as a record's
   lock, a command's flags or a parser's states. Each group becomes a file named for it, in the
   language's style for names; never `util` or `part2`.
3. A type stays with its methods. The package or module comment stays in one file; move a long
   one's details to the files they explain, or to a decision record.
4. For a test file, group by the behaviour the tests cover, and keep each fixture and assertion
   function beside the tests that call it. Code that the tests of several files share goes in one
   file, named for what it holds.

## Move

- Move the code unchanged, then improve it in place, so that the move's diff shows the move alone.
- Each new file takes what its language needs to stand alone: its package or module clause, its
  imports, and the directives or constraints that govern its declarations. Drop the imports a file
  no longer uses.
- The moved code must pass every linter the repository runs, at the limits its config sets, such
  as a line's length, a function's length or its complexity. Break a function over a limit into
  smaller functions, each named for what it does. The behaviour stays the same.
- Trim the comments as they move, as the `trim` skill does: purpose or reason only.
- Every file must pass every gate outright: no baseline, no exclusion.

## Check

1. The formatters and the build, as the repository runs them.
2. The linters and the size check on the old and the new files.
3. The tests of the package or module alone; CI runs the rest.
4. Commit as `refactor(scope): split FILE by responsibility`, listing the new files in the body.
