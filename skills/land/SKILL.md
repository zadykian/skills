---
name: land
description: >-
  Land a stack of approved pull requests on main, bottom first, by fast-forward through a /ff
  comment, and tag a release if asked.
disable-model-invocation: true
argument-hint: "PR... [vX.Y.Z]"
---

# Land a stack

Land the pull requests `$ARGUMENTS` on main, the bottom of the stack first. main takes
fast-forwards only, so the commits CI checked are the commits that land. A comment `/ff` lands a
pull request, through the workflow that the toolkit's
[`ff` action](https://github.com/zadykian/toolkit/tree/main/actions/ff) sets up. Never run
`gh pr merge`, and never push to main.

## The repository's rules

The repository's CLAUDE.md and `.claude/rules/` name its facts: the checks to wait for, its known
flakes, the gates to run before `/ff`, and who tags a release. They add to the steps below and
change none of them.

## Each pull request, in order

Run each command from a clone of the repository, whose remote names it to `gh`.

1. **Base.** `gh pr view N --json baseRefName,headRefName,headRefOid,state`. `/ff` lands only a
   pull request into main. Where the base is the branch that just landed, retarget the pull
   request at main:

   ```sh
   gh api -X PATCH 'repos/{owner}/{repo}/pulls/N' -f base=main
   ```

   `gh pr edit --base` fails on the Projects (classic) deprecation, so use the API.
2. **On main.** `git fetch origin main "pull/N/head"`, which fetches a fork's head too, then
   `git merge-base --is-ancestor origin/main HEAD_SHA`. Where main is not an ancestor of the
   head, stop: the stack needs a rebase (below).
3. **Checks.** `gh pr checks N --watch`, until none is pending. Every check must have passed. Each
   job that the head's workflows run on a pull request must be among them: read them with
   `git show HEAD_SHA:.github/workflows/FILE`. Stop on a check that failed or is missing, and
   report it. Rerun a failed job only where the repository names it a known flake.
4. **Conversations.** Every review conversation resolved; the ruleset refuses the push otherwise.
5. **Land.** `gh pr diff N --name-only` lists the files it changes.
   - A pull request that changes `.github/workflows`: the workflow's token may not push it. Give
     the maintainer `git push origin HEAD_SHA:main` to run, and wait for them. Its branch stays
     on GitHub. Once the next pull request is retargeted at main (step 1), give the maintainer
     `git push origin --delete BRANCH` too.
   - Any other: `gh pr comment N --body /ff`, the comment alone.
6. **Wait** until `gh pr view N --json state -q .state` says `MERGED`. Where the workflow
   comments that it did not move main, report its reason and stop.

Then go on with the next pull request.

## A rebased stack

Rebase only when the maintainer asks. Then push each branch with its old head as the lease:

```sh
git push origin --force-with-lease=BRANCH:OLD_SHA BRANCH
```

The checks run again. Wait for them, `gh pr checks N --watch`, before `/ff`.

## Release

Only when the maintainer gives a version, once the stack has landed, and where the repository has
a release workflow.

1. `git fetch origin --tags`, and check the version against the last tag,
   `git describe --tags --abbrev=0 origin/main`. A commit since then whose header has a `!` bumps
   the major, or the minor before 1.0. Otherwise a `feat` bumps the minor, and the rest the patch.
2. The maintainer pushes the tag, unless the repository's CLAUDE.md says you do. Give them the
   commands, with main's head:

   ```sh
   git tag -a vX.Y.Z -m vX.Y.Z COMMIT
   git push origin vX.Y.Z
   ```

3. Report the release workflow's run once its `headSha` is the tagged commit,
   `gh run list --workflow WORKFLOW --limit 1 --json headSha,status,url`. Then report the release
   once published: `gh release view vX.Y.Z`.
