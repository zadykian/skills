# banned-terms

Warns on vague names and fillers, such as `helper`, `utils` and `simply`, in what a pull request
adds. The [banned-terms](../../skills/banned-terms/SKILL.md) skill teaches the agent to keep them
out, and each finding links to it. The action never blocks the merge: its job passes, whatever it
finds.

## Usage

`.github/workflows/rules.yml`:

```yaml
name: rules

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number }}
  cancel-in-progress: true

permissions: {}

jobs:
  rules:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: zadykian/toolkit/actions/banned-terms@SHA # vX.Y.Z
```

The `edited` type checks the title and the description again once they change, and
`pull-requests: write` lets the action keep its comment. [Versions](../../README.md#versions) says
which hash to pin.

## The terms

The list is [terms.json](../../skills/banned-terms/terms.json), beside the skill, and no input
changes it. The action reads the file at its pinned ref, as the runner downloads the whole
repository. Each group of the file, of its `terms` and a `hint`, is a rule of the report: its title
lists the terms, and its fix is the hint.

A term matches a token. A text splits into tokens at each character other than an ASCII letter or
digit, then before each hump of camelCase and PascalCase, and each token is lowercased. So
`HTTPHelper` gives `http` and `helper`, and `使用helper` gives `helper`.

A path from the root names the system's files, so no token of it matches. It starts at a `/` with
no ASCII letter or digit, `.`, `_`, `-`, `~` or `/` before it, and runs over the letters, digits,
`.`, `_`, `-` and `/` after it.

- `StringHelper`, `str_utils.py` and `MiscStuff` match.
- `utilize`, `helpful`, `etcd` and `utils2` don't, as none of their tokens is a term.
- `/etc/hosts`, `"/usr/share/misc"` and `PATH=/opt/misc` don't, as each is a path from the root.
  `./etc`, `~/misc` and `https://example.com/utils` match.

A line gives one finding a term, even where it holds the term twice.

## What it reads

It reads the pull request through GitHub's API alone, and checks out nothing:

1. The lines that it adds, from each file's patch: code, comments and docs alike. A finding shows
   inline in Files changed, at the line's number on the new side.
2. The paths of the files that it adds or renames.
3. Its title and its description, line by line.
4. The message of each of its commits. A finding names the commit by its sha7 and subject.

## Inputs

| Input     | Default               | Meaning                                                      |
| --------- | --------------------- | ------------------------------------------------------------ |
| `token`   | `${{ github.token }}` | The token that reads the pull request and keeps its comment  |
| `comment` | `true`                | `false` leaves the comment out, and keeps the annotations    |
| `exclude` | generated files       | The files to skip, a glob a line, as git's `:(glob)` matches |

The default `exclude`, in [action.yml](action.yml), holds the lockfiles, generated code and vendored
code that atomic-commits leaves out of its counts. A value of your own replaces it.

## Limits

- It reads only what the pull request adds. A line that it changes counts as added, so an old name
  on it, such as an import of `utils`, gives a finding. A removed line gives none.
- GitHub gives no patch of a binary file, nor of a large diff. The report notes each such file, and
  the check reads its path alone.
- GitHub lists 3000 files and 250 commits of a pull request at most.
