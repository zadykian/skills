# skills

A Claude Code plugin marketplace, `zadykian`, of three bundles, `flow`, `docs` and `lint`, that
share one version. [README.md](README.md) says what each skill does, how to install it, and what
a version's parts mean.

## Layout

- `.claude-plugin/marketplace.json`: the catalog. Each bundle takes its skills from the root,
  `"source": "./"` with `"strict": false`, lists them, and gives the marketplace's version.
  `lint`'s hooks are inline in its entry.
- `skills/NAME/SKILL.md`: a skill, which a bundle offers as `/BUNDLE:NAME`, and
  `gh skill install` copies as `/NAME`. Its directory holds `SKILL.md` alone, as gh copies the
  whole directory into a repository.
- `hooks/`: the lint bundle's hooks, which Claude Code runs from its copy of the marketplace.
- `docs/BUNDLE.md`: what each skill of a bundle does, and what facts a repository names for it.
- `tools/`: the gates' scripts. `tools/run` downloads the lint tools at the versions and SHA-256
  sums it pins, into `.cache/tools`.
- `actions/NAME/`: a GitHub Action, which a workflow uses as `zadykian/toolkit/actions/NAME@SHA`,
  and a README of what it does. A `check.sh` reaches `actions/lib/` as `$GITHUB_ACTION_PATH/../lib`.
- `tests/run`: runs the cases of each `tests/NAME.sh` against `tests/gh`, the fake gh. Its header
  comment says how to write a case.

## Commands

```sh
make lint                          # every gate, as CI's lint job runs them
make vale FILES='PATHS'            # one gate, on some files
make versions                      # the bundles, and the version against the last release
make hooks                         # the hooks, against throwaway repositories
make test                          # the actions' cases, as CI's test job runs them
claude --plugin-dir .              # a session with the work tree's skills
```

`make lint` needs `jq` and `claude` on the `PATH`, and `make test` needs `git` and `jq`.
`make plugins` runs `claude plugin validate` on the marketplace and on the skills, its warnings
counted as errors.

## A change to a skill or a hook

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
- The repository is public. No secret, employer's name, internal host or address goes into it.
- Prose keeps to the [writing](skills/writing/SKILL.md#the-caps-and-vale) skill's caps, as Vale,
  rumdl and `tools/sizecheck` check them.

## Commits and pull requests

- [atomic-commits](skills/atomic-commits/SKILL.md) sets how commits and pull requests are cut and
  written. `.github/workflows/rules.yml` warns on a pull request that breaks its rules.
- Commits are signed, as `main`'s ruleset requires.

## How changes land

- [land](skills/land/SKILL.md) sets how pull requests land. Its `/ff` workflow is
  `.github/workflows/fast-forward.yml`.
- `.github/workflows/release.yml` releases a raised version once it lands on `main`, with the
  notes that `tools/releasenotes` writes from the commits since the last release.
