# Input: the build agent's report (schemas/build-report.schema.json); $issue = the issue number; $approved = the ID of
# the /approve comment the build started from (later /fix and /review runs read the issue thread only up to it).
# Output: the pull request description as markdown.

# One line: a line break inside a list item would end the item.
def oneline: gsub("\\s*\n\\s*"; " ");
# As code, shown exactly: the fence is longer than any run of backticks inside.
def code: ([scan("`+") | length] | max // 0) as $n | ("`" * ($n + 1)) as $f
  | if $n > 0 then "\($f) \(.) \($f)" else "\($f)\(.)\($f)" end;
# One test of the build report as a list item (publish.sh shows a fix's tests the same way).
def test_line:
  "- " + (if (.id | test("\\S")) then "**\(.id)** " else "" end)
  + (if .status == "not-written" then "⚠️ not written: \(if (.note | test("\\S")) then .note | oneline else "no reason given" end)"
     elif (.file | test("\\S") | not) or (.name | test("\\S") | not) then "\(.status): ⚠️ no file or name given"
     else "\(.status): \(.file | oneline | code): \(.name | oneline | code)" end)
  + (if .status != "not-written" and (.note | test("\\S")) then " (\(.note | oneline))" else "" end);

"<!-- ai-pipeline:pr -->",
(if $approved != "" then "<!-- ai-pipeline:approved \($approved) -->" else empty end),
"Closes #\($issue)",
"",
"## Summary",
"",
.summary,
"",
"## Changes",
"",
(.changes | map("- `\(.path)`: \(.what)") | join("\n")),
"",
"## Tests",
"",
(if (.tests | length) == 0 then "_None._" else .tests | map(test_line) | join("\n") end),
"",
"## Checks",
"",
"- Agent run: \(if .checks.passed then "passed" else "failed" end). \(.checks.notes)",
"- Pipeline re-run: passed (the pipeline runs `pipeline/scripts/run-checks.sh` itself before opening this PR).",
"",
(if (.followUps | length) > 0 then
  "## Follow-ups (not in this PR)", "", (.followUps | map("- " + .) | join("\n")), ""
else empty end),
"---",
"_Opened by the AI pipeline from the approved plan on #\($issue). The AI review runs automatically; comment `/review` to run it again. A person reviews and merges._"
