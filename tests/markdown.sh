# shellcheck shell=bash
# The cases of lib/markdown.sh: the lines and headings that markdown_read finds in a text, and what
# first, section, filled and quote print of them. Backticks quote Markdown here, never a command.
# shellcheck disable=SC2016

# shellcheck source=actions/lib/markdown.sh
. "$ROOT/actions/lib/markdown.sh"

# same fails the case where $2, the value of $1, differs from $3.
same() {
    [ "$2" = "$3" ] || fail "$1 is '$2', not '$3'"
}

# joined prints the values $1, $2... each followed by a |.
joined() {
    printf '%s|' "$@"
}

# A body as GitHub renders an issue form, a level-3 heading a field, with a fence and a comment.
setup reads-the-lines-and-the-headings
fenced=$'### Summary\n\nA check.\n\n```md\n### Today\n```\n'
markdown_read "$fenced"$'<!-- x -->\nProposal\n---\n\n- Do it.'
same kinds "${kinds[*]}" 'heading text text text code code code text heading heading text text'
same texts "$(joined "${texts[@]}")" \
    '### Summary||A check.||```md|### Today|```||Proposal|---||- Do it.|'
same 'the headings' "${h_starts[*]}/${h_ends[*]}/${h_levels[*]}/${h_texts[*]}" \
    '0 8/0 9/3 2/Summary Proposal'
same h_quotes "$(joined "${h_quotes[@]}")" '`### Summary`|`Proposal` over `---`|'
same 'first 3 Summary' "$(first 3 Summary)" 0
same 'first 2 Proposal' "$(first 2 Proposal)" 1
same 'first 2 Summary' "$(first 2 Summary)" -1
same 'first 3 Today, in a fence,' "$(first 3 Today)" -1
same 'section 0' "$(section 0)" $'\nA check.'
same 'section 1' "$(section 1)" $'\n- Do it.'
same 'filled 11' "$(filled 11)" 11
same 'filled 10' "$(filled 10)" 9
same 'filled 7, a comment after a fence,' "$(filled 7)" 6

# A line of dashes under a list item is a thematic break, not a heading.
setup hides-comments-and-closing-runs
markdown_read $'<!--\n## Hidden\n-->\n## Shown ##\nA <!-- note --> line\n\n- An item\n---'
same kinds "${kinds[*]}" 'text text text heading text text text text'
same texts "$(joined "${texts[@]}")" '|||## Shown ##|A  line||- An item|---|'
same 'the headings' "${h_levels[*]} ${h_texts[*]}" '2 Shown'
markdown_read ''
same 'an empty text' "${kinds[*]} ${#h_texts[@]}" 'text 0'

setup quotes
long=$(printf 'a%.0s' $(seq 61))
same "quote ' x '" "$(quote ' x ')" '`x`'
same 'quote of a backtick' "$(quote 'a `b`')" '`` a `b` ``'
same 'quote of 61 characters' "$(quote "$long")" "\`${long:0:59}…\`"
