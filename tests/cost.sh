# shellcheck shell=bash
# The cases of the cost skill's cost.sh, on s, a session of the project /w/p: its main transcript
# on Opus, a subagent on Sonnet, and a workflow run, w, of one agent on Haiku. Its responses cost
# 4.2 M units: 3.1 the main session's, 1.0 the subagent's and 0.1 the workflow agent's.

# call prints an assistant record of the message $1, at the second $2, on the model $3, with the
# usage $4 and the content $5.
call() {
    jq -n -c --arg id "$1" --argjson t "$2" --arg model "$3" --argjson usage "$4" \
        --argjson content "${5:-[]}" '{type: "assistant", timestamp: ($t | todate),
        message: {id: $id, model: $model, usage: $usage, content: $content}}'
}

# start writes s. Its first response spans two records, and the last holds its output. Its second
# comes 10 minutes on, so its 1-hour cache write is a miss. Its last line is cut, as in a write.
start() {
    local p="$FAKE/config/projects/-w-p"
    mkdir -p "$p/s/subagents/workflows/w" "$p/s/workflows"
    {
        call a 0 claude-opus-5-5 '{"cache_creation_input_tokens": 400000, "output_tokens": 10}'
        call a 1 claude-opus-5-5 '{"cache_creation_input_tokens": 400000, "output_tokens": 100000}'
        call b 600 claude-opus-5-5 '{"cache_creation_input_tokens": 1000000,
            "cache_creation": {"ephemeral_1h_input_tokens": 1000000},
            "cache_read_input_tokens": 2000000}'
        echo '{"type": "assistant", "message": {"id": "cut'
    } >"$p/s.jsonl"
    call c 0 claude-sonnet-5-5 '{"input_tokens": 1000000, "output_tokens": 200000}' \
        >"$p/s/subagents/agent-c.jsonl"
    call d 0 claude-haiku-5-5 '{"cache_read_input_tokens": 2000000, "output_tokens": 100000}' \
        >"$p/s/subagents/workflows/w/agent-d.jsonl"
}

# report runs cost.sh in /w/p with the arguments $@. shows checks that its output holds each
# text of $@, its runs of spaces as one.
report() {
    step CLAUDE_CONFIG_DIR="$FAKE/config" CLAUDE_PROJECT_DIR=/w/p sh "$ROOT/skills/cost/cost.sh" "$@"
}
shows() {
    local text
    for text; do
        [[ $(tr -s ' ' <"$FAKE/out") == *"$text"* ]] ||
            fail "no output '$text': $(cat "$FAKE/out")"
    done
}

setup 'cost: the latest session, a response once, by tier, model and context size'
start
report
exits 0
shows 'Sessions: 1. Responses: 4. Cost: 4.2 M units' 'main 2 3.1 74%' 'subagents 1 1.0 24%' \
    'workflow agents 1 0.1 2%' 'claude-sonnet-5-5 1 1.0 24%' '200k to 500k 1 1.0 24%' \
    '500k or more 3 3.2 76%'

setup 'cost: a session missing'
report "$FAKE/gone.jsonl"
exits 1
prints 'cost.sh: no transcript'
