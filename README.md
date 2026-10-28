# toolkit

[Claude Code](https://code.claude.com/docs/en/overview) skills and hooks for work in a GitHub
repository, and GitHub Actions that check each pull request against the same rules. The skills
plan a change as an issue, commit it in small steps, and land the stack by GitHub's merge. They keep
prose short, and the hooks lint each file as Claude edits it. The skills and hooks are a plugin
marketplace, `zadykian`, of three bundles. They and the actions release at one version.

## The bundles

| Bundle | Skill          | Run as                               | What it does                          |
| ------ | -------------- | ------------------------------------ | ------------------------------------- |
| flow   | atomic-commits | by Claude as it commits              | Small commits, stacks of small PRs    |
| flow   | issue          | `/flow:issue [topic]`                | Plans a change, then files the issue  |
| flow   | land           | `/flow:land PR... [vX.Y.Z]`, by hand | Lands a stack by merge, tags releases |
| docs   | writing        | by Claude as it edits a file         | The policy for comments and docs      |
| docs   | trim           | `/docs:trim FILE...`                 | Trims comments and docs to the policy |
| lint   | split-file     | `/lint:split-file FILE`              | Splits a file over the line cap       |
| lint   | banned-terms   | by Claude as it writes code or prose | Keeps vague names and fillers out     |
| lint   | its hooks      | after each edit, and as Claude stops | Run the repository's own lint gates   |

Claude Code names a bundle's skill after the bundle, as `/flow:land`. Claude also uses a skill
unasked where its description fits the task, unless it runs by hand only. [flow](docs/flow.md),
[docs](docs/docs.md) and [lint](docs/lint.md) say how each runs, and what a repository adds.

## Install

In a session, for yourself, on Claude Code 2.1.275 or later, which adds the marketplace too:

```text
/plugin install flow --marketplace zadykian/toolkit
/plugin install docs --marketplace zadykian/toolkit
/plugin install lint --marketplace zadykian/toolkit
```

For everyone who works in a repository, in its `.claude/settings.json`. Claude Code reads it once
the folder is trusted, fetches the marketplace, and loads the bundles enabled there:

```json
{
  "extraKnownMarketplaces": {
    "zadykian": {
      "source": { "source": "github", "repo": "zadykian/toolkit", "ref": "vX.Y.Z" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "flow@zadykian": true,
    "docs@zadykian": true,
    "lint@zadykian": true
  }
}
```

Claude Code updates a third party's marketplace only where `autoUpdate` is on, or when asked:
`/plugin marketplace update zadykian`. The `"ref"` holds it at a release, as `main` may hold
changes not yet released: name that release's tag in place of `vX.Y.Z`.

One skill alone, with [gh](https://cli.github.com/) 2.90 or later, copied into the repository's
`.claude/skills`, where it runs as `/land`:

```sh
gh skill install zadykian/toolkit land --agent claude-code --scope project
```

gh installs the latest release, or the one a `land@v1.0.0` names, and pins it with `--pin`. It
copies no hooks: the lint bundle's come with the plugin alone.

## The actions

| Action                                   | Skill          | What it does                                       |
| ---------------------------------------- | -------------- | -------------------------------------------------- |
| [atomic-commits](actions/atomic-commits) | atomic-commits | Warns on a PR's commits, its size or its title     |
| [pr-description](actions/pr-description) | atomic-commits | Warns on a description off Problem, then Changes   |
| [issue](actions/issue)                   | issue          | Warns on an issue's title or body off its form     |
| [banned-terms](actions/banned-terms)     | banned-terms   | Warns on vague names and fillers that a PR adds    |

The checks warn and never block. Each annotates its run, writes a job summary and keeps one
comment of its own up to date, and its job passes. A check reads the pull request or the issue
through GitHub's API alone and checks out nothing, so it runs none of a pull request's code. No
input changes a rule: each check holds its skill's own, and links each finding to the rule.

The checks of a pull request run in one workflow, `.github/workflows/rules.yml`, a step each:

```yaml
name: rules

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number }}
  cancel-in-progress: true

permissions: {}

jobs:
  rules:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: zadykian/toolkit/actions/atomic-commits@SHA # vX.Y.Z
      - uses: zadykian/toolkit/actions/pr-description@SHA # vX.Y.Z
      - uses: zadykian/toolkit/actions/banned-terms@SHA # vX.Y.Z
```

[Pin a release](#pin-a-release) says which hash to pin. The `edited` type checks the title and the
description again once they change, and `pull-requests: write` lets each check keep its comment.
The `concurrency` group cancels a pull request's older run once a newer event starts one, as the
two would race to create each comment.

The issue check takes a workflow of its own, on `issues`, as no event of a pull request names an
issue. [Its README](actions/issue/README.md#usage) shows it.

Each action's README says what it checks, and its inputs.

## The templates

| Template                                                                   | Skill          | Path in a repository                |
| -------------------------------------------------------------------------- | -------------- | ----------------------------------- |
| [pull_request_template.md](skills/atomic-commits/pull_request_template.md) | atomic-commits | `.github/pull_request_template.md`  |
| [change.yml](skills/issue/change.yml)                                      | issue          | `.github/ISSUE_TEMPLATE/change.yml` |
| [config.yml](skills/issue/config.yml)                                      | issue          | `.github/ISSUE_TEMPLATE/config.yml` |

A skill writes a text in its template's form. A repository copies each template, of the release
it pins, to its path, where GitHub offers it to whoever opens a new pull request or issue. The
issue form's `config.yml` turns blank issues off.

## The repository's rules

A skill's rules hold in every repository, and it runs as the marketplace ships it. A repository's
CLAUDE.md and `.claude/rules/` name its own facts, which add to a skill's steps. Such are the
checks to wait for, the gates a text passes, or the paths of its generated code. No rule of a
skill changes for a repository. Each bundle's page says what facts a repository names.

## Versions

One version, `X.Y.Z`, covers every part: the skills, the hooks and the actions. The marketplace
gives it, and each bundle too, as Claude Code updates a bundle only when its version changes. A
change need not raise it: commits land on `main` unreleased, and the last pull request of a stack
raises it. It raises:

- the patch, for a fix, a clearer wording, or any other commit;
- the minor, for a `feat`: a new step, argument, input, skill or action;
- the major, for a break, such as a renamed skill or action, an argument or input changed or
  dropped, or a step a repository relies on, gone. So is a make target that a repository must now
  write. A commit marks a break by a `!` in its header, or a `BREAKING CHANGE:` footer. Before
  1.0, a break raises the minor.

The largest change since the last release sets the part it raises. Once a raise lands on `main`,
the release workflow tags `main`'s head `vX.Y.Z` and publishes a GitHub Release. Its notes list
the commits since the last release, as breaking changes, features, fixes and other changes. Under
a breaking change goes its `BREAKING CHANGE:` footer, which says what a repository must change.
[CLAUDE.md](CLAUDE.md) says how a change is made and checked.

### Pin a release

A repository pins the skills and the actions to the same release, so that its checks hold the
rules its skills teach:

- the marketplace's `"ref"` in `.claude/settings.json` names the release's tag, as
  [Install](#install) shows;
- each action's `uses:` names the full hash of the tag's commit, with the tag in a comment, as
  `zadykian/toolkit/actions/NAME@SHA # vX.Y.Z`. `git rev-parse vX.Y.Z^{commit}` prints the hash.

A released tag is never moved or deleted, and no major tag, such as `v1`, follows the releases.

Dependabot moves an action's hash and comment, but not the marketplace's `ref`, which it does not
read. So a repository's `github-actions` update in `.github/dependabot.yml` ignores every action
of the toolkit, `ignore: [{dependency-name: "zadykian/toolkit*"}]`, and `tools/pin` moves both to
a release. Run it from a clone of this repository that has the tag:

```sh
tools/pin vX.Y.Z DIR
```

It pins the repository whose work tree is `DIR`. Its header comment says what it changes.

## License

[MIT](LICENSE).
