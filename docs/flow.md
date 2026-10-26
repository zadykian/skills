# flow

The way a change goes from an idea to `main`: plan it as an issue, commit it in small steps, and
land the stack of pull requests by fast-forward. The bundle is `flow@zadykian`, as
[the README](../README.md#install) shows.

## atomic-commits

Has Claude deliver a change as small, self-contained [Conventional Commits][cc], each of which
builds and passes the tests. A change over 300 lines becomes a stack of pull requests, each of
which leaves `main` green. Claude uses it as it commits in a git repository, or as
`/flow:atomic-commits`.

A pull request's description opens with `## Problem`, one to three sentences, then `## Changes`,
bullets by behavior. `## Stack` follows in a stack, and a `BREAKING CHANGE:` footer ends it where
the title has `!`. It runs to 200 words at most.

In CI, the toolkit's [`atomic-commits` action][ac-action] warns on a pull request whose commits,
size or title break the skill's rules, and the [`pr-description` action][pd-action] on its
description. Both only warn: neither blocks the merge.

Every rule of the skill holds in every repository: the header, its types and scopes, and the
body. So do the pull request's title and description, the size limits, the plan and the stack. The
repository's CLAUDE.md names only facts, such as its build and test commands and the paths of its
generated code.

## issue

Plans a change, then files it as a GitHub issue in a compact house style once the maintainer
approves the plan: a summary, `## Today` with `file:line` references at `main`'s SHA, and
`## Proposal`. Claude uses it when asked to file an issue or plan one, or as
`/flow:issue [topic]`. It needs `gh`, logged in.

The title's form, the sections and the word range hold in every repository. The repository's
CLAUDE.md names the checks that a title and a body pass before they go out, such as Vale or a
confidentiality check.

## land

Lands a stack of approved pull requests on `main`, the bottom first, by fast-forward through a
`/ff` comment, and tags a release if asked. It runs by hand only:

```text
/flow:land 41 42 [vX.Y.Z]
```

It needs `gh`, logged in, and a `/ff` workflow, as the toolkit's [`ff` action][ff-action] sets
up. The repository's CLAUDE.md names the facts of how its changes land, which add to the
skill's steps and change none of them:

- the checks to wait for, and a known flake that gets one rerun;
- a gate before `/ff`, such as a check of the pull request's text;
- the release: its workflow, and whether the skill pushes the tag.

[cc]: https://www.conventionalcommits.org/en/v1.0.0/
[ac-action]: ../actions/atomic-commits
[pd-action]: ../actions/pr-description
[ff-action]: ../actions/ff
