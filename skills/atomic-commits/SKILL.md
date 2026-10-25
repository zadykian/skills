---
name: "atomic-commits"
description: "Use when implementing code changes in a git repo - deliver small, self-contained Conventional Commits, and split any change over 300 diff lines into a stack of independently mergeable PRs."
---

# Atomic commits and stacked PRs

## Hard rules

1. Every commit is one logical change, builds, and passes tests on its own.
2. Target ≤ 100 changed lines per commit (typically 10–60). Only purely mechanical commits (rename,
   move, formatting, regenerated code) may exceed this, and their body says so.
3. Every commit message follows Conventional Commits 1.0.0 (section 3). A change that fits two types
   is two commits.
4. No PR exceeds 300 changed lines against its own base. Larger work becomes a stack of PRs, each of
   which leaves `main` green and releasable even if the rest never lands.
5. Plan the split before writing code, then commit as you go. Never write everything first and split
   afterwards: after-the-fact splits produce commits that don't build.

**Counting lines:** insertions + deletions (`git diff --numstat`), tests and docs included. Excluded
only: lockfiles, generated code, test snapshots/golden files, vendored dependencies (see the
pathspecs under "Verify"). Never meet the limit by moving tests into a later PR, excluding
hand-written files, or compressing formatting.

If one change genuinely cannot go below 300 lines, isolate it in a PR that contains nothing else and
ask the user before opening it.

Under 20 changed lines in total, one commit is fine; skip the plan.

## 1. Plan

Before the first edit, write the plan with size estimates:

```text
PR 1/3  refactor(payments): extract PaymentGateway interface        ~120
  c1  refactor(payments): extract PaymentGateway interface
  c2  refactor(payments): route StripeClient through the interface
PR 2/3  feat(payments): add retry policy                            ~210
  c3  feat(payments): add RetryPolicy with exponential backoff
  c4  feat(payments): make retry limits configurable
PR 3/3  feat(checkout): retry failed gateway calls                  ~90
  c5  feat(checkout): wrap gateway calls in RetryPolicy
```

- Order by dependency: whatever later commits need comes first.
- Estimates run low. If a PR is estimated above ~250, split it now.
- If the user is present and the plan has more than one PR, show it and wait for a go-ahead.
  Otherwise follow it and include it in the final report.

## 2. Shape each commit

Separate commits for:

- Refactoring (no behavior change) and behavior change. Refactor first.
- Mechanical changes (rename, move, format, dependency bump, codegen) and hand-written logic.
- Moving code and editing it: move it unchanged in one commit, edit it in the next, so the diff
  shows only real changes.
- Unrelated fixes noticed along the way: their own commit, or note them and leave them.

Keep together:

- Code and the tests that prove it.
- A change and the edits needed to keep everything compiling (call sites, mocks, fixtures).

Never commit debug output, commented-out code, WIP, or a "fix previous commit" commit. Fold fixes
into the commit they belong to.

## 3. Commit messages: Conventional Commits 1.0.0

Spec: <https://www.conventionalcommits.org/en/v1.0.0/>

```text
<type>[(scope)][!]: <description>

[body]

[footer(s)]
```

**Header** (required, ≤ 72 characters in total):

- `type`, lowercase. Use `feat` for a new feature (SemVer MINOR) and `fix` for a bug fix (SemVer
  PATCH) whenever they apply. Otherwise: `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`,
  `chore`, `revert`.
- `(scope)`, optional: a lowercase noun naming the part of the codebase, e.g. `feat(payments):`.
- `!`, optional, directly before the colon: marks a breaking change. Allowed on any type.
- A colon and one space, then the description: an imperative summary of the change, starting
  lowercase, no trailing period.

**Body** (optional): one blank line after the header; free-form paragraphs explaining why the change
was made. Wrap at 72.

**Footers** (optional): one blank line after the body (or the header, if there is no body). Each
footer is `Token: value` or `Token #value`, and tokens use `-` instead of spaces: `Refs: #412`,
`Reviewed-by: Name`, `Co-authored-by: Name <email>`.

**Breaking changes** (SemVer MAJOR): put `!` in the header and add a footer
`BREAKING CHANGE: <what changed and what callers must do>`. The token must be uppercase;
`BREAKING-CHANGE` means the same. The spec accepts either marker alone; use both so the migration
note is never lost.

**Reverts:** `revert: <header of the reverted commit>` with a footer `Refs: <sha>`.

Examples:

```text
feat(payments): add RetryPolicy with exponential backoff

Gateway calls fail transiently under load. Retrying with backoff
keeps these failures from reaching checkout.

Refs: #412
```

```text
refactor(payments)!: remove legacy ChargeClient

BREAKING CHANGE: ChargeClient is removed; call PaymentGateway.Charge
instead.
```

```text
fix(checkout): stop double-charging on retried requests
```

`fixup!` commits don't conform; they are temporary and must be autosquashed before pushing or
reporting.

## 4. Work loop

For each planned commit:

1. Make the smallest edit that completes it.
2. Run the build and the relevant tests.
3. Stage only its files with `git add <paths>`, then check `git diff --cached --stat`.
4. Commit with a Conventional Commits message.

The shell is non-interactive. Never run `git add -p`, `git add -i`, or a bare `git rebase -i`.
Instead:

- Two commits that touch the same file: write the file's intermediate state, commit, then write its
  final state.
- Fixing an earlier commit: `git commit --fixup=<sha>`, then
  `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash --update-refs <base>`.
- Rewording the last commit: `git commit --amend -m "<header>" -m "<body>"`.
- Rewording an earlier commit: write the full message to `/tmp/msg.txt`, then run the command
  below. One commit per run.

  ```sh
  GIT_SEQUENCE_EDITOR="perl -pi -e 's/^pick <sha7>/reword <sha7>/'" GIT_EDITOR="cp /tmp/msg.txt" git rebase -i --update-refs <base>
  ```

