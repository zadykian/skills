# shellcheck shell=sh
# The functions of the lint plugin's hooks, sourced by lint-file.sh and lint-tree.sh
# (docs/lint.md). Sourcing it sets variables and defines functions, and runs nothing.

# base is the full ref of origin/main. git reads a tag or a branch named origin/main before the
# remote's, and a fetch from a fork may bring such a tag.
base=refs/remotes/origin/main

# The hooks' git commands take no optional lock, such as the index's on a refresh, so that none
# fails a git command that Claude runs at the same time.
GIT_OPTIONAL_LOCKS=0
export GIT_OPTIONAL_LOCKS

# input is the hook's JSON, as each hook sets it.
input=

# field prints the string field $1 of the hook's JSON in $input, escapes as they are. sed reads
# it, as jq may be missing. A quote in a JSON string is escaped, so only a key matches.
field() {
    printf '%s\n' "$input" | tr '\n' ' ' |
        sed -E -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\1/p"
}

# flag succeeds where the hook's JSON in $input sets the key $1 to true.
flag() {
    printf '%s\n' "$input" | tr '\n' ' ' | grep -q "\"$1\"[[:space:]]*:[[:space:]]*true"
}

# common prints the git common directory of the directory $1, which every work tree of a
# repository shares.
common() {
    git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null
}

# plain succeeds where the path $1 holds only characters of [A-Za-z0-9._/@+-] and no part of it
# starts with -. make pastes a path into its recipes unquoted, and expands a $ in it, and a tool
# takes a part starting with - as an option. A path that passes is safe in a line of the record
# and in the hooks' JSON too.
plain() {
    case $1 in
    '' | *[!A-Za-z0-9._/@+-]* | -* | */-*) return 1 ;;
    esac
}

# mentions succeeds where a makefile of the work tree in the current directory names lint-file
# or lint-tree. It reads the makefiles without running them, so it serves before the vouch:
# a tree that names neither gets no notice, and costs no more than this.
mentions() {
    git grep -q --untracked -w -e lint-file -e lint-tree -- \
        GNUmakefile makefile Makefile '*.mk' 2>/dev/null
}

# vouch succeeds where the maintainer vouches for the code of the work tree in the current
# directory, which the gates run; else it prints why not. Each commit from origin/main to HEAD
# has a good signature, %G? of G, by the key that gpg.ssh.allowedSignersFile lists for its
# author, %ae, which no .mailmap changes. A GPG signer's user id holds the address in <>. A git
# config key would not do: worktrees share their clone's config, so it would vouch for an outside
# pull request fetched into a worktree too.
#
# The index matches HEAD, with no conflict, as a merge, a cherry-pick or a checkout of a path
# stages another's changes. The gate code matches HEAD in the work tree too, with no file of it
# untracked, as git apply stages nothing: the defaults, then the pathspecs that HEAD's
# .claude/lint-gates adds. Each set is checked alone, so an exclude among the added ones leaves
# the defaults whole. The file is read from HEAD, so an edit of it never shrinks the set.
vouch() {
    if ! git rev-parse -q --verify "$base^{commit}" >/dev/null; then
        echo "$base is missing"
        return 1
    fi
    format='%h%x09%G?%x09%GS%x09%ae'
    if ! signs=$(git log --no-show-signature --format="$format" "$base..HEAD" 2>/dev/null); then
        echo "git cannot list the commits from $base to HEAD"
        return 1
    fi
    bad=$(printf '%s\n' "$signs" | awk -F '\t' 'NF {
        signer = $3
        if (match(signer, /<[^<>]*>$/)) signer = substr(signer, RSTART + 1, RLENGTH - 2)
        if ($2 != "G" || signer != $4) { print $1; exit }
    }')
    if [ -n "$bad" ]; then
        echo "commit $bad lacks a good signature by its author's key"
        return 1
    fi
    if ! git diff --cached --quiet HEAD -- 2>/dev/null; then
        echo 'the index differs from HEAD'
        return 1
    fi
    pristine GNUmakefile makefile Makefile '*.mk' tools .cache .gitignore .claude/lint-gates ||
        return 1
    gates=$(git show HEAD:.claude/lint-gates 2>/dev/null |
        sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    set --
    while IFS= read -r spec; do
        [ -z "$spec" ] || set -- "$@" "$spec"
    done <<EOF
$gates
EOF
    [ $# -eq 0 ] || pristine "$@"
}

# pristine succeeds where the files of the pathspecs $@ match HEAD in the work tree, none of them
# untracked; else it prints why not.
pristine() {
    if ! changed=$(git diff --name-only HEAD -- "$@" 2>/dev/null) ||
        ! untracked=$(git ls-files --others --exclude-standard -- "$@" 2>/dev/null); then
        echo 'git cannot compare the gate code with HEAD'
        return 1
    fi
    if [ -n "$changed" ]; then
        printf 'the gate file %s differs from HEAD\n' "$(printf '%s\n' "$changed" | head -n 1)"
        return 1
    fi
    if [ -n "$untracked" ]; then
        printf 'the gate file %s is untracked\n' "$(printf '%s\n' "$untracked" | head -n 1)"
        return 1
    fi
}

# notice shows the user the text $1 in the hook's JSON output, and lets Claude go on. It drops
# control characters and escapes quotes and backslashes.
notice() {
    printf '{"systemMessage": "%s"}\n' \
        "$(printf '%s' "$1" | tr -d '\000-\037' | sed 's/[\\"]/\\&/g')"
}
