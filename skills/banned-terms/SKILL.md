---
name: banned-terms
description: >-
  Keep vague names and fillers, such as helper, utils, misc and simply, out of new code and prose.
  Use when naming a file, type, function or variable, and when writing a comment, a doc, a commit
  message, or a pull request's title and body.
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

# Banned terms

A name says what its code does, and a sentence says something. The terms below do neither. Keep
them out of the names of files, types, functions and variables, and out of comments, docs, commit
messages and pull requests.

## The repository's rules

The repository's CLAUDE.md and `.claude/rules/` add to the list below and win where they differ.
They may add terms of their own, each with a hint, and allow terms that the repository needs.

## The terms

| Terms                           | Hint                                                              |
| ------------------------------- | ----------------------------------------------------------------- |
| helper, helpers                 | Names no responsibility: name what it does                        |
| util, utils, utility, utilities | Names no responsibility: name what it does                        |
| misc, miscellaneous             | A grab bag: group by purpose                                      |
| stuff, thing, things            | Names nothing: name it                                            |
| etc                             | An open list: name each item, or lead the examples with "such as" |
| various                         | Say which ones, or how many                                       |
| simply, basically, obviously    | Filler: delete it                                                 |

## How a term matches

A term matches a whole word, in any case. A text splits into words at each character other than a
letter or a digit, and again at each hump of camelCase and PascalCase. So `HTTPHelper` gives
`http` and `helper`.

- `StringHelper`, `str_utils.py` and `MiscStuff` match.
- `utilize`, `helpful` and `etcd` don't, as none of their words is a term.

## What to write instead

Name the code by what it does, and split a grab-bag module by purpose:

| Instead of                         | Write                                   |
| ---------------------------------- | --------------------------------------- |
| `StringHelper`                     | `Slugifier`, or `escapeHtml`            |
| `utils.py`, of dates and paths     | `dates.py` and `paths.py`               |
| `processStuff(items)`              | `chargeOrders(orders)`                  |
| "Add tests, docs, etc."            | "Add tests and docs."                   |
| "Simply run `make lint`."          | "Run `make lint`."                      |

## Scope

New text alone: the names, lines and messages you write. Leave an existing name unchanged unless
the user asks for a rename, which then takes a commit of its own. The action reads only what a
pull request adds. So a line you change may keep an old name, as an import of `utils` does,
though the action warns on it.

## The action

[zadykian/actions/banned-terms](https://github.com/zadykian/actions/tree/main/banned-terms) warns
on these terms in what a pull request adds. It reads the lines, the paths of the files added or
renamed, the title and body, and the commit messages. It never blocks the merge.
