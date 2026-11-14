# Input: the planning agent's structured output (schemas/plan.schema.json). Output: the plan comment as markdown.
# The first line is a marker the build stage and re-plans use to find pipeline comments.

def bullets: if length == 0 then "_None._" else map("- " + .) | join("\n") end;
def numbered: if length == 0 then "_None._" else to_entries | map("\(.key + 1). \(.value)") | join("\n") end;
# One line: a line break inside a list item would end the item.
def oneline: gsub("\\s*\n\\s*"; " ");

"<!-- ai-pipeline:plan -->",
"## 🗺️ Implementation plan",
"",
.summary,
"",
"### Approach",
"",
.approach,
"",
"### Steps",
"",
(.steps | numbered),
"",
"### Files",
"",
(if (.files | length) == 0 then "_None._" else (.files | map("- `\(.path)` (\(.change))") | join("\n")) end),
"",
"### Acceptance criteria",
"",
(.acceptanceCriteria | map("\(.criterion | oneline)  \n   _Check:_ \(.check | oneline)") | numbered),
"",
"### Tests",
"",
# Grouped by layer, in the order the layers first appear.
(if (.testPlan | length) == 0 then "_None._" else
  (.testPlan | reduce .[] as $t ([]; if any(.[]; . == $t.layer) then . else . + [$t.layer] end)) as $layers
  | [$layers[] as $layer
      | "**\($layer | oneline)**",
        "",
        (.testPlan | map(select(.layer == $layer))
          | map("- **\(.id).** \(.proves | oneline)"
              + (if (.criteria | length) > 0
                 then " _(criteri\(if (.criteria | length) == 1 then "on" else "a" end) \(.criteria | map(tostring) | join(", ")))_"
                 else "" end)
              + (if (.replaces | test("\\S")) then "  \n  _Replaces:_ \(.replaces | oneline)" else "" end))
          | join("\n")),
        ""]
  | .[:-1] | join("\n")
end),
(if (.skippedLayers | length) > 0 then
  "",
  "_Layers with no tests:_",
  "",
  (.skippedLayers | map("- \(.layer | oneline): \(.reason | oneline)") | join("\n"))
else empty end),
"",
"### Risks",
"",
(.risks | bullets),
"",
(if (.questions | length) > 0 then
  "### ❓ Questions before I build",
  "",
  (.questions | numbered),
  "",
  "_Reply in one comment that starts with `/plan` followed by your answers; the plan is updated from them._"
elif (.acceptanceCriteria | length) == 0 then
  "### ⚠️ Not ready to build",
  "",
  "_The plan has no acceptance criteria. Comment `/plan` followed by how you'll check the change works; the plan is updated from it._"
elif .readyToBuild | not then
  "### ⚠️ Not ready to build",
  "",
  "_The planner didn't mark this plan ready. Comment `/plan` with any changes to plan it again._"
else
  # /approve checks that this footer is the comment's last line (approved-plan.sh): keep the two in step.
  "### ✅ Ready to build",
  "",
  "_Comment `/approve` to build this plan._"
end)
