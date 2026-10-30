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

## The agents

Five agents, each at a fixed model and effort, so that a role a cheaper model does well runs on
it. A session or a workflow names one as `lean:NAME`.

| Agent              | Model  | Effort | Tools                  | Turns | Compacts at | CLAUDE.md |
| ------------------ | ------ | ------ | ---------------------- | ----- | ----------- | --------- |
| `lean:scout`       | haiku  | medium | Read, Grep, Glob, Bash | 20    | 100k        | no        |
| `lean:runner`      | haiku  | medium | Bash, Read             | 30    | 100k        | no        |
| `lean:checker`     | sonnet | medium | Read, Grep, Glob, Bash | 40    | 200k        | yes       |
| `lean:implementer` | sonnet | medium | all                    | 80    | 200k        | yes       |
| `lean:expert`      | opus   | xhigh  | all                    | 100   | 200k        | yes       |

- `scout` finds code and facts, and returns `file:line` with snippets. It changes nothing.
- `runner` runs builds, tests and CI waits, logs each to a file, and returns the failures.
- `checker` verifies a batch of 5–10 findings, and returns a verdict line for each.
- `implementer` carries out a written spec, and commits each step once its tests pass.
- `expert` takes what needs judgment: an analysis, a design left open, research, or a judge's call.

Each caps its report at 300 words, about 2k chars. `runner`, `implementer` and `expert` give the
path of a file of details too, in the directory the brief names or in `${TMPDIR:-/tmp}`.

### Why each limit

The numbers come from the transcripts of 4 weeks of long sessions, or from a price.

- **Haiku compacts at 100k.** Haiku 5.5 bills a request at 5x once its prompt passes 100k tokens,
  and 100k is the setting's floor.
- **The others compact at 200k.** A call costs the same up to 200k, then about 1.8x a doubling.
  Workflow agents ran 126k at the median and 275k at the 90th percentile, so 200k trims the tail.
- **Turns.** Each sits near the role's calls in the logs. Explorers took 5–13 calls, so `scout`
  gets 20. A median verifier made 26, so `checker` gets 40. Workflow agents made 78 at the 90th
  percentile, so `implementer` gets 80. A build, a test run and a CI wait fit in `runner`'s 30.
- **`expert` hands off at 100.** The 10 dearest agents were open-ended implementers, at 160–250
  calls and 550–720k tokens of context. A turn limit stops an agent mid-step with no report. So
  `expert` commits and writes a handoff of 2k chars at each phase's end. At its limit, the parent
  spawns a fresh `expert` on the handoff, rather than resume the large context.
- **No CLAUDE.md for `scout` and `runner`.** The brief holds what they need, and a repository's
  CLAUDE.md would fill a context that compacts at 100k.
- **The 1-hour cache for `runner` alone.** It waits, and a wait past 5 minutes turns the next read
  into a write. A 1-hour write costs 2 against 1.25, and writes were 34% of cost, so the others
  keep the 5-minute cache.
- **A report of 300 words.** Hand-backs ran 10k chars at the median, and each later call of the
  parent carries them. 300 words is a fifth of that.

### A repository's own code search

`scout` finds code with `rg -n`, then reads a range. A trial of a semantic index as an aid saved
no tokens, and cost much to run, so `scout` needs none. A repository may still name a code search
of its own in its CLAUDE.md, for the brief to pass on. Three rules then hold:

- one semantic index for the repository, not two;
- the tool runs under a `timeout`, and `scout` falls back to `rg` on any failure. Its health check
  proves an index exists, not a daemon alone. In the logs, a mandated explorer found no index in 3
  runs of 3, and the parent grepped anyway;
- no tip added to each tool call, as each later call carries it again.

## delegate

Used by Claude as it spawns a subagent, and unasked where its description fits. It sets when to
hand off work, to which `lean` agent, how to brief it, and how to read the result.

- **A lookup of 3 calls inline.** Three calls of a main session at its 252k median read about 38k
  units at the cache price. A spawn's first call writes 36–43k tokens of prefix, about 50k units.
- **5–10 findings to a `checker`.** They share its 36–43k prefix. Past 10, it nears its 200k
  compaction.
- **A report of 300 words.** Hand-backs ran 10k chars at the median, and each later call of the
  parent carries them. 300 words is a fifth of that.
- **Half the cores at once.** Each agent runs builds and tests on the same machine, so 4 agents on
  an 8-core one. The total has no cap.
- **A queue kept by hand.** Past `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`, 20 by default, the Agent
  tool refuses a spawn and queues none. The skill starts the next agent as one ends.

## fan-out

Claude uses the `fan-out` skill as it writes a Workflow script, or plans a review with several
agents. It sizes review by risk, sends findings to a checker 5-10 at a time, fixes once, and tells
a script to tier its agents and keep its results small. Half of all workflow agents verified
something, and no script named a model, so each ran the top model.

Its hook, [lean-fanout.sh](../hooks/lean-fanout.sh), runs before the Workflow tool, and denies a
script with an `agent()` call whose options name none of `agentType`, `model` and `effort`. The
reason names the accepted forms: a role's agent, as `agentType: 'lean:checker'`, or `model` with
`effort`. The hook is POSIX sh, and needs `jq`. It reads the tool's `script`, or the file at
`scriptPath`, and passes a saved workflow, by `name`, as it has no script to read. It allows where
`jq` is missing, its input does not parse, or the file is unreadable.

Its parse is heuristic. It reads each call up to its closing parenthesis, and leaves out strings
and comments. It allows a call whose options are a variable, or an object literal with a spread,
as they may hold the keys. So it denies a call wrongly where a key is quoted, as
`'model': 'haiku'`, which counts as a string.

It misses a call where:

- a key is named and set to nothing, as `model: undefined`;
- the script builds `agent(` in a string, or calls the function by another name;
- a `${}` of a template literal holds a quote, which can skew the rest of the script.
