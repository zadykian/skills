---
name: land
description: >-
  Land a stack of approved pull requests on main, bottom first, by GitHub's merge commits, and tag
  a release if asked.
disable-model-invocation: true
argument-hint: "PR... [vX.Y.Z]"
---

# Land a stack

Land the pull requests `$ARGUMENTS` on main, the bottom of the stack first, by GitHub's merge
commits. Each pull request's commits land as they are, under a merge commit that GitHub signs, so
the commits CI checked are the commits that land. Never push to main, never squash or rebase-merge,
and never bypass the rules: no `--admin`.

## The repository's rules

The repository's CLAUDE.md and `.claude/rules/` name its facts: the checks to wait for, its known
flakes, the gates to run before the merge, and who tags a release. They add to the steps below and
change none of them.

## Each pull request, in order

Run each command from a clone of the repository, whose remote names it to `gh`. `gh stack` comes
from the gh-stack extension: `gh extension install github/gh-stack`.

1. **Base.** `gh pr view N --json baseRefName,headRefName,headRefOid,state`. The bottom's base is
   main, and each other's base is the head branch of the one below. Where not, stop and report
   it: `gh stack merge` lands each unmerged pull request below its top, given or not.
2. **On its base.** `git fetch origin main "pull/N/head"`, which fetches a fork's head too. The
   bottom's head contains main, `git merge-base --is-ancestor origin/main HEAD_SHA`, and each
   other's head contains the one below, `git merge-base --is-ancestor BELOW_SHA HEAD_SHA`. Where
   not, stop: the stack needs a rebase (below).
3. **Checks.** `gh pr checks N --watch`, until none is pending. Every check must have passed. Each
   job that the head's workflows run on a pull request must be among them: read them with
   `git show HEAD_SHA:.github/workflows/FILE`. Stop on a check that failed or is missing, and
   report it. Rerun a failed job only where the repository names it a known flake.
4. **Conversations.** Every review conversation resolved; the ruleset refuses the merge otherwise.

Then go on with the next pull request.

## The merge

Once each has passed, land them all at once:

- Two or more: link them as one stack on GitHub, bottom first, as `gh stack link 41 42 43`. It
  only adds to a stack, and never removes a pull request from one, so it changes nothing where
  they are one already. Then `gh stack merge TOP --merge --yes`, TOP being the last pull request
  given. It lands TOP and each unmerged pull request below it, all or nothing, under one merge
  commit for them all.
- One: `gh api 'repos/{owner}/{repo}/pulls/N' --jq .stack.number` prints its stack, or nothing.
  In a stack, even as its last layer, it lands by `gh stack merge N --merge --yes`, as GitHub
  refuses `gh pr merge` there. In none, by `gh pr merge N --merge`, as `gh stack merge` refuses
  it.

Always pass `--merge`: without it, `gh stack merge --yes` takes the method used last. GitHub
judges each pull request's required reviews, checks and code owners against the stack's base. On
a refusal, report what gh printed, and stop.

Wait until `gh pr view N --json state -q .state` says `MERGED` for each. GitHub closes the issues
each one links, and deletes its branch where the repository's settings say so: leave both to it.
Where the stack holds pull requests above TOP, GitHub retargets the next one at main. It rebases
their branches itself and signs the commits it writes, so their commits change, and their checks
run again.

## A rebased stack

Rebase only when the maintainer asks. A stack's branches are linear: each on the one below, and
the bottom on main. Rebase from the top branch, never merging main in, with
`git rebase --update-refs origin/main`, and sign each commit it writes, as the ruleset requires.
Then push each branch with its old head as the lease:

```sh
git push origin --force-with-lease=BRANCH:OLD_SHA BRANCH
```

The checks run again. Wait for them, `gh pr checks N --watch`, before the merge.

## Release

Only when the maintainer gives a version, once the stack has landed, and where the repository has
a release workflow.

1. `git fetch origin --tags`, and check the version against the last tag, TAG, from
   `git describe --tags --abbrev=0 origin/main`. Read the commits since then with
   `git log --no-merges TAG..origin/main`: GitHub's merge commits carry no Conventional Commits
   header. A commit whose header has a `!` bumps the major, or the minor before 1.0. Otherwise a
   `feat` bumps the minor, and the rest the patch.
2. The maintainer pushes the tag, unless the repository's CLAUDE.md says you do. Give them the
   commands, with main's head:

   ```sh
   git tag -a vX.Y.Z -m vX.Y.Z COMMIT
   git push origin vX.Y.Z
   ```

3. Report the release workflow's run once its `headSha` is the tagged commit,
   `gh run list --workflow WORKFLOW --limit 1 --json headSha,status,url`. Then report the release
   once published: `gh release view vX.Y.Z`.
