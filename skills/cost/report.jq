# Prints the report of the rows that rows.jq read, of $sessions sessions. A cost is in millions
# of units, M units, as cost.sh says.

def factor: if .model | test("haiku") then (if .prompt > 100000 then 1 / 8 else 1 / 40 end)
  elif .model | test("sonnet") then 0.5 else 1 end;
def mega: . / 1e5 | round | "\(. / 10 | floor).\(. % 10)";
def share($total): if $total > 0 then "\(. / $total * 100 | round)%" else "-" end;
def left($n): tostring | . + (" " * ($n - length) // "");
def right($n): tostring | (" " * ($n - length) // "") + .;
def row: "\(.[0] | left(32))" + (.[1:] | map(right(10)) | add);
# table prints $title over a line for each row: a label, a count, and units, a share of $total.
def table($title; $count; $total): "", ([$title, $count, "M units", "share"] | row),
  (.[] | [.[0], .[1], (.[2] | mega), (.[2] | share($total))] | row);
# by groups the calls by the key f: its label, from $labels where they name it, the calls, and
# their units.
def by(f; $labels): group_by(f) | map((.[0] | f) as $key | [$labels[$key] // $key, length,
  (map(.units) | add)]);
def gap: if .gap == null then 0 elif .gap < 300 then 1 elif .gap < 3600 then 2 else 3 end;
def size: .prompt | if . < 1e5 then 0 elif . < 2e5 then 1 elif . < 5e5 then 2 else 3 end;

(map(select(.k == "call")) | group_by(.id) | map(max_by(.out) | .prompt = .in + .w5 + .w1 + .cr
  | .factor = factor | .units = (.in + 1.25 * .w5 + 2 * .w1 + 0.05 * .cr + 5 * .out) * .factor))
  as $calls |
($calls | map(.units) | add // 0) as $total |
"Sessions: \($sessions). Responses: \($calls | length). Cost: \($total | mega) M units.",
($calls | by(.tier; {main: "main", subagent: "subagents", workflow: "workflow agents"})
  | table("By tier"; "calls"; $total)),
($calls | by(.model // "?"; null) | sort_by(-.[2])
  | table("By model"; "calls"; $total)),
($calls | by(size; ["under 100k", "100k to 200k", "200k to 500k", "500k or more"])
  | table("By context size"; "calls"; $total)),
($calls | group_by(.thread) | map(sort_by(.ts) | . as $t | [range(length) | $t[.] +
  {gap: (if . == 0 then null else $t[.].ts - $t[. - 1].ts end)}]) | add // []
  | map(.units = (1.25 * .w5 + 2 * .w1) * .factor)
  | by(gap; ["first call of a thread", "under 5 min", "5 min to 1 h", "1 h or more"])
  | table("Cache writes, by the idle gap before"; "calls"; $total))
