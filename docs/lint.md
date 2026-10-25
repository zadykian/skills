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

### The vouch rule

The gates run the tree's own code, such as its makefiles and `tools/`, and the hooks run them
without asking. So a hook runs no gate in a tree unless the maintainer vouches for it, where all
of these hold:

- Each commit from `origin/main` to `HEAD` has a good signature, `%G?` of `G`, by the key that
  `gpg.ssh.allowedSignersFile` lists for the commit's author address. A GPG key's user id holds
  that address instead.
- The index matches `HEAD`, with nothing staged and no conflict. A merge, a cherry-pick or a
  checkout of a path stages another's changes.
- The gate code matches `HEAD` in the work tree, with no file of it untracked, as `git apply`
  stages nothing.

The gate code is `GNUmakefile`, `makefile`, `Makefile`, `*.mk`, `tools`, `.cache`, `.gitignore`
and `.claude/lint-gates`, as git pathspecs. A repository adds its own in `.claude/lint-gates`.

`origin/main` itself is taken as vouched for, so its branch rules should require signed commits.
A git config key would not do: worktrees share their clone's config, so it would vouch for an
outside pull request fetched into a worktree too. Git needs these settings, in the user's config:

```sh
git config --global gpg.format ssh
git config --global user.signingKey ~/.ssh/id_ed25519.pub
git config --global commit.gpgSign true
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

The allowed signers file lists your address and key on a line: `you@example.com ssh-ed25519 ...`.

The check reads what git records, so it lets two cases through:

- A commit made here carries the maintainer's signature, whether Claude, a rebase or a cherry-pick
  made it. An outside change committed here as the maintainer's own passes: read it first.
- An unstaged change to a file outside the gate code goes unseen, and so does a file git ignores.
  So outside code may run where `git apply` or `git stash apply` writes it to a file the gates
  load. Read an outside pull request at its own commits, never as a diff applied to a tree.

### .claude/lint-gates

`.claude/lint-gates` adds a pathspec a line to the gate code. A `#` starts a comment, to the end
of its line. The hooks read the file from `HEAD`, so an uncommitted edit never shrinks the list.
An edit of it stops the gates, as of any other gate file, until a commit takes it.

List each file beyond the defaults that the gates run or load as code. Such are the pins of the
tools a gate installs, a linter's config that names plugins, and the modules a tool imports.

```text
# The pins of the Python tools, and ansible's settings, which name its plugins.
.github/lint-requirements.txt
ansible.cfg
*.py
```

The hooks check the defaults and the file's lines apart. So an exclude, such as `:!Makefile`,
narrows the file's own lines alone, and a file of excludes alone covers every other path.

### A notice that no gate ran

A tree the maintainer does not vouch for gets a line, shown to the user rather than Claude:

```text
lint: no gate ran in /home/you/repo, as the index differs from HEAD.
```

The hooks show each such line once a session. The gates run again once its cause is gone:

| Cause                                 | What to do                                      |
| ------------------------------------- | ----------------------------------------------- |
| `refs/remotes/origin/main is missing` | Fetch `origin`, which has a branch `main`       |
| `commit ... lacks a good signature`   | Sign it, or list its author's key as a signer   |
| `the index differs from HEAD`         | Commit the staged change, or unstage it         |
| `the gate file ... differs from HEAD` | Read the change, then commit it or undo it      |
| `the gate file ... is untracked`      | Read the file, then commit, ignore or delete it |

A tree whose makefiles name neither target gets no notice.

### Opt out

- A repository: leave the two targets out, or set `"lint@zadykian": false` under
  `enabledPlugins` in its `.claude/settings.json`.
- One person: the same key in `.claude/settings.local.json`, or in the user's settings.
- A kind of file: `lint-file` passes over the kinds it lists no gate for.

### The session's state

The hooks keep a session's state in `CLAUDE_PLUGIN_DATA/sessions/ID`, or, where that is unset, in
`claude-lint/sessions/ID` of the git common directory. It holds the trees recorded, the states
noted, and the notices shown. A session start drops the state of sessions untouched for 30 days.

[`tools/hookcheck`](../tools/hookcheck) runs the hooks on sample JSON against throwaway
repositories, and prints a line a case.

## split-file

Splits a source file over the repository's line cap into files by responsibility. Its package or
module, its API and its behaviour stay as they are, so callers and tests change nothing. It moves
the code unchanged first, then makes each file pass every gate outright, and trims the comments as
the `trim` skill does. Claude uses it when a size check reports a file over its cap, or as
`/lint:split-file FILE`.

The skill holds no language's rules: each comes from the repository. The cap is the one its size
check reports, or 300 lines. The repository's CLAUDE.md or `.claude/rules/` may set:

- the line cap, and the caps of comments, or the rules that set them;
- each language's rules: the package or module clause a new file takes, and the directives,
  build constraints or preambles that go with its declarations;
- the formatters, and how a file sheds the imports it no longer uses;
- the linters and their limits, such as a line's length, a function's length or its complexity;
- how to build, and how to run the tests of one package or module alone;
- the files that list others, such as a layout or a rule of where a test goes, which a split
  changes too;
- the commit's header, where the repository's form differs.

## banned-terms

Keeps vague names and fillers, such as `helper`, `utils`, `misc` and `simply`, out of new code and
prose. It covers the names of files, types, functions and variables, and comments, docs, commit
messages and pull requests. A term matches a whole word, so `str_utils.py` matches but `utilize`
does not. The skill holds for new text alone, and renames nothing unasked.

Claude uses it as it works on the files that `writing` covers too, as its `paths` lists them, or
as `/lint:banned-terms`. The repository's CLAUDE.md or `.claude/rules/` may set:

- terms of its own, each with a hint;
- terms of the list that it allows, as a word its domain needs.

In CI, [zadykian/actions/banned-terms][bt-action] warns on these terms in what a pull request
adds, and never blocks the merge. Its inputs `terms` and `allow` take the repository's changes to
the list.

[bt-action]: https://github.com/zadykian/actions/tree/main/banned-terms
