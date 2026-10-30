# Reads a transcript's lines, of the tier $tier and the thread $thread, into a row for each
# response. A line that is not JSON, as one being written, gives none.

fromjson? | (.timestamp // "" | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601? // 0) as $ts |
if .type == "assistant" and .message.model != "<synthetic>" then
  .message as $m |
  ($m.usage | objects | (.cache_creation.ephemeral_1h_input_tokens // 0) as $w1 |
    {k: "call", $tier, $thread, $ts, id: ($m.id // "\($thread) \($ts)"), model: $m.model,
     in: (.input_tokens // 0), $w1, w5: ((.cache_creation_input_tokens // 0) - $w1),
     cr: (.cache_read_input_tokens // 0), out: (.output_tokens // 0)})
else empty end
