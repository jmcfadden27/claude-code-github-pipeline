<!-- ai-pipeline:plan -->
## 🗺️ Implementation plan

Add an optional due date to tasks and list overdue tasks first.

### Approach

Add a nullable due_date column through a new migration, expose it on the task model and the create/update endpoints, and sort GET /tasks by overdue first, then by due date, then by creation time. Validation follows the existing TaskValidator pattern.

### Steps

1. Add migration 0007_add_task_due_date with a nullable due_date column
2. Add dueDate to the Task model, the create and update request types and TaskValidator
3. Sort GET /tasks: overdue first, then by due date, then by creation time
4. Add tests for create, update, validation and ordering

### Files

- `migrations/0007_add_task_due_date.sql` (create)
- `src/tasks/task.ts` (modify)
- `src/tasks/task-validator.ts` (modify)
- `src/tasks/task-routes.ts` (modify)
- `test/db/migrations.test.ts` (modify)
- `test/task-validator.test.ts` (modify)
- `test/tasks.test.ts` (modify)

### Acceptance criteria

1. A task can be created and updated with an optional due date  
   _Check:_ API tests create and update tasks with and without dueDate
2. GET /tasks lists overdue tasks first  
   _Check:_ An API test lists tasks with past, future and no due dates and checks the order

### Tests

**Database**

- **D1.** After migration 0007, tasks have a nullable due_date and existing tasks keep a null due date _(criterion 1)_

**Unit**

- **U1.** TaskValidator accepts a missing dueDate and an ISO date, and rejects a date that isn't ISO _(criterion 1)_

**API**

- **A1.** POST and PATCH /tasks store and return dueDate, with and without one _(criterion 1)_
- **A2.** GET /tasks with past, future and no due dates lists overdue tasks first _(criterion 2)_  
  _Replaces:_ 'GET /tasks lists tasks newest first'

_Layers with no tests:_

- UI: No client code in this change
- Journey: No user flow changes without client code

### Risks

- Existing API clients ignore the new field; ordering of GET /tasks changes for everyone

### ❓ Questions before I build

1. Should a due date in the past be rejected when a task is created, or allowed?
2. Should completed tasks that are past their due date still count as overdue?

_Reply in one comment that starts with `/plan` followed by your answers; the plan is updated from them._
