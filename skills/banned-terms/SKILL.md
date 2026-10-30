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

The list below holds in every repository. A repository adds no term of its own, and allows none
of the list.

## The terms

The terms are in [terms.json](terms.json), beside this file: an array of groups, each of its
`terms` and a `hint` on what to write instead. Read the file before you name something or write
prose. [The action](#the-action) reads the same file.

## How a term matches

A term matches a whole word, in any case. A text splits into words at each character other than a
letter or a digit, and again at each hump of camelCase and PascalCase. So `HTTPHelper` gives
`http` and `helper`.

A path from the root names the system's files, not yours, so no term matches in it. It starts at
a `/` with no letter, digit, `.`, `_`, `-`, `~` or `/` before it.

- `StringHelper`, `str_utils.py` and `MiscStuff` match.
- `utilize`, `helpful` and `etcd` don't, as none of their words is a term.
- `/etc/hosts` and `/usr/share/misc` don't, as each is a path from the root. `./etc` and `~/misc`
  match.

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

The toolkit's [`banned-terms` action][action] warns on these terms in what a pull request adds. It
reads the lines, the paths of the files added or renamed, the title and body, and the commit
messages. It never blocks the merge.

[action]: https://github.com/zadykian/toolkit/tree/main/actions/banned-terms
