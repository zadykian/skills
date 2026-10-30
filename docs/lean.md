# lean

The `lean` plugin cuts the tokens and the time of long sessions that fan out subagents and
workflows. Its rules are generic. Each of its numbers comes from 4 weeks of transcripts, a price,
or a documented default, and Claude Code 2.1.312 is the version its settings were checked on.

## cost

Reports what sessions cost, from the transcripts in `~/.claude/projects/`, as
`/lean:cost [SESSION...]`, by hand alone. It measures a baseline before a rule ships, and the
change after. Its `cost.sh`, beside the skill, is POSIX sh and `jq`, and its header comment says
how it weighs a token. The report gives:

- the cost, in units of an Opus 5.5 input token, by tier, model and the prompt's size;
- cache writes by the idle gap before each, as a gap past 5 minutes turns a read into a write;
- the ten largest tool results, and the foreground polls, with the minutes they waited;
- each workflow's `totalTokens`, which leaves out cache reads, beside its agents' real tokens.

Claude Code deletes a transcript after 30 days by default, so a baseline of weeks needs
`cleanupPeriodDays` raised. A repository names nothing for it.
