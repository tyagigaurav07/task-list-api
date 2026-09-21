# Task List API

A simple task management REST API built with **Rust (Axum) + MySQL (SQLx)**.

This project covers:
- Database schema for employees, groups and tasks
- Dummy data for testing
- A single API endpoint to fetch all **parent tasks** (`parent_task_id = 0`), with the
  creator's name and the assigned employee/group name already resolved

---

## Project structure

```
task-list-api/
├── Cargo.toml
├── .env.example
├── sql/
│   ├── schema.sql        -- creates database + tables
│   └── dummy_data.sql    -- sample employees, groups, tasks
├── src/
│   └── main.rs           -- Axum app + SQLx query + JSON response
└── sample_response.json  -- example output of GET /api/tasks
```

---

## Prerequisites

- Rust (install via [rustup](https://rustup.rs))
- MySQL Server (8.0+ recommended)

---

## Setup

### 1. Create the database and tables

```bash
mysql -u root -p < sql/schema.sql
```

This creates the `task_management` database along with the `employees`, `groups`
and `tasks` tables.

### 2. Load dummy data

```bash
mysql -u root -p < sql/dummy_data.sql
```

This inserts:
- 5 employees
- 2 groups (Sales Team, Support Team)
- 10 parent tasks (mix of employee-assigned / group-assigned, pending / in
  progress / completed / cancelled)
- 3 sub-tasks (`parent_task_id != 0`) to verify the API correctly excludes them

### 3. Create a database user for the app (recommended)

Credentials should never be hard-coded, so create a dedicated MySQL user for
the application instead of using `root`:

```sql
CREATE USER 'taskapp'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON task_management.* TO 'taskapp'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Configure environment variables

Copy the example file and fill in your own credentials:

```bash
cp .env.example .env
```

`.env`:
```
DATABASE_URL=mysql://taskapp:your_password_here@localhost/task_management
```

`.env` is git-ignored, so credentials never get committed.

### 5. Run the project

```bash
cargo run
```

The server starts on:
```
http://127.0.0.1:8080
```

---

## API

### `GET /api/tasks`

Returns all **main/parent tasks** (`parent_task_id = 0`). Sub-tasks are
excluded from this endpoint by design.

**Sample response:**

```json
[
  {
    "task_id": 1,
    "title": "Follow up with customer",
    "task": "Call ABC Industries regarding pending payment",
    "created_by": "Amit Sharma",
    "created_on": "2026-09-21T12:47:11",
    "due_date": "2026-09-16",
    "completed_on": null,
    "status": "Pending",
    "assigned_to": "Rahul Kumar"
  },
  {
    "task_id": 2,
    "title": "Handle new leads from website",
    "task": "Distribute and follow up on leads received this week",
    "created_by": "Amit Sharma",
    "created_on": "2026-09-21T12:47:11",
    "due_date": "2026-09-20",
    "completed_on": null,
    "status": "Pending",
    "assigned_to": "Sales Team"
  }
]
```

Note `assigned_to`: when the task is assigned to an employee, this shows the
employee's name (e.g. "Rahul Kumar"); when assigned to a group, it shows the
group's name (e.g. "Sales Team"). The API resolves this automatically — the
client doesn't need to know which type it is.

A full sample response for all 10 seeded parent tasks is in `sample_response.json`.

---

## Design decisions

### Table design

- **employees**: `employee_id`, `name`, `email`, `created_at`
- **groups**: `group_id`, `group_name`, `created_at`
- **tasks**: all task fields from the spec, plus:
  - `parent_task_id` — self-referencing column on `tasks`. `0` marks a main
    task; any other value is the `task_id` of its parent, making it a
    sub-task.
  - `assigned_employee_id` and `assigned_group_id` — two nullable foreign
    keys, one to `employees` and one to `groups`.

### Employee vs. group assignment

A task is assigned to **either** one employee **or** one group, never both,
never neither. Rather than using a single "polymorphic" column
(`assigned_to_id` + `assigned_to_type`), this uses two real foreign key
columns plus a `CHECK` constraint:

```sql
CONSTRAINT chk_task_assignment CHECK (
    (assigned_employee_id IS NOT NULL AND assigned_group_id IS NULL)
    OR
    (assigned_employee_id IS NULL AND assigned_group_id IS NOT NULL)
)
```

This keeps referential integrity enforced by MySQL itself (real foreign
keys), rather than relying on application code to guarantee it.

### Resolving the creator and assignee's name

The query joins `employees` once for the creator, and joins both
`employees` and `groups` (as `LEFT JOIN`, since only one will match) for
the assignee, then uses `COALESCE()` to pick whichever one is not null:

```sql
SELECT
    ...
    creator.name AS created_by,
    COALESCE(assignee_emp.name, assignee_grp.group_name) AS assigned_to
FROM tasks t
JOIN employees creator
    ON creator.employee_id = t.created_by
LEFT JOIN employees assignee_emp
    ON assignee_emp.employee_id = t.assigned_employee_id
LEFT JOIN `groups` assignee_grp
    ON assignee_grp.group_id = t.assigned_group_id
WHERE t.parent_task_id = 0
```

### Filtering parent tasks only

Simple `WHERE t.parent_task_id = 0` in the same query — no extra round trip
needed.

### Connecting to MySQL from Rust

`sqlx::MySqlPool` is created once at startup from the `DATABASE_URL`
environment variable (loaded via `dotenvy`) and shared across requests
through Axum's `State`. Using a connection pool (rather than opening a new
connection per request) is the standard approach for a web API — it reuses
existing connections instead of paying the connection-setup cost on every
request.

---

## Notes

- No credentials are hard-coded anywhere in the source code — everything
  comes from `DATABASE_URL` in `.env` (see `.env.example`).
- `parent_task_id` uses `0` (not `NULL`) for main tasks, exactly as
  specified in the task description, which also makes the filter query a
  simple equality check.
