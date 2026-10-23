# skills

[Claude Code](https://code.claude.com/docs/en/overview) skills and hooks for work in a GitHub
repository. They plan a change as an issue, commit it in small steps, and land the stack by
fast-forward. They keep prose short, and lint each file as Claude edits it. The repository is a
plugin marketplace, `zadykian`, of three bundles that share one version.

## The bundles

| Bundle | Skill          | Run as                               | What it does                          |
| ------ | -------------- | ------------------------------------ | ------------------------------------- |
| flow   | atomic-commits | by Claude as it commits              | Small commits, stacks of small PRs    |
| flow   | issue          | `/flow:issue [topic]`                | Plans a change, then files the issue  |
| flow   | land           | `/flow:land PR... [vX.Y.Z]`, by hand | Lands a stack by `/ff`, tags releases |
| docs   | writing        | by Claude as it edits a file         | The policy for comments and docs      |
| docs   | trim           | `/docs:trim FILE...`                 | Trims comments and docs to the policy |
| lint   | split-file     | `/lint:split-file FILE`              | Splits a file over the line cap       |
| lint   | its hooks      | after each edit, and as Claude stops | Run the repository's own lint gates   |

Claude Code names a bundle's skill after the bundle, as `/flow:land`. Claude also uses a skill
unasked where its description fits the task, unless it runs by hand only. [flow](docs/flow.md),
[docs](docs/docs.md) and [lint](docs/lint.md) say how each runs, and what a repository adds.

## Install

In a session, for yourself, on Claude Code 2.1.275 or later, which adds the marketplace too:

```text
/plugin install flow --marketplace zadykian/skills
/plugin install docs --marketplace zadykian/skills
/plugin install lint --marketplace zadykian/skills
```

For everyone who works in a repository, in its `.claude/settings.json`. Claude Code reads it once
the folder is trusted, fetches the marketplace, and loads the bundles enabled there:

```json
{
  "extraKnownMarketplaces": {
    "zadykian": {
      "source": { "source": "github", "repo": "zadykian/skills" },
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
`/plugin marketplace update zadykian`. A `"ref": "v1.0.0"` beside `"repo"` holds it at a release.

One skill alone, with [gh](https://cli.github.com/) 2.90 or later, copied into the repository's
`.claude/skills`, where it runs as `/land`:

```sh
gh skill install zadykian/skills land --agent claude-code --scope project
```

gh installs the latest release, or the one a `land@v1.0.0` names, and pins it with `--pin`. It
copies no hooks: the lint bundle's come with the plugin alone.

## The repository's rules

A skill holds what every repository shares, and runs as the marketplace ships it. What one
repository adds goes in its CLAUDE.md, CONTRIBUTING.md or `.claude/rules/`, which win where they
differ from a skill. They hold such things as the checks to wait for, an issue's title, or the
gates a text passes. Each bundle's page says what they may set for its skills.

## Versions

The marketplace has one version, `X.Y.Z`, which each bundle gives too, and
[CHANGELOG.md](CHANGELOG.md) says what each version changed. Claude Code updates a bundle only
when its version changes, so each change to a skill, a hook or the catalog raises it:

- the patch, for a fix or a clearer wording;
- the minor, for a new step, argument or skill;
- the major, for a break, such as a renamed skill, an argument changed or dropped, or a step a
  repository relies on, gone. So is a make target that a repository must now write.

The largest change in a release sets the part it raises. A version that lands on `main` is
released as the tag `vX.Y.Z` and a GitHub Release. [CLAUDE.md](CLAUDE.md) says how a change is
made and checked.

## License

[MIT](LICENSE).
