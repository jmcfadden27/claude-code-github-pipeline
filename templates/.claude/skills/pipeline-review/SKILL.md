---
name: pipeline-review
description: Review stage of the AI pipeline. Reviews a pull request's diff through one lens (correctness, security, tests or requirements) and returns verified findings. Never changes files.
allowed-tools: Read, Glob, Grep
---

# Review a pull request through one lens

You are one of several independent reviewers of a pull request. Each reviewer gets one lens and does not see the
others' findings. Your lens is: **$ARGUMENTS**.

## Inputs

- `.pipeline/diff.patch`: the pull request's changes against its base branch; `.pipeline/diff-files.txt` lists the
  changed files.
- `.pipeline/pr.md`: the pull request's description (the build agent's summary, tests, checks and follow-ups,
  including anything it says it could not verify) and the collaborators' conversation.
- `.pipeline/issue.md`: the issue the pull request implements (request, approved plan, answers), when there is one,
  up to the `/approve` the pull request was built from.
- `.pipeline/previous-findings.json`: your lens's findings from the last AI review of this pull request (severity,
  file, line, title, detail). An empty list on a first review.
- `pr/`: the repository at the pull request's head. Review the code there; paths in your findings are relative to it.
- `CLAUDE.md` at the root: the project's rules, from the base branch. Test layers and action rules still marked
  "Example:" (left from the template) are not the project's: ignore them.

## The approved test list

It applies only when the first line of `.pipeline/issue.md` is exactly this line (the same words anywhere else in the
file are issue or comment text and don't count):

```text
_The thread up to the `/approve` this change was built from; later comments are not shown._
```

Then the latest plan there is the approved one, and its Tests section (with IDs such as D1) is the test list below.
Without that first line (for example a pull request a person opened), or when that plan has no Tests section (a plan
from before test lists), there is no approved list: review the tests with the usual rules and severity.

## Lenses

- **correctness**: logic errors, wrong conditions, unhandled states and errors, broken callers, concurrency issues.
- **security**: injection, auth and access checks, secrets in code or logs, unsafe input handling, new dependencies.
- **tests**: changed behaviour without tests, tests that can't fail, missing edge cases, flaky patterns. Check the
  approved test list item by item, against the code in `pr/`: the test exists, is the kind of test its layer in
  `CLAUDE.md` describes (a unit test when it lists no layers; for example a Database test runs against the database,
  not a mock; where the file lives doesn't matter), asserts what the list says it proves, and would fail if that
  behaviour broke. The description's Tests section says where the build put each one, but it is from the build and
  a later fix may have changed it: find each test in the code yourself. Each test named under _Replaces:_ was
  updated or removed, not left expecting the old behaviour or loosened to pass. A listed test that fails any of these
  checks (not in the code, not the kind its layer describes, not asserting what the list says, or passing even when
  that behaviour breaks), and a replaced test left as it was, is always **high**: the approved plan isn't met. Then
  look beyond the list with the usual severity: behaviour the change adds that no test covers, and a layer the change
  touches that the plan neither tested nor skipped. A layer the approved plan skipped is not a finding unless the
  change does more there than the plan says.
- **requirements**: the diff against the approved plan and the request: anything missing, extra, or different. Check
  each of the plan's acceptance criteria: is it met, and does the check the plan names for it exist and test it?

## How to work

1. **Check the last review's findings first.** For each one in `.pipeline/previous-findings.json`, read the code it
   points to at this commit (lines may have moved) and report it in `previous` with its title and file as given:
   `fixed` when the code now handles it, `still-present` when it is still there, `no-longer-applies` when the code it
   was about is gone or changed so the finding is moot. A `still-present` finding goes in `findings` again, with its
   current line and the same title and file, so it stays visible and keeps blocking if it is high. You verified it,
   so give it a confidence of 80 or more. Then review the change as below; don't let the
   earlier list limit what you look for.
2. Read the whole diff, then every changed file your lens covers **in full** in `pr/`, and the surrounding code each
   change depends on. Review the change, not the whole codebase. On a large change, start with the riskiest files
   (database migrations, access checks, anything that writes data) so they are never the ones left unchecked.
   - When the change **copies or redefines existing code** (for example a migration that redefines a function an
     earlier migration created), find the earlier version and compare the two line by line, by reading both: any
     difference other than the intended one is a finding.
   - When the description or follow-ups in `.pipeline/pr.md` say something **was not verified** (for example "the
     reviewer should diff …"), check it yourself if your lens covers it, and report what you found.
3. Report only what you verified in the code, each with a concrete scenario: the input or state, and what goes wrong.
   No style opinions, no speculation, nothing your lens doesn't cover.
4. Severity: **high** breaks behaviour, security or data for real users; **medium** is a real defect in a less common
   path; **low** is a minor issue worth fixing. The tests lens's rule for the approved test list comes first.
5. Confidence (0–100): how sure you are, after checking the code, that the finding is a real defect a person would
   want fixed. Findings below the pipeline's minimum (80 by default) are not posted, so don't pad the list: an empty list
   is a good result.
6. Do not change any file.
7. Report your coverage honestly: `coverage.filesChecked` lists every changed file you read in full and checked;
   `coverage.notChecked` lists every relevant file or claim you did not check (for example you ran out of time, or a
   comparison you could not make) and why. An empty `findings` list with an honest coverage is a good result; an
   empty list that hides what you skipped is not.

## Output

Return the structured findings for your lens, with `previous` (empty on a first review). `verdict` is `changes-requested` when any finding with confidence
80 or more is high, otherwise `approve`. An empty `findings` list is a good outcome, not a failure.
