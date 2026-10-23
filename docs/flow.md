# flow

The way a change goes from an idea to `main`: plan it as an issue, commit it in small steps, and
land the stack of pull requests by fast-forward. The bundle is `flow@zadykian`, as
[the README](../README.md#install) shows.

## atomic-commits

Has Claude deliver a change as small, self-contained [Conventional Commits][cc], each of which
builds and passes the tests. A change over 300 lines becomes a stack of pull requests, each of
which leaves `main` green. Claude uses it as it commits in a git repository, or as
`/flow:atomic-commits`.

The repository's CLAUDE.md, CONTRIBUTING.md and commit checks win where they set the header's
form or the types and scopes. So they do for the body and the pull request's description. The
rest holds in every repository: one logical change per commit, the size limits, the plan and the
stack.

## issue

Plans a change, then files it as a GitHub issue in a compact house style once the maintainer
approves the plan: a summary, `## Today` with `file:line` references at `main`'s SHA, and
`## Proposal`. Claude uses it when asked to file an issue or plan one, or as
`/flow:issue [topic]`. It needs `gh`, logged in.

The repository's CLAUDE.md and CONTRIBUTING.md win where they say of issues:

- the title's form, where the repository's differs from a Conventional Commits header;
- sections of the repository's own, and a word range other than 150 to 350;
- the checks a title and a body pass before they go out, such as Vale or a list of terms.

## land

Lands a stack of approved pull requests on `main`, the bottom first, by fast-forward through a
`/ff` comment, and tags a release if asked. It runs by hand only:

```text
/flow:land 41 42 [vX.Y.Z]
```

It needs `gh`, logged in, and a `/ff` workflow, as [zadykian/ff](https://github.com/zadykian/ff)
sets up. The repository's CLAUDE.md and CONTRIBUTING.md win where they say how changes land:

- the checks to wait for, and a known flake that gets one rerun;
- a gate before `/ff`, such as a check of the pull request's text;
- the release: its workflow, the tag's form, and whether the skill pushes the tag.

[cc]: https://www.conventionalcommits.org/en/v1.0.0/