## 5. Choose PR boundaries

Each PR has one purpose stated in its title, is reviewable without reading the others, and leaves
`main` building, passing, and deployable.

Ways to cut, in order of preference:

1. **Preparatory refactors**: behavior-neutral restructuring that makes the feature easy to add.
2. **Vertical slices**: one endpoint, command, or use case per PR, end to end, with tests.
3. **Layers, bottom-up**: types/schema → persistence → domain logic → API/wiring. A lower layer may
   merge before anything calls it, as long as tests cover it.
4. **Expand–contract** for breaking changes to APIs, schemas, and config: add the new path beside
   the old one, migrate callers, remove the old path last. If the old path is public API, that final
   removal is the breaking commit (`!` plus `BREAKING CHANGE:` footer).
5. **Feature flag**, default off, when an incomplete feature would otherwise be user-visible.
   Turning it on is the last PR.

Never leave `main` with a compile error that the next PR fixes, untested dead code, or a schema
change that breaks running code.

## 6. Stack mechanics (git ≥ 2.38)

One branch per PR, each branched from the previous one:

```text
main ← feat/retry-1-gateway ← feat/retry-2-policy ← feat/retry-3-checkout
```

- Start the next PR's branch once the previous one's commits are done:
  `git switch -c feat/retry-2-policy`.
- Always edit from the top branch. To change a commit in a lower PR, make a `--fixup` commit on the
  top branch and run `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash --update-refs main`; this
  rewrites the stack and moves every branch ref.
- Push and open PRs only when the user asked for it. Push each branch with
  `git push --force-with-lease origin <branch>`. Open each PR against the branch below it:
  `gh pr create --base feat/retry-1-gateway --head feat/retry-2-policy`.
- After the bottom PR merges (squash or merge commit), from the top branch:
  `git rebase --update-refs --onto main feat/retry-1-gateway`, force-push the moved branches, and
  retarget the next PR with `gh pr edit <number> --base main` if the host didn't already. A
  fast-forward lands the very commits, so it needs the retarget alone.

PR titles use the Conventional Commits header format too, because a squash merge turns the title
into the commit on `main`. A PR containing a breaking commit has `!` in its title and the
`BREAKING CHANGE:` footer at the end of its description.

PR description:

```markdown
## Problem

What is wrong or missing today, and why it matters: one to three sentences. Closes #12.

## Changes

- One bullet per high-level change, said by behavior, not by file.

## Stack

PR 2 of 3. Base: #41. Next: feat(checkout): retry failed gateway calls.

BREAKING CHANGE: what changed, and what callers must do.
```

- `## Problem` comes first: one to three sentences, and the issue it closes, if any.
- `## Changes` holds bullets by behavior, not by file.
- `## Stack` is in each PR of a stack, and required when the base isn't `main`. It says
  `PR N of M`, then the base and the next PR.
- No other sections or headings, at any level. 200 words at most, not counting code blocks and
  HTML comments.

## 7. Verify

From the top branch, before reporting:

```sh
excl=(
  ':(exclude,glob)**/go.sum'
  ':(exclude,glob)**/*.pb.go'
  ':(exclude,glob)**/*_gen.go'
  ':(exclude,glob)**/*.g.cs'
  ':(exclude,glob)**/*.Designer.cs'
  ':(exclude,glob)**/*ModelSnapshot.cs'
  ':(exclude,glob)**/package-lock.json'
  ':(exclude,glob)**/packages.lock.json'
  ':(exclude,glob)**/vendor/**'
)

# Size of every commit in the stack
for c in $(git rev-list --reverse main..HEAD); do
  n=$(git show --numstat --format= "$c" -- . "${excl[@]}" | awk '{s+=$1+$2} END{print s+0}')
  echo "$n  $(git log -1 --format='%h %s' "$c")"
done

# Size of each PR against its own base
size() { git diff --numstat "$1"..."$2" -- . "${excl[@]}" | awk '{s+=$1+$2} END{print s+0}'; }
size main feat/retry-1-gateway
size feat/retry-1-gateway feat/retry-2-policy

# Headers: Conventional Commits and ≤ 72 chars. Both print nothing when clean.
types='feat|fix|refactor|perf|test|docs|style|build|ci|chore|revert'
git log --format=%s main..HEAD | grep -vE "^($types)(\([a-z0-9._/-]+\))?!?: [^ ]"
git log --format=%s main..HEAD | awk 'length > 72'

# Every commit builds and passes tests
git rebase --exec '<build && test>' main
```

Build-and-test examples: `go build ./... && go test ./...`,
`dotnet build && dotnet test --no-build`. If the full suite is slow, run build plus affected tests
per commit and the full suite on each PR's tip.

If `--exec` stops on a commit, fix that commit (`git commit --amend`), then `git rebase --continue`.
If any size is over its limit or any header doesn't conform, fix it before reporting.

In CI, two actions check a PR against these rules. Both only warn, and never block the merge:

- [`zadykian/actions/atomic-commits`][ac-action]: its commits, its size and its title.
- [`zadykian/actions/pr-description`][pd-action]: its description, as section 6 sets it.

[ac-action]: https://github.com/zadykian/actions/tree/main/atomic-commits
[pd-action]: https://github.com/zadykian/actions/tree/main/pr-description

## 8. Report

Finish with each PR's branch, title, counted size, and commits (hash and subject), plus any rule you
couldn't follow and why.

**Repository rules.** Every rule here holds in every repository. Its CLAUDE.md names only facts,
such as the build and test commands that section 7 runs and the paths of its generated code.

These rules apply unless the user explicitly asks for a single commit or a single PR.
