# shellcheck shell=bash
# The cases that each check holds the values that its skill states: a cap, a list or a form that
# the check copies, as no input changes it. Each reads the value from both files, and fails where
# they differ, naming the line of each side. So a change to a skill fails here until its check
# follows it. Backticks quote the skills' Markdown here, never a command.
# shellcheck disable=SC2016

check_ac=actions/atomic-commits/check.sh check_pd=actions/pr-description/check.sh
skill_ac=skills/atomic-commits/SKILL.md template_ac=skills/atomic-commits/pull_request_template.md
check_is=actions/issue/check.sh skill_is=skills/issue/SKILL.md form_is=skills/issue/change.yml

# values prints each match of the regex $2 in the file $1: a line of FILE:LINE, a tab, and the
# match's last group. With the regex $3, it reads the first line that $3 matches, past the match.
# With $4 too, it reads on, up to the first line that $4 matches. Where nothing matches, it
# prints a line that says so, with no tab.
values() {
    local n=0 on=true some=false line rest
    [ $# -lt 3 ] || on=false
    while IFS= read -r line; do
        n=$((n + 1)) rest=$line
        if ! $on; then
            [[ $line =~ $3 ]] || continue
            on=true rest=${line#*"${BASH_REMATCH[0]}"}
        elif [ $# -gt 2 ] && { [ $# = 3 ] || [[ $line =~ $4 ]]; }; then
            break
        fi
        while [[ $rest =~ $2 ]] && [ -n "${BASH_REMATCH[0]}" ]; do
            printf '%s:%d\t%s\n' "$1" "$n" "${BASH_REMATCH[-1]}"
            rest=${rest#*"${BASH_REMATCH[0]}"} some=true
        done
    done <"$ROOT/$1"
    $some || printf '%s: no line matches %s\n' "$1" "$2"
}

# said prints the line $1 of values as FILE:LINE says 'VALUE', or, where $1 is empty, that
# nothing follows the place $2.
said() {
    if [ -z "$1" ]; then
        echo "nothing follows $2"
    elif [[ $1 == *$'\t'* ]]; then
        echo "${1%%$'\t'*} says '${1#*$'\t'}'"
    else
        echo "$1"
    fi
}

# agree checks that the lines $1 and $2 of values, the check's and the skill's, give the same
# values in the same order. The first difference fails the case, naming the line of each side,
# or the last line of a side that ends first.
agree() {
    local ours theirs a b i
    mapfile -t ours <<<"$1"
    mapfile -t theirs <<<"$2"
    for ((i = 0; i < ${#ours[@]} || i < ${#theirs[@]}; i++)); do
        a=${ours[i]-} b=${theirs[i]-}
        [[ $a != *$'\t'* || ${a#*$'\t'} != "${b#*$'\t'}" ]] || continue
        fail "$(said "$a" "${ours[-1]%%$'\t'*}"), but $(said "$b" "${theirs[-1]%%$'\t'*}")"
        return
    done
}

# slugs prints the anchor of each heading of the Markdown file $1, as GitHub makes it: lowercase,
# with its spaces as -, and its characters other than letters, digits, spaces, _ and - dropped.
slugs() {
    local line fenced=false
    while IFS= read -r line; do
        if [[ $line =~ ^\ *(\`\`\`|~~~) ]]; then
            if $fenced; then fenced=false; else fenced=true; fi
        elif ! $fenced && [[ $line =~ ^#{1,6}\ +(.+) ]]; then
            line=${BASH_REMATCH[1],,} line=${line//[^[:alnum:] _-]/}
            echo "${line// /-}"
        fi
    done <"$ROOT/$1"
}

# links checks that each $skill#ANCHOR of the check $1 names a heading of its skill: the file of
# skills/ that its skill= line names, as a URL or as the PATH of $(file_url PATH). A check with
# such anchors fails where it has no such line.
links() {
    local anchors page headings at anchor
    anchors=$(values "$1" '\$skill#([a-z0-9-]+)')
    [[ $anchors == *$'\t'* ]] || return 0
    page=$(values "$1" '^skill=.*[ /](skills/[a-z-]+/SKILL\.md)\)?$')
    if [[ $page != *$'\t'* ]]; then
        fail "$1 links to \$skill#ANCHOR, but no skill= line names a file of skills/"
        return
    fi
    page=${page#*$'\t'} headings=$(slugs "$page")
    while IFS=$'\t' read -r at anchor; do
        grep -qxF -- "$anchor" <<<"$headings" ||
            fail "$at links to $page#$anchor, which names no heading of it"
    done <<<"$anchors"
}

setup holds-the-cap-of-a-commit
agree "$(values "$check_ac" '^max_commit_lines=([0-9]+)')" \
    "$(values "$skill_ac" 'Target ≤ ([0-9]+) changed lines per commit')"

setup holds-the-word-of-a-mechanical-commit
word=$(values "$skill_ac" 'their body says `([a-z]+)`')
agree "$(values "$check_ac" '\[\[ \$\{body,,\} == \*([a-z]+)\* \]\]')" "$word"
agree "$(values "$check_ac" 'its body says so: \\`([a-z]+)\\`')" "$word"
agree "$(values "$check_ac" 'its body does not say \\`([a-z]+)\\`')" "$word"

setup holds-the-cap-of-a-pull-request
agree "$(values "$check_ac" ' max_pr_lines=([0-9]+)$')" \
    "$(values "$skill_ac" 'No PR exceeds ([0-9]+) changed lines')"

setup holds-the-types-of-a-header
types=$(values "$check_ac" '([a-z]+)' "^types='")
agree "$types" "$(values "$skill_ac" '`([a-z]+)`' '^- `type`, lowercase\. ' '^- ')"
agree "$types" "$(values "$skill_ac" '([a-z]+)' "^types='")"

setup holds-the-form-of-a-header
agree "$(values "$check_ac" '^header_form="\^\(\$\{types// /\|\}\)(.*)"$')" \
    "$(values "$skill_ac" 'grep -vE "\^\(\$types\)(.*)"$')"

setup holds-the-cap-of-a-header
cap=$(values "$skill_ac" '^\*\*Header\*\* \(required, ≤ ([0-9]+) characters in total\)')
agree "$(values "$check_ac" '-le ([0-9]+) \] \|\| finding "\$\{3:-header-length\}"')" "$cap"
agree "$(values "$check_ac" "^rule header-length 'The header is over ([0-9]+) characters'")" "$cap"
agree "$(values "$check_ac" 'Shorten the header to ([0-9]+) characters')" "$cap"

setup holds-the-width-of-a-body
width=$(values "$skill_ac" 'Wrap at ([0-9]+)[^0-9]')
agree "$(values "$check_ac" '-le ([0-9]+) \] \|\| .* finding body-width')" "$width"
agree "$(values "$check_ac" "^rule body-width 'A line of the body is over ([0-9]+) characters'")" \
    "$width"
agree "$(values "$check_ac" 'Wrap the body at ([0-9]+) ')" "$width"

setup holds-the-prefixes-of-a-temporary-commit
prefixes=$(values "$skill_ac" '`([a-z]+)!`' '^A commit whose header starts ')
agree "$(values "$check_ac" '([a-z]+)[|)]' "^temporary='\^\(\(")" "$prefixes"
agree "$(values "$check_ac" '`([a-z]+)!' '^belongs to\. A ')" "$prefixes"

setup leaves-out-the-paths-that-its-skill-does
agree "$(values actions/atomic-commits/action.yml '^ +(.+)$' '^    default: \|$' '^$')" \
    "$(values "$skill_ac" "':\(exclude,glob\)([^']+)'")"

setup holds-the-cap-of-a-description
agree "$(values "$check_pd" '^max=([0-9]+)$')" \
    "$(values "$skill_ac" ' ([0-9]+) words at most, not counting code blocks')"

setup holds-the-sections-of-a-description
sections=$(values "$skill_ac" '^- `## ([[:alpha:]]+)`')
agree "$(values "$check_pd" '([[:alpha:]]+)[ )]' '^names=\(')" "$sections"
agree "$(values "$check_pd" '=\$\(first 2 ([[:alpha:]]+)\)')" "$sections"

# The check's form of a description runs from problem_md to footer_md, each part quoted.
setup quotes-the-form-of-a-description
agree "$(values "$check_pd" "^([a-z]+_md=')?(.*[^'])'?\$" "^problem_md='" '^# ')" \
    "$(values "$skill_ac" '^(.+)$' '^```markdown$' '^```$')"

setup heads-the-template-of-a-description-by-its-sections
agree "$(values "$template_ac" '^## ([[:alpha:]]+)$')" "$sections"

# The template's comments that open with a capital are the form's lines, in order, past rumdl's
# directive. A bullet's drops its -, and the footer's opens with when it goes in.
setup guides-the-template-of-a-description-by-its-form
agree "$(values "$template_ac" '^<!-- (Where the title has !, end with: )?([A-Z].+) -->$')" \
    "$(values "$skill_ac" '^(- )?([^#].*)$' '^```markdown$' '^```$')"

# Each template beside its skill, and the toolkit's own copy of it in .github/.
setup copies-each-template-into-github
while read -r source copy; do
    cmp -s "$ROOT/$source" "$ROOT/$copy" || fail "$copy is not a copy of $source"
done <<'EOF'
skills/atomic-commits/pull_request_template.md .github/pull_request_template.md
skills/issue/change.yml .github/ISSUE_TEMPLATE/change.yml
skills/issue/config.yml .github/ISSUE_TEMPLATE/config.yml
EOF

# The check's pattern of an attribution line, (MARK )?TEXT, as TEXT or MARK TEXT, the skill's forms.
setup holds-the-line-that-may-follow-a-footer
agree "$(values "$check_pd" " by='\^(\(.+ \)\?[^']*[^' ]) '\$" |
    sed -E 's/\t\((.+) \)\?(.+)$/\t\2 or \1 \2/')" \
    "$(values "$skill_ac" 'that starts (`[^`]+` or `[^`]+`)' | tr -d '`')"

# The form's labels in its order, and those that its validations require, each at the line of its
# `required: true`.
setup holds-the-fields-of-an-issue
agree "$(values "$check_is" "'([^']+)'" '^labels=\(')" "$(values "$form_is" '^ +label: (.+)$')"
agree "$(values "$check_is" "'([^']+)'" '^required=\(')" "$(awk -v at="$form_is" '
    /^ +label: / { sub(/^ +label: /, ""); label = $0 }
    /^ +required: true$/ { print at ":" NR "\t" label }' "$ROOT/$form_is")"

setup holds-the-cap-of-an-issue
agree "$(values "$check_is" ' max_body=([0-9]+)$')" \
    "$(values "$skill_is" 'The whole body is ([0-9]+) characters at most')"

# An issue's title is a header, as a commit's.
setup holds-the-header-of-an-issue
agree "$(values "$check_is" '([a-z]+)' "^types='")" \
    "$(values "$skill_ac" '`([a-z]+)`' '^- `type`, lowercase\. ' '^- ')"
agree "$(values "$check_is" '^header_form="\^\(\$\{types// /\|\}\)(.*)"$')" \
    "$(values "$skill_ac" 'grep -vE "\^\(\$types\)(.*)"$')"
agree "$(values "$check_is" '^max_title=([0-9]+)')" \
    "$(values "$skill_ac" '^\*\*Header\*\* \(required, ≤ ([0-9]+) characters in total\)')"

setup quotes-the-form-of-an-issue
agree "$(values "$check_is" "^(form_md=')?(.*[^'])'?\$" "^form_md='" '^skeleton=')" \
    "$(values "$skill_is" '^(.+)$' '^```markdown$' '^```$')"

setup gates-hold-the-caps-of-writing
writing=skills/writing/SKILL.md
agree "$(values tools/sizecheck '^max=([0-9]+)$')" \
    "$(values "$writing" 'Files of ([0-9]+) lines or fewer')"
agree "$(values .rumdl.toml '^line-length = ([0-9]+)$')" \
    "$(values "$writing" 'prose wrapped at ([0-9]+) columns')"
agree "$(values .vale/styles/Microsoft/SentenceLength.yml '^max: ([0-9]+)$')" \
    "$(values "$writing" 'Sentences of ([0-9]+) words or fewer')"
agree "$(values .vale.ini '^([[:alpha:]-]+\.[[:alpha:]]+) = error$')" \
    "$(values "$writing" '\(`([[:alpha:]-]+\.[[:alpha:]]+)`\)')"

setup links-to-headings-of-its-skill
for script in "$ROOT"/actions/*/check.sh; do links "${script#"$ROOT"/}"; done
