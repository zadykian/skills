# shellcheck shell=bash
# The Markdown reader of a check.sh, which sources it: the lines and the headings of a text, such
# as a pull request's description, as GitHub renders them. Sourcing it defines functions, and runs
# nothing.
#
#   markdown_read TEXT   reads the Markdown TEXT into the arrays below
#   first LEVEL TEXT     prints the index of the first heading TEXT of the level LEVEL, or -1
#   section I            prints the text lines of the heading I's section, up to the next heading
#   filled LINE          prints the index of the last line, at or before LINE, that holds something
#   quote TEXT           prints TEXT as a Markdown code span, cut to 60 characters
#
# markdown_read sets the arrays of the lines, kinds and texts, and of the headings, h_starts,
# h_ends, h_levels, h_texts and h_quotes, as its comments say. A heading may be an ATX one, as
# `## Title`, or a setext one, a line underlined with === or ---. A heading in a fenced code block
# or in an HTML comment is none.

# quote prints the text $1 as a Markdown code span, without its outer blanks, cut to 60 characters.
quote() {
    local text=$1
    text=${text#"${text%%[![:blank:]]*}"} text=${text%"${text##*[![:blank:]]}"}
    [ "${#text}" -le 60 ] || text="${text:0:59}…"
    if [[ $text == *"\`"* ]]; then printf "\`\` %s \`\`" "$text"; else printf "\`%s\`" "$text"; fi
}

# markdown_heading records a heading from the line $1 to the line $2, of the level $3 and the
# text $4, as the Markdown $5 quotes it.
markdown_heading() {
    h_starts+=("$1") h_ends+=("$2") h_levels+=("$3") h_texts+=("${4%"${4##*[![:blank:]]}"}")
    h_quotes+=("$5")
}

# first prints the index of the first heading of the level $1 and the text $2, or -1.
first() {
    local i
    for i in "${!h_texts[@]}"; do
        [ "${h_levels[i]} ${h_texts[i]}" != "$1 $2" ] || { echo "$i" && return; }
    done
    echo -1
}

# filled prints the index of the last line, at or before the line $1, that holds something, or -1.
filled() {
    local i=$1
    while ((i >= 0)) && [ "${kinds[i]}" != code ] && [ -z "${texts[i]//[[:blank:]]/}" ]; do
        i=$((i - 1))
    done
    echo "$i"
}

# section prints the text lines of the heading $1's section, up to the next heading.
section() {
    local i end=${#kinds[@]}
    [ "$1" = $((${#h_starts[@]} - 1)) ] || end=${h_starts[$1 + 1]}
    for ((i = h_ends[$1] + 1; i < end; i++)); do
        [ "${kinds[i]}" != text ] || printf '%s\n' "${texts[i]}"
    done
}

# markdown_read reads the Markdown $1 into the lines and the headings below.
markdown_read() {
    local fence hidden para opener closer atx closing setext item line visible rest n level text i
    # The text's lines from 0, as Markdown reads them: kinds[i] is text, code or heading, and
    # texts[i] the line without its HTML comments. A comment that opens a line hides the lines up
    # to its end, as an HTML block does; one within a line hides itself alone.
    kinds=() texts=() fence='' hidden=false para=-1
    # The headings by index: their first and last lines, levels, texts, and quotes of their source.
    h_starts=() h_ends=() h_levels=() h_texts=() h_quotes=()
    opener="^ {0,3}((\`{3,})[^\`]*|(~{3,}).*)\$" closer="^ {0,3}(\`{3,}|~{3,})[[:blank:]]*\$"
    atx='^ {0,3}(#{1,6})([[:blank:]]+(.*))?$'
    closing='^((.*[^[:blank:]])[[:blank:]]+)?#+[[:blank:]]*$'
    # A setext heading underlines a paragraph, but not a list item or a quote: there, a line of
    # dashes is a thematic break.
    setext='^ {0,3}(=+|-+)[[:blank:]]*$' item='^ {0,3}(>|([-*+]|[0-9]{1,9}[.)])([[:blank:]]|$))'
    while IFS= read -r line; do
        if [ -n "$fence" ] || { ! $hidden && [[ $line =~ $opener ]]; }; then
            if [ -z "$fence" ]; then
                fence=${BASH_REMATCH[2]}${BASH_REMATCH[3]}
            elif [[ $line =~ $closer && ${BASH_REMATCH[1]} == "$fence"* ]]; then
                fence=''
            fi
            kinds+=(code) texts+=("$line") para=-1
            continue
        fi
        visible='' rest=$line
        while :; do
            if $hidden; then
                [[ $rest == *'-->'* ]] || break
                rest=${rest#*'-->'} hidden=false
            elif [[ $rest == *'<!--'*'-->'* ]]; then
                visible+=${rest%%'<!--'*} rest=${rest#*'<!--'} rest=${rest#*'-->'}
            else
                if [[ $rest != *'<!--'* || "$visible${rest%%'<!--'*}" == *[![:blank:]]* ]]; then
                    visible+=$rest
                else
                    hidden=true
                fi
                break
            fi
        done
        texts+=("$visible") n=${#kinds[@]}
        if [[ $visible =~ $atx ]]; then
            # A closing run of #, as in `## Problem ##`, is no part of the text.
            level=${#BASH_REMATCH[1]} text=${BASH_REMATCH[3]}
            [[ ! $text =~ $closing ]] || text=${BASH_REMATCH[2]}
            markdown_heading "$n" "$n" "$level" "$text" "$(quote "$visible")"
            kinds+=(heading) para=-1
        elif [ "$para" != -1 ] && [[ $visible =~ $setext && ! ${texts[para]} =~ $item ]]; then
            level=1
            [[ $visible != *-* ]] || level=2
            text=$(printf '%s ' "${texts[@]:para:n-para}")
            text=${text#"${text%%[![:blank:]]*}"}
            markdown_heading "$para" "$n" "$level" "$text" \
                "$(quote "$text") over $(quote "$visible")"
            for ((i = para; i <= n; i++)); do kinds[i]=heading; done
            para=-1
        else
            kinds+=(text)
            # The first line of the paragraph that this line is in, or -1 for a blank line.
            if [ -z "${visible//[[:blank:]]/}" ]; then para=-1; elif ((para < 0)); then para=$n; fi
        fi
    done <<<"$1"
}
