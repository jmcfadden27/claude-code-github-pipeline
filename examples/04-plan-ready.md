_Comment posted by the pipeline on issue #12 after the answers._

<!-- ai-pipeline:plan -->
## 🗺️ Implementation plan

Add an optional due date to tasks and list overdue open tasks first.

### Approach

As before, with the answers applied: due dates in the past are allowed, and only open tasks count as overdue.

### Steps

1. Add migration 0007_add_task_due_date with a nullable due_date column
2. Add dueDate to the Task model, the create and update request types and TaskValidator
3. Sort GET /tasks: open overdue tasks first, then by due date, then by creation time
4. Add tests for create, update, validation and ordering (including completed overdue tasks)

### Files

- `migrations/0007_add_task_due_date.sql` (create)
- `src/tasks/task.ts` (modify)
- `src/tasks/task-validator.ts` (modify)
- `src/tasks/task-routes.ts` (modify)
- `test/db/migrations.test.ts` (modify)
- `test/task-validator.test.ts` (modify)
- `test/tasks.test.ts` (modify)

### Acceptance criteria

1. A task can be created and updated with an optional due date, including one in the past  
   _Check:_ Database, unit and API tests store, validate, create and update tasks with no due date, a future date and a past date (D1, U1, A1, A2)
2. GET /tasks lists open overdue tasks first; completed tasks are never overdue  
   _Check:_ An API test lists open and completed tasks with past, future and no due dates and checks the order (A3)

### Tests

**Database**

- **D1.** After migration 0007, tasks have a nullable due_date: existing tasks keep a null due date and a new one stores a past or future date _(criterion 1)_

**Unit**

- **U1.** TaskValidator accepts a missing dueDate, a future ISO date and a past one, and rejects a date that isn't ISO _(criterion 1)_

**API**

- **A1.** POST /tasks with no dueDate, a future date and a past date returns 201 with the dueDate it was sent _(criterion 1)_
- **A2.** PATCH /tasks/:id sets a past dueDate, changes it and clears it _(criterion 1)_
- **A3.** GET /tasks with open and completed tasks that have past, future and no due dates lists open overdue tasks first, then by due date; completed tasks are never overdue _(criterion 2)_  
  _Replaces:_ 'GET /tasks lists tasks newest first', which expects the old order

_Layers with no tests:_

- UI: No client code in this change (the web client is a follow-up)
- Journey: No user flow changes until the web client shows due dates

### Risks

_None._

### ✅ Ready to build

_Comment `/approve` to build this plan._
