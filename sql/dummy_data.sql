-- ============================================================
-- Task Management API - Dummy Data
-- Run after schema.sql
-- ============================================================

USE task_management;

-- ------------------------------------------------------------
-- Employees (5)
-- ------------------------------------------------------------
INSERT INTO employees (name, email) VALUES
('Amit Sharma',   'amit.sharma@example.com'),
('Rahul Kumar',   'rahul.kumar@example.com'),
('Priya Verma',   'priya.verma@example.com'),
('Sneha Reddy',   'sneha.reddy@example.com'),
('Vikram Singh',  'vikram.singh@example.com');

-- ------------------------------------------------------------
-- Groups (2)
-- ------------------------------------------------------------
INSERT INTO `groups` (group_name) VALUES
('Sales Team'),
('Support Team');

-- ------------------------------------------------------------
-- Tasks
-- Employee IDs (in insertion order above): 1=Amit, 2=Rahul, 3=Priya, 4=Sneha, 5=Vikram
-- Group IDs: 1=Sales Team, 2=Support Team
-- ------------------------------------------------------------

-- 1. Parent task, assigned to an employee, pending
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Follow up with customer', 'Call ABC Industries regarding pending payment',
     1, '2026-09-16', NULL, 'Pending', 0, 2, NULL);

-- 2. Parent task, assigned to a group, pending
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Handle new leads from website', 'Distribute and follow up on leads received this week',
     1, '2026-09-20', NULL, 'Pending', 0, NULL, 1);

-- 3. Parent task, assigned to an employee, completed
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Prepare monthly invoice report', 'Generate and send invoice summary for September',
     3, '2026-09-10', '2026-09-09 17:30:00', 'Completed', 0, 4, NULL);

-- 4. Parent task, assigned to a group, in progress
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Resolve customer support tickets', 'Clear pending tickets in the queue older than 2 days',
     2, '2026-09-22', NULL, 'In Progress', 0, NULL, 2);

-- 5. Parent task, assigned to an employee, pending
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Update inventory stock count', 'Reconcile physical stock with system records for Warehouse A',
     5, '2026-09-25', NULL, 'Pending', 0, 3, NULL);

-- 6. Parent task, assigned to a group, completed
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Quarterly sales review', 'Compile Q3 sales numbers and prepare presentation',
     1, '2026-09-05', '2026-09-05 16:00:00', 'Completed', 0, NULL, 1);

-- 7. Parent task, assigned to an employee, cancelled
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Vendor onboarding - XYZ Traders', 'Complete vendor documentation and approval',
     3, '2026-09-12', NULL, 'Cancelled', 0, 5, NULL);

-- 8. Parent task, assigned to an employee, pending
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Prepare HR onboarding kit', 'New joiner documentation for next week intake',
     4, '2026-09-24', NULL, 'Pending', 0, 2, NULL);

-- 9. Parent task, assigned to a group, in progress
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Client escalation - Delta Corp', 'Coordinate response for escalated billing complaint',
     2, '2026-09-21', NULL, 'In Progress', 0, NULL, 2);

-- 10. Parent task, assigned to an employee, completed
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Purchase order approval - Office Supplies', 'Review and approve PO #4521',
     5, '2026-09-08', '2026-09-08 11:15:00', 'Completed', 0, 1, NULL);

-- ------------------------------------------------------------
-- Sub-tasks (parent_task_id != 0)
-- These belong to some of the parent tasks above and should
-- be EXCLUDED from the "view all tasks" API response.
-- ------------------------------------------------------------

-- Sub-task of task 1 (Follow up with customer)
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Draft payment reminder email', 'Prepare email draft for ABC Industries',
     1, '2026-09-15', '2026-09-14 10:00:00', 'Completed', 1, 2, NULL);

-- Sub-task of task 4 (Resolve customer support tickets)
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Escalate ticket #884 to L2 support', 'Ticket requires backend investigation',
     2, '2026-09-21', NULL, 'Pending', 4, 4, NULL);

-- Sub-task of task 5 (Update inventory stock count)
INSERT INTO tasks
    (title, description, created_by, due_date, completed_at, status, parent_task_id, assigned_employee_id, assigned_group_id)
VALUES
    ('Count Warehouse A - Shelf 1 to 10', 'Physical count for first section',
     5, '2026-09-23', NULL, 'In Progress', 5, 3, NULL);
