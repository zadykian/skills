# docs

The `docs` bundle keeps a repository's code comments and docs short. [`writing`][writing] holds the
policy, and [`trim`][trim] brings files to it. Install the plugin `docs` as the
[README](../README.md#install) shows, and its skills run as `/docs:writing` and `/docs:trim`. Or
copy a skill into a repository, where it runs as `/writing` or `/trim`:

```sh
gh skill install zadykian/skills writing --agent claude-code --scope project
gh skill install zadykian/skills trim --agent claude-code --scope project
```

`trim` reads `writing` for the policy, so a repository that installs `trim` installs `writing` too.

Each skill runs as the marketplace ships it. The repository's CLAUDE.md and `.claude/rules/` add
to its steps and win where they differ.

## writing

The writing policy for code comments and docs:

- a comment gives a block's purpose, or a reason the code cannot show, and never narrates it;
- each fact lives in one place, and a doc does not restate a command's help;
- sentences of 30 words or fewer, files of 300 lines or fewer, and prose wrapped at 100 columns;
- Vale's `Microsoft.SentenceLength`, `write-good.TooWordy` and `proselint.Needless`, each alert
  fixed by rewriting, never by an exception or a baseline.

Claude loads it unasked as it works on Markdown or on a common kind of source or config file, as
the skill's `paths` lists them. `/docs:writing` loads it by hand.

A repository's own policy goes in `.claude/rules/writing.md`, with `paths` of its own, so that it
loads with the files it covers. It holds only what the repository adds, and says that the shared
policy comes from the `writing` skill. It may hold:

- caps of the repository's own, such as a README's, a comment block's or a module comment's;
- where each kind of fact lives: the decision records, the guide, the help;
- the terms or names to keep out, by a list kept outside the repository;
- the gates that check prose, and the files each reads.

## trim

Trims code comments or Markdown docs to the policy, keeping every fact in the one place it
belongs. It deletes narration and what restates the code or the help, and rewrites each sentence
Vale flags. It changes comments, never code. Claude uses it on files that fail Vale or the comment
caps, or as `/docs:trim FILE...`.

The repository's CLAUDE.md or `.claude/rules/` may set:

- the caps of a comment block and a file, or the rules that set them;
- the form of a doc comment in each of the repository's languages;
- the texts that something besides Markdown reads, such as a heading a script links to, or
  commands a test runs;
- the checks to run on the files changed, and which of them take a list of files.

[writing]: ../skills/writing/SKILL.md
[trim]: ../skills/trim/SKILL.md
