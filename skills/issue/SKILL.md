---
name: issue
description: >-
  Plan a change, then file it as a GitHub issue in a compact house style once the maintainer
  approves the plan. Use when asked to file, open or write up an issue, or to plan a change as
  one.
argument-hint: "[topic]"
---

# File an issue

Plan, approval, then the issue. Never branch or write code unless the maintainer asks for it.

## The repository's rules

The steps below hold in every repository. A repository's CLAUDE.md and `.claude/rules/` add
facts to them, such as the checks a text passes before it goes out. They set no title's form,
sections or lengths of their own.

## 1. Plan

Reply with a plan and ask for approval:

- the goal, in a sentence or two;
- the changes, with `file:line` references;
- what to check: the repository's gates, CI's jobs and the tests;
- open decisions, each with a recommendation;
- the pull requests and their order, where the change takes several, and what each waits for.

"Approved, create the issue" means `gh issue create`, not code.

## 2. Read the latest main

```sh
git fetch origin
git rev-parse --short origin/main      # the SHA the issue cites
git show origin/main:PATH              # read files at that SHA
```

The local checkout may lag main by several commits: cite only lines read at `origin/main`. Cite a
pull request in flight by its number, as an issue that builds on its head does.

## 3. Write it

The title is a Conventional Commits header, as `atomic-commits` sets a commit's.

The body's fields are in [change.yml](change.yml), beside this file: the issue form that a
repository copies to `.github/ISSUE_TEMPLATE/`. Read the file before you write the body.

- The body holds the form's fields, in its order, each as GitHub renders it: `### LABEL`, then
  its text.
- Each field's rule is its `description`.
- A field is optional unless its `validations` say `required: true`. An empty optional field is
  left out. A person's form writes `_No response_` there instead.
- The whole body is 2000 characters at most, headings included, each line end counted as one.

```markdown
### Summary

SUMMARY. Line references are to main SHA.

### Today

- `path/file:12-30` does X.

### Proposal

- Do Y.
```

## 4. File it

Write the body to `BODY.md` in the session's scratchpad, or another directory outside the
repository, and name it by one absolute path in each command. Run the checks the repository
names for a text on the title and the body. In a public repository nothing secret goes in:
no key, token or password, and no internal host, address or domain.

```sh
gh issue create --title 'TITLE' --body-file /ABSOLUTE/PATH/BODY.md [--label LABEL]
```

Labels: `feat` gets `enhancement`, `fix` gets `bug` and `docs` gets `documentation`. The other
types get none. Reply with the issue's URL.
