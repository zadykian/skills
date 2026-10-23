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
- `docs/BUNDLE.md`: what each skill of a bundle does, and what a repository's rules may set for it.
- `CHANGELOG.md`: a `## X.Y.Z` section per version, the newest first.
- `tools/`: the gates' scripts. `tools/run` downloads the lint tools at the versions and SHA-256
  sums it pins, into `.cache/tools`.

## Commands

```sh
make lint                          # every gate, as CI's lint job runs them
make vale FILES='PATHS'            # one gate, on some files
make versions                      # the bundles and the version, against origin/main
make hooks                         # the hooks, against throwaway repositories
claude --plugin-dir .              # a session with the work tree's skills
```

`make lint` needs `jq` and `claude` on the `PATH`. `make plugins` runs `claude plugin validate`
on the marketplace and on the skills, its warnings counted as errors.

## A change to a skill or a hook

- A skill is generic, and reads no notes of a repository's. It names no repository's paths, jobs,
  terms, people or languages: those go in the repository's CLAUDE.md or `.claude/rules/`. A skill
  names another by its bare name, as both install paths name them differently.
- Each change to `skills/`, `hooks/` or the catalog raises the version, as
  [Versions](README.md#versions) says: in the catalog's `metadata.version` and in each bundle.
  It adds its part to the version's section in CHANGELOG.md. `make versions` fails otherwise. A
  change that breaks a repository's rules or targets says what to change there, in the changelog.
- A new skill: its directory, its bundle's `skills` list, its row in the README's table, and its
  section in its bundle's page.
- The repository is public. No secret, employer's name, internal host or address goes into it.
- Prose keeps to the `writing` skill: 30 words a sentence and 100 columns a line, as Vale and
  rumdl check, and a file to 300 lines, as `tools/sizecheck` checks.

## Commits and pull requests

- [atomic-commits](skills/atomic-commits/SKILL.md) sets how commits and pull requests are cut.
- The header is a Conventional Commits header, as `tools/commits` checks it. Its scope is the
  skill or the bundle changed, as `feat(land): ...` or `fix(lint): ...`. A change across them, or
  to the repository, takes none.
- Commits are signed, as `main`'s ruleset requires.

## How changes land

- Pull requests land on `main` by fast-forward only: never run `gh pr merge`, and never push to
  `main`. A comment `/ff` lands one (`.github/workflows/fast-forward.yml`), as `/flow:land` does.
- The maintainer pushes a pull request that changes `.github/workflows` by hand,
  `git push origin SHA:main`, as the workflow's token may not push such a change.
- `.github/workflows/release.yml` releases each new version once it lands on `main`.
