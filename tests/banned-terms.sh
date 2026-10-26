# shellcheck shell=bash
# The cases of banned-terms/check.sh. Their fixtures hold the terms of
# skills/banned-terms/terms.json.

# The check links to main, as check runs it from this checkout.
main=https://github.com/zadykian/toolkit/blob/main
skill=$main/skills/banned-terms/SKILL.md

# start starts the case $1, of a pull request with no commit and no file.
start() {
    setup "$1"
    answer repos/o/r/pulls/1/commits '[]'
    answer repos/o/r/pulls/1/files '[]'
}

# titled answers the pull request with the title $1.
titled() {
    answer repos/o/r/pulls/1 "$(pull "$(jq -n --arg title "$1" '{title: $title}')")"
}

# commits answers the commits of the pull request, a message an argument and a page each. Their
# hashes repeat their number: 1111111, then 2222222.
commits() {
    local pages
    mapfile -t pages < <(jq -nc '$ARGS.positional | to_entries[]
        | [{sha: ("\(.key + 1)" * 40), commit: {message: .value}}]' --args "$@")
    answer repos/o/r/pulls/1/commits "${pages[@]}"
}

# files answers the files of the pull request, the JSON of one an argument and a page each.
files() {
    local file pages=()
    for file in "$@"; do pages+=("[$file]"); done
    answer repos/o/r/pulls/1/files "${pages[@]}"
}

# changed prints the JSON of a file of the path $1 and the patch $2, of the status $3, modified
# where omitted.
changed() {
    jq -nc --arg path "$1" --arg patch "$2" --arg status "${3:-modified}" \
        '{filename: $path, status: $status, changes: 1, patch: $patch}'
}

# listed leaves a tree of the action in $FAKE whose skill's terms.json holds the text $1, or which
# has no terms.json where $1 is omitted. Pass "$tree" to check, which then runs on that tree.
listed() {
    mkdir -p "$FAKE/actions/banned-terms" "$FAKE/skills/banned-terms"
    ln -s "$ROOT/actions/lib" "$FAKE/actions/lib"
    [ $# = 0 ] || printf '%s\n' "$1" >"$FAKE/skills/banned-terms/terms.json"
    tree=GITHUB_ACTION_PATH=$FAKE/actions/banned-terms
}

# matches checks that the title $1 gives a finding of each term after it, and no other.
matches() {
    local term
    start "matches-$1"
    titled "$1"
    check banned-terms
    for term in "${@:2}"; do warns "::The title says \`$term\`: \`$1\`"; done
    warnings $(($# - 1))
}

matches StringHelper helper
matches str_utils.py utils
matches MiscStuff misc stuff
matches HTTPHelper helper
matches 'getHTTPResponse, XMLHttpHelpers and HTTP2Util' helpers util
matches 'Etc. and SIMPLY' etc simply
matches 'utilize, helpful and etcd'
matches 'utils2, Thingy and miscount'

start reports-a-group-as-its-rule
titled 'feat: add a string helper and its helper test'
check banned-terms
warns "::warning title=banned-terms%3A helper%2C helpers::The title says \`helper\`"
warnings 1
summarizes "#### helper, helpers

The rule: $skill

- The title says \`helper\`: \`feat: add a string helper and its helper test\`

How to fix it:

Names no responsibility: name what it does"

# The groups of the skill's terms.json, which jq reads apart from check.sh: TERMS, a tab and HINT
# a line. The first term of each warns, with its group's rule.
groups=$(jq -r '.[] | [(.terms | join(", ")), .hint] | join("\t")' \
    "$ROOT/skills/banned-terms/terms.json") || true
start warns-on-each-group-of-the-skills-terms
[ -n "$groups" ] || fail "skills/banned-terms/terms.json lists no group"
title="feat: $(cut -f1 <<<"$groups" | sed 's/,.*//' | paste -sd ' ' -)"
titled "$title"
check banned-terms
while IFS=$'\t' read -r terms hint; do
    summarizes "#### $terms

The rule: $skill

- The title says \`${terms%%,*}\`: \`$title\`

How to fix it:

$hint"
done <<<"$groups"

# A term is lowercased, and splits at each character other than a letter or a digit. A hint's
# line ends become spaces.
start splits-each-term-of-the-list
listed '[{"terms": ["foo", "Bar-baz"], "hint": "Say it"}, {"terms": ["QUX"], "hint": "Drop\nit"}]'
titled 'feat: foo baz qux quux'
check banned-terms "$tree"
warns "::warning title=banned-terms%3A foo%2C bar%2C baz::The title says \`foo\`"
warns "::warning title=banned-terms%3A foo%2C bar%2C baz::The title says \`baz\`"
warns "::warning title=banned-terms%3A qux::The title says \`qux\`"
warnings 3
summarizes $'How to fix it:\n\nSay it'
summarizes $'How to fix it:\n\nDrop it'

start warns-without-the-list
listed
check banned-terms "$tree"
warns '::warning::banned-terms could not check #1: skills/banned-terms/terms.json, which lists'
warnings 1

start quotes-a-backtick
titled $'fix: drop  the `utils`\tmodule'
check banned-terms
summarizes "- The title says \`utils\`: \`\` fix: drop the \`utils\` module \`\`"

start cuts-a-long-quote
titled "feat: add a helper $(printf '%0130d' 0)"
check banned-terms
summarizes "\`feat: add a helper $(printf '%0100d' 0)…\`"

start reads-the-description
# A description that GitHub's editor saved, its lines ending in CR LF.
body='Parse it.\r\n\r\nAdd tests, docs, etc.\r\nIt basically works.'
answer repos/o/r/pulls/1 "$(pull "{\"body\": \"$body\"}")"
check banned-terms
warns "::Line 3 of the description says \`etc\`: \`Add tests, docs, etc.\`"
warns "::Line 4 of the description says \`basically\`: \`It basically works.\`"
warnings 2

start reads-each-commit-message
commits 'feat: add a parser helper' $'feat: add a lexer\n\nIt simply splits.\n\nRefs: #12'
check banned-terms
warns "::The subject of commit \`1111111\` says \`helper\`: \`feat: add a parser helper\`"
warns "::Line 3 of commit \`2222222 feat: add a lexer\` says \`simply\`: \`It simply splits.\`"
warnings 2

start numbers-the-lines-of-each-hunk
files "$(changed src/a.go '@@ -1,3 +1,4 @@ package a
 import "os"
-import "a/misc"
+import "a/helpers"
+helper := helpers.NewHelper()
 func a() {}
\ No newline at end of file
@@ -20,2 +21,3 @@ func b() {
 	b()
+	c := thing()
 }')" "$(changed README.md $'@@ -0,0 +1 @@\n+Simply run it.' added)"
check banned-terms
warns "file=src/a.go,line=2::The added line says \`helpers\`: \`import \"a/helpers\"\`"
warns "file=src/a.go,line=3::The added line says \`helper\`: \`helper := helpers.NewHelper()\`"
warns "file=src/a.go,line=3::The added line says \`helpers\`"
warns "file=src/a.go,line=22::The added line says \`thing\`: \`c := thing()\`"
warns "file=README.md,line=1::The added line says \`simply\`"
warnings 5
summarizes "- \`src/a.go:22\`: The added line says \`thing\`: \`c := thing()\`"

start reads-the-paths-added-or-renamed
files "$(changed src/str_utils.py $'@@ -0,0 +1 @@\n+x = 1' added)" \
    '{"filename": "lib/misc/a.go", "status": "renamed", "changes": 0}' \
    "$(changed src/helpers.go $'@@ -1 +1 @@\n-a\n+b')"
check banned-terms
at='title=banned-terms%3A util%2C utils%2C utility%2C utilities,file=src/str_utils.py'
warns "::warning $at::The path of the added file says \`utils\`: \`src/str_utils.py\`"
warns "file=lib/misc/a.go::The path of the renamed file says \`misc\`"
warnings 2

start skips-the-files-excluded
files "$(changed vendor/x/utils.go $'@@ -0,0 +1 @@\n+package utils' added)" \
    "$(changed a.go $'@@ -1 +1 @@\n+// A helper.')"
check banned-terms EXCLUDE=$'**/vendor/**\n*.md'
warns "file=a.go,line=1::The added line says \`helper\`"
warnings 1

start notes-each-file-without-a-patch
files '{"filename": "logo.png", "status": "added", "changes": 0}' \
    '{"filename": "data.json", "status": "modified", "changes": 9000}' \
    '{"filename": "old.png", "status": "removed", "changes": 0}'
check banned-terms
warns '::warning title=banned-terms%3A Files with no patch,file=logo.png::GitHub gives no patch'
warns 'file=data.json::GitHub gives no patch of the file, so its lines go unread.'
warnings 2
summarizes '#### Files with no patch'
summarizes "The rule: $main/actions/banned-terms/README.md#limits"

# The check, where the runner downloads zadykian/toolkit/actions/banned-terms@v1.2.0, links to it.
start links-at-the-ref-of-uses
mkdir -p _actions/zadykian/toolkit
ln -s "$ROOT" _actions/zadykian/toolkit/v1.2.0
titled 'feat: add a string helper'
files '{"filename": "logo.png", "status": "added", "changes": 0}'
check banned-terms GITHUB_ACTION_PATH="$FAKE/_actions/zadykian/toolkit/v1.2.0/actions/banned-terms"
tag=https://github.com/zadykian/toolkit/blob/v1.2.0
summarizes "The rule: $tag/skills/banned-terms/SKILL.md
"
summarizes "The rule: $tag/actions/banned-terms/README.md#limits"

# setup answers no commits: gh api fails, as on GitHub's 404.
setup warns-where-it-cannot-read
check banned-terms
warns '::warning::banned-terms could not check #1: check.sh:'
warnings 1

start passes-a-clean-pull-request
check banned-terms
warnings 0
summarizes "No findings remain as of \`0123456\`."
writes 0
