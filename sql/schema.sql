-- ============================================================
-- Task Management API - Database Schema
-- Database: MySQL 8.0
-- ============================================================
-- Run this first, then dummy_data.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS task_management;
USE task_management;

-- ------------------------------------------------------------
-- Employees
-- ------------------------------------------------------------
CREATE TABLE employees (
    employee_id   INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Groups (e.g. Sales Team, Support Team)
-- ------------------------------------------------------------
CREATE TABLE `groups` (
    group_id      INT AUTO_INCREMENT PRIMARY KEY,
    group_name    VARCHAR(100) NOT NULL UNIQUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Tasks
--
-- Design notes:
-- - parent_task_id: 0 means this is a main/parent task.
--   Any other value points to another task's task_id, making
--   it a sub-task. This is the self-referencing relationship
--   the API's "view all tasks" filter relies on.
--
-- - Assignment rule (employee OR group, never both, never
--   neither): implemented with two nullable FK columns plus
--   a CHECK constraint that enforces exactly one is set.
--   This keeps the schema fully relational (real FKs, so
--   referential integrity is enforced by MySQL itself)
--   instead of a single polymorphic "assigned_to_id +
--   assigned_to_type" column, which would need application
--   code to guarantee integrity instead of the database.
-- ------------------------------------------------------------
CREATE TABLE tasks (
    task_id               INT AUTO_INCREMENT PRIMARY KEY,
    title                 VARCHAR(200) NOT NULL,
    description           TEXT,
    created_by            INT NOT NULL,
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date              DATE,
    completed_at          DATETIME NULL,
    status                ENUM('Pending', 'In Progress', 'Completed', 'Cancelled')
                              NOT NULL DEFAULT 'Pending',
    parent_task_id        INT NOT NULL DEFAULT 0,

    assigned_employee_id  INT NULL,
    assigned_group_id     INT NULL,

    CONSTRAINT fk_task_created_by
        FOREIGN KEY (created_by) REFERENCES employees(employee_id),

    CONSTRAINT fk_task_assigned_employee
        FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id),

    CONSTRAINT fk_task_assigned_group
        FOREIGN KEY (assigned_group_id) REFERENCES `groups`(group_id),

    -- exactly one of the two assignment columns must be filled
    CONSTRAINT chk_task_assignment CHECK (
        (assigned_employee_id IS NOT NULL AND assigned_group_id IS NULL)
        OR
        (assigned_employee_id IS NULL AND assigned_group_id IS NOT NULL)
    )
);

-- Helpful indexes for the "view all parent tasks" query
CREATE INDEX idx_tasks_parent_task_id ON tasks(parent_task_id);
CREATE INDEX idx_tasks_assigned_employee ON tasks(assigned_employee_id);
CREATE INDEX idx_tasks_assigned_group ON tasks(assigned_group_id);
