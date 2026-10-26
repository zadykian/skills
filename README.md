# toolkit

[Claude Code](https://code.claude.com/docs/en/overview) skills and hooks for work in a GitHub
repository, and GitHub Actions that check each pull request against the same rules. The skills
plan a change as an issue, commit it in small steps, and land the stack by fast-forward. They keep
prose short, and the hooks lint each file as Claude edits it. The skills and hooks are a plugin
marketplace, `zadykian`, of three bundles. They and the actions release at one version.

## The bundles

| Bundle | Skill          | Run as                               | What it does                          |
| ------ | -------------- | ------------------------------------ | ------------------------------------- |
| flow   | atomic-commits | by Claude as it commits              | Small commits, stacks of small PRs    |
| flow   | issue          | `/flow:issue [topic]`                | Plans a change, then files the issue  |
| flow   | land           | `/flow:land PR... [vX.Y.Z]`, by hand | Lands a stack by `/ff`, tags releases |
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

## The repository's rules

A skill's rules hold in every repository, and it runs as the marketplace ships it. A repository's
CLAUDE.md and `.claude/rules/` name its own facts, which add to a skill's steps. Such are the
checks to wait for, the gates a text passes, or the paths of its generated code. No rule of a
skill changes for a repository. Each bundle's page says what facts a repository names.

## Versions

The marketplace has one version, `X.Y.Z`, which each bundle gives too. Claude Code updates a
bundle only when its version changes. A change need not raise it: commits land on `main`
unreleased, and the last pull request of a stack raises it, for the skills, hooks and actions at
once. It raises:

- the patch, for a fix, a clearer wording, or any other commit;
- the minor, for a `feat`: a new step, argument or skill;
- the major, for a break, such as a renamed skill, an argument changed or dropped, or a step a
  repository relies on, gone. So is a make target that a repository must now write. A commit
  marks a break by a `!` in its header, or a `BREAKING CHANGE:` footer. Before 1.0, a break
  raises the minor.

The largest change since the last release sets the part it raises. Once a raise lands on `main`,
the release workflow tags `main`'s head `vX.Y.Z` and publishes a GitHub Release. Its notes list
the commits since the last release, as breaking changes, features, fixes and other changes. Under
a breaking change goes its `BREAKING CHANGE:` footer, which says what a repository must change.
[CLAUDE.md](CLAUDE.md) says how a change is made and checked.

A repository pins its actions to the same release as the marketplace's [`ref`](#install). Each
action's `uses:` names the SHA of the release's tag, with the tag in a comment.

## License

[MIT](LICENSE).
