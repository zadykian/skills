# toolkit

Claude Code skills and hooks, and GitHub Actions that check each pull request against the same
rules, at one version. The skills and hooks are a plugin marketplace, `zadykian`, of three
bundles, `flow`, `docs` and `lint`. [README.md](README.md) says what each skill and action does,
how to install and pin them, and what a version's parts mean.

## Layout

- `.claude-plugin/marketplace.json`: the catalog. Each bundle takes its skills from the root,
  `"source": "./"` with `"strict": false`, lists them, and gives the version. `lint`'s hooks are
  inline in its entry.
- `skills/NAME/SKILL.md`: a skill, which a bundle offers as `/BUNDLE:NAME`, and
  `gh skill install` copies as `/NAME`. Its directory holds `SKILL.md`, and the data files it
  reads, such as banned-terms' `terms.json`, as gh copies the whole directory into a repository.
- `hooks/`: the lint bundle's hooks, which Claude Code runs from its copy of the marketplace.
- `docs/BUNDLE.md`: what each skill of a bundle does, and what facts a repository names for it.
- `actions/NAME/`: an action, which a workflow uses as `zadykian/toolkit/actions/NAME@SHA`: its
  `action.yml`, its scripts, and a README of what it does and its inputs. A check's script is
  `check.sh`, and `ff`'s are the steps of its job.
- `actions/lib/`: what each `check.sh` sources. `report.sh` turns its findings into annotations,
  a job summary and one comment, and its header comment is its API. `glob.sh` gives
  `excluded PATH`, the one reading of the `exclude` inputs.
- `tests/run`: runs the cases of each `tests/NAME.sh`, against `tests/gh`, the fake gh: of an
  action, of `actions/lib/`, of a tool, or, in `rules.sh`, of the checks against their skills. Its
  header comment says how to write a case.
- `tools/`, the gates: `run` downloads the lint tools at the versions and SHA-256 sums it pins,
  into `.cache/tools`. `files` lists the files of a kind that a gate checks, `sizecheck` caps
  their lines, and `hookcheck` runs the hooks against throwaway repositories.
- `tools/`, the release: `lastrelease` finds the last release's tag, `versioncheck` checks the
  bundles and the version against it, and `releasenotes` writes the notes of the commits since.
  `pin` moves a repository's marketplace ref and action hashes to one release.

## Commands

```sh
make lint                          # every gate, as CI's lint job runs them
make vale FILES='PATHS'            # one gate, on some files
make versions                      # the bundles, and the version against the last release
make hooks                         # the hooks, against throwaway repositories
make test                          # every case, as CI's test job runs them
tests/run NAME...                  # the cases of tests/NAME.sh alone
claude --plugin-dir .              # a session with the work tree's skills
```

`make lint` needs `jq` and `claude` on the `PATH`, and curl the first time. It runs zizmor's
online audits where `GH_TOKEN` is set. `make test` needs `git` and `jq`. `make plugins` runs
`claude plugin validate` on the marketplace and on the skills, its warnings counted as errors.

## A change to a skill, a hook or an action

- A change to a rule that a check holds edits the skill and the check in the same pull request,
  so that the two never ship apart. `tests/rules.sh` fails where a check's value differs from its
  skill's.
- A skill is generic, and reads no notes of a repository's. It names no repository's paths, jobs,
  terms, people or languages: those go in the repository's CLAUDE.md or `.claude/rules/`. A skill
  names another by its bare name, as both install paths name them differently.
- A change need not raise the version: the last pull request of a stack raises it, as
  [Versions](README.md#versions) says, in the catalog's `metadata.version` and in each bundle.
  `make versions` fails where the version is below the last release's, or a raise that the
  commits since then do not call for. A change that breaks a repository's CLAUDE.md or targets
  says what to change there, in its commit's `BREAKING CHANGE:` footer, which the release's notes
  give.
- A new skill: its directory, its bundle's `skills` list, its row in the README's table, and its
  section in its bundle's page.
- A new action: its directory, its `tests/NAME.sh`, and its row in the README's table. A new check
  takes a step in `.github/workflows/rules.yml` too.
- The repository is public. No secret, employer's name, internal host or address goes into it.
- Prose keeps to the [writing](skills/writing/SKILL.md#the-caps-and-vale) skill's caps, as Vale,
  rumdl and `tools/sizecheck` check them.

### How an action is built

- `action.yml` passes `github.repository`, the pull request's number and the inputs in `env:`,
  never as `${{ }}` in `run:`, which zizmor's template-injection audit refuses.
- A check never blocks. `check.sh` exits 0 on findings and on its own errors: `report_start` traps
  them, and each ends in one warning. A case of `tests/NAME.sh` fails where it exits non-zero.
- A check reads the pull request through `gh api` alone, and checks out nothing, so it runs none of
  the pull request's code. It runs on `pull_request`, of the types `opened, edited, reopened,
  synchronize`.
- Every check takes the inputs `token` and `comment`, and none that changes a rule. `check.sh`
  holds its skill's values, or reads the skill's own file of them, as banned-terms reads
  `skills/banned-terms/terms.json`.
- `check.sh` reaches `actions/lib/` as `$GITHUB_ACTION_PATH/../lib`, as the runner downloads the
  whole repository for `zadykian/toolkit/actions/NAME@SHA`.
- A finding says where, quotes what is wrong, and links to the rule's section of the skill. The
  link comes from `file_url`, at the action's own ref, never from a URL written out. The rule says
  how to fix it, with a command where one exists.
- `ff` runs on `issue_comment`, and acts on a `/ff` comment on a pull request alone. It checks out
  the default branch, fetches the pull request's head and pushes it with git. It runs none of
  the pull request's code. A refusal fails the job, and `comment-refusal.sh` comments why. Once
  the push lands, closing the issues and deleting the branch only warn.
- `ff` takes no inputs and uses no `actions/lib/`. `tests/ff.sh` runs its scripts in a clone of a
  local origin, and a case checks where `main` ends and what the pull request is told.

## Commits and pull requests

- [atomic-commits](skills/atomic-commits/SKILL.md) sets how commits and pull requests are cut and
  written. `.github/workflows/rules.yml` warns on a pull request that breaks its rules.
- Commits are signed, as `main`'s ruleset requires.

## How changes land

- [land](skills/land/SKILL.md) sets how pull requests land. Its `/ff` workflow is
  `.github/workflows/fast-forward.yml`.
- `.github/workflows/release.yml` releases a raised version once it lands on `main`, with the
  notes that `tools/releasenotes` writes from the commits since the last release.
