_Pull request description written by the pipeline. Title: **feat(tasks): add optional due dates to tasks**._

<!-- ai-pipeline:pr -->
Closes #12

## Summary

Tasks can now have an optional due date. GET /tasks lists open overdue tasks first, then by due date, then by creation time. Past due dates are accepted; completed tasks are never overdue.

## Changes

- `migrations/0007_add_task_due_date.sql`: Adds the nullable due_date column
- `src/tasks/task.ts`: dueDate on the model and the request types
- `src/tasks/task-validator.ts`: Validates dueDate as an ISO date
- `src/tasks/task-routes.ts`: New ordering for GET /tasks
- `test/db/migrations.test.ts`: Migration 0007 and the due_date column
- `test/task-validator.test.ts`: Due date validation
- `test/tasks.test.ts`: Create, update and ordering with due dates; the old newest-first test now checks the new order

## Tests

- **D1** written: `test/db/migrations.test.ts`: `0007 adds a nullable due_date that keeps existing tasks null`
- **U1** written: `test/task-validator.test.ts`: `accepts a missing, future or past ISO dueDate and rejects any other`
- **A1** written: `test/tasks.test.ts`: `POST /tasks stores an optional dueDate, including a past one`
- **A2** written: `test/tasks.test.ts`: `PATCH /tasks/:id sets a past dueDate, changes it and clears it`
- **A3** updated: `test/tasks.test.ts`: `GET /tasks lists open overdue tasks first, then by due date` (Was 'GET /tasks lists tasks newest first')

## Checks

- Agent run: passed. Lint and 58 tests passed on the second run (first run: one ordering test failed, fixed).
- Pipeline re-run: passed (the pipeline runs `pipeline/scripts/run-checks.sh` itself before opening this PR).

## Follow-ups (not in this PR)

- Show due dates in the web client

---
_Opened by the AI pipeline from the approved plan on #12. The AI review runs automatically; comment `/review` to run it again. A person reviews and merges._
