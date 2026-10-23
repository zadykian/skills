# lint

The `lint` plugin runs a repository's own lint gates while Claude Code works in it. After each
edit it lints the file, and as Claude ends its turn it lints the work tree. The gates are two make
targets the repository writes, `lint-file` and `lint-tree`. In a repository without them the
hooks do nothing, so the plugin is safe to enable anywhere.

## The hooks

### What runs, and when

- `SessionStart`: `lint-tree.sh` notes the state of the project's work tree.
- `PostToolUse`, after `Edit`, `MultiEdit`, `Write` or `NotebookEdit`: `lint-file.sh` runs
  `make lint-file` on the file.
- `Stop`: `lint-tree.sh` runs `make lint-tree` in each tree the session changed.

The hooks lint the project's repository alone: the work tree of `CLAUDE_PROJECT_DIR`, and its
linked work trees, such as those in `.claude/worktrees/`. A file of another repository is passed
over. Both scripts, [lint-file.sh](../hooks/lint-file.sh) and
[lint-tree.sh](../hooks/lint-tree.sh), are POSIX sh, and need `git` and GNU make but not `jq`.

After each edit, `lint-file.sh` passes over the file where any of these holds:

- the file lies outside the project's repository, is gone, or git ignores it;
- its path holds a character outside `[A-Za-z0-9._/@+-]`, or a part starting with `-`, as make
  pastes a path into its recipes unquoted;
- no makefile of its tree names `lint-file` or `lint-tree`, as the hook reads them, unrun.

Otherwise it records the tree for the Stop hook. Where the maintainer vouches for the tree and
its makefile has a rule for `lint-file`, it runs `make -k -C TREE lint-file FILES=PATH`. `PATH`
is the file's path from the tree's root. A failure goes to Claude, which fixes it.

As Claude ends its turn, `lint-tree.sh` gathers these trees:

- those that `lint-file.sh` recorded since the last stop, a record it then clears;
- the project's work tree, where its state differs from the one noted as the session started,
  and from the last stop's. The state is `HEAD`, the diff from it, and the untracked files. So
  a change made through Bash counts too.

It passes over a tree whose `HEAD` is `origin/main` with nothing staged, modified or untracked. It
passes over one whose makefile has no rule for `lint-tree` too. In each other tree that the
maintainer vouches for, it runs `make -k -C TREE lint-tree BASE=refs/remotes/origin/main`. It
gathers the failures, and Claude sees them all at once.

Claude then goes on to fix them, and stops again with `stop_hook_active` set. The hook lets it
stop then, so each failure is reported once. What the fix wrote is linted as the next turn ends.

### The targets

`lint-file` takes `FILES`, a path from the tree's root. The hook passes one file, and a list
should work too, as by hand. It runs the gates of each file's kind on that file alone, so it should
take seconds. A file of a kind no gate checks passes.

`lint-tree` takes `BASE`, the ref the branch starts from: `refs/remotes/origin/main`, the remote's
own ref, which no tag or branch named `origin/main` shadows. It runs the gates whose findings
depend on the tree alone, such as the commits' messages and the secrets in those since `BASE`.
Leave out gates that read the network or the date, such as an audit of advisories.

Both run in the tree's root, with stdin from `/dev/null`, and with `-k`, so each gate runs past
another's failure. Claude sees the end of a failure's output: 60 lines, each cut to 300 columns.
Where lines are cut, make's lines that name a failed target come first. Each target needs an
explicit rule: the hooks read make's database, `make -pRrq`, and a pattern rule is not one.
Claude Code stops `lint-file` after 5 minutes, and `lint-tree` after 15.

Where each gate takes `FILES` and passes over the files not of its kind, `lint-file` may just
list them:

```make
.PHONY: lint-file lint-tree

# The gates of each file of FILES, by its kind, which the lint plugin runs after an edit.
lint-file: vale rumdl shell sizecheck

# Every gate, as the lint plugin runs it at a turn's end.
lint-tree: lint
```
