# issue

Warns on an issue that strays from the form that [section 3 of the issue skill][section] sets. Its
title is a Conventional Commits header, and its body holds the fields of [the issue form][form].
The action blocks nothing: it annotates its run, writes a job summary, keeps one comment on the
issue up to date, and its job passes, findings or not.

## The format

The title is a header, as [atomic-commits][header] sets a commit's: `type(scope)!: description`,
72 characters at most. The body holds the form's fields, in its order, each as GitHub renders it:
`### LABEL`, then its text.

```markdown
### Summary

SUMMARY. Line references are to main SHA.

### Today

- `path/file:12-30` does X.

### Proposal

- Do Y.
```

`### Pull requests`, `### Waits` and `### Open decisions` follow, where they apply. An empty
optional field is left out, or holds `_No response_`, as a person's form writes it.

## Rules

Each rule links to [section 3][section]. Its finding quotes the title or the heading at fault, and
its fix shows the form. A heading may be an ATX one, as `### Today`, or a setext one, a line
underlined with `===` or `---`. A heading in a fenced code block or an HTML comment is none.

| Key | Finding when |
| --- | --- |
| `title` | The title is not a Conventional Commits header, or is over 72 characters |
| `empty` | The body is empty, or blank |
| `sections` | A heading other than a field, or a field off level 3, out of order or repeated |
| `required` | Summary, Today or Proposal is missing, or holds no prose |
| `length` | The body is over 2000 characters, headings included |

A blank field holds no prose, nor one of HTML comments, code blocks or `_No response_` alone. A
length counts characters, whatever their bytes, and a line end as one: the count drops the `\r` of
the browser's `\r\n`, which GitHub keeps.

## Inputs

| Input | Default | What it sets |
| --- | --- | --- |
| `token` | `${{ github.token }}` | The token that reads the issue and comments on it |
| `comment` | `true` | `true` keeps one comment of the report on the issue |

## Usage

```yaml
on:
  issues:
    types: [opened, edited]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.issue.number }}
  cancel-in-progress: true

permissions: {}

jobs:
  issue:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions:
      issues: write
    steps:
      - uses: zadykian/toolkit/actions/issue@SHA # vX.Y.Z
```

It takes a workflow of its own, as the event of a pull request names no issue. The `edited` type
checks the issue again once its title or body changes. `issues: write` lets the action comment. It
reads the issue through GitHub's API alone, so the job checks out nothing.

[section]: ../../skills/issue/SKILL.md#3-write-it
[form]: ../../skills/issue/change.yml
[header]: ../../skills/atomic-commits/SKILL.md#3-commit-messages-conventional-commits-100
