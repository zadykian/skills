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

First read the repository's notes for this skill, `.claude/skill-notes/issue.md` at its root,
where they exist. They give the title's form, the checks a text passes before it goes out, and
sections or lengths of their own. They add to the steps below, and win where they differ, as does
what CLAUDE.md and CONTRIBUTING.md say of issues and commits.

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

- **Title:** a Conventional Commits header, as the repository's commits have them, unless the
  notes give another form.
- **Summary:** two to four sentences: what is missing or wrong today, and what the issue adds. It
  ends "Line references are to main SHA." Name the versions of any other source cited.
- **`## Today`:** bullets with `file:line` references, the crucial facts only. Group them under a
  short label where they cover several subjects.
- **`## Proposal`:** bullets saying what changes. A decision leads with its name in bold, and a
  rejected option says why: "**Not X:** ...".
- **`## Pull requests`:** only where the change takes several, a checkbox per pull request with
  its title, in landing order.
- **`## Waits`:** only where something outside the issue must happen first.
- **`## Open decisions`:** only when something is undecided, each with options and a
  recommendation.
- 150 to 350 words in all. A design that rests on probes runs longer.

```markdown
SUMMARY. Line references are to main SHA.

## Today

- `path/file:12-30` does X.

## Proposal

- Do Y.
```

## 4. File it

Write the body to `BODY.md` in the session's scratchpad, or another directory outside the
repository, and name it by one absolute path in each command. Run the checks the notes name on the
title and the body. In a public repository nothing secret goes in: no key, token or password, and
no internal host, address or domain.

```sh
gh issue create --title 'TITLE' --body-file /ABSOLUTE/PATH/BODY.md [--label LABEL]
```

Labels: `feat` gets `enhancement`, `fix` gets `bug` and `docs` gets `documentation`. The other
types get none. Reply with the issue's URL.
