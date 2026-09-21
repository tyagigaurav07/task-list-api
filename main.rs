use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::get,
    Router,
};
use chrono::{NaiveDate, NaiveDateTime};
use serde::Serialize;
use sqlx::mysql::{MySqlPool, MySqlPoolOptions};
use std::net::SocketAddr;

// ---------------------------------------------------------------
// Shape of a single row returned by the "view all tasks" API.
// This is the JSON structure the client actually sees.
// ---------------------------------------------------------------
#[derive(Serialize)]
struct TaskResponse {
    task_id: i32,
    title: String,
    task: Option<String>,
    created_by: String,
    created_on: NaiveDateTime,
    due_date: Option<NaiveDate>,
    completed_on: Option<NaiveDateTime>,
    status: String,
    assigned_to: String,
}

// ---------------------------------------------------------------
// This mirrors exactly what the SQL query below selects.
// sqlx::FromRow maps each database column to a struct field
// by name, so this has to line up with the query's column
// aliases.
// ---------------------------------------------------------------
#[derive(sqlx::FromRow)]
struct TaskRow {
    task_id: i32,
    title: String,
    task: Option<String>,
    created_by: String,
    created_on: NaiveDateTime,
    due_date: Option<NaiveDate>,
    completed_on: Option<NaiveDateTime>,
    status: String,
    assigned_to: String,
}

impl From<TaskRow> for TaskResponse {
    fn from(row: TaskRow) -> Self {
        TaskResponse {
            task_id: row.task_id,
            title: row.title,
            task: row.task,
            created_by: row.created_by,
            created_on: row.created_on,
            due_date: row.due_date,
            completed_on: row.completed_on,
            status: row.status,
            assigned_to: row.assigned_to,
        }
    }
}

// Shared application state - just the DB connection pool for now.
#[derive(Clone)]
struct AppState {
    db: MySqlPool,
}

#[tokio::main]
async fn main() {
    // Load DATABASE_URL (and any other config) from a local .env
    // file. This is how we avoid hard-coding credentials in the
    // source code - see .env.example for the expected format.
    dotenvy::dotenv().ok();

    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set (see .env.example)");

    let pool = MySqlPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("failed to connect to MySQL - check DATABASE_URL and that MySQL is running");

    let state = AppState { db: pool };

    let app = Router::new()
        .route("/api/tasks", get(get_all_tasks))
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    println!("Server running on http://{addr}");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

// ---------------------------------------------------------------
// GET /api/tasks
//
// Returns all PARENT tasks only (parent_task_id = 0), with the
// creator's name and the assigned employee/group name resolved
// via joins, so the client never has to make follow-up calls.
// ---------------------------------------------------------------
async fn get_all_tasks(State(state): State<AppState>) -> impl IntoResponse {
    let result = sqlx::query_as::<_, TaskRow>(
        r#"
        SELECT
            t.task_id                                       AS task_id,
            t.title                                          AS title,
            t.description                                    AS task,
            creator.name                                     AS created_by,
            t.created_at                                     AS created_on,
            t.due_date                                       AS due_date,
            t.completed_at                                   AS completed_on,
            t.status                                          AS status,
            COALESCE(assignee_emp.name, assignee_grp.group_name) AS assigned_to
        FROM tasks t
        JOIN employees creator
            ON creator.employee_id = t.created_by
        LEFT JOIN employees assignee_emp
            ON assignee_emp.employee_id = t.assigned_employee_id
        LEFT JOIN `groups` assignee_grp
            ON assignee_grp.group_id = t.assigned_group_id
        WHERE t.parent_task_id = 0
        ORDER BY t.task_id
        "#,
    )
    .fetch_all(&state.db)
    .await;

    match result {
        Ok(rows) => {
            let tasks: Vec<TaskResponse> = rows.into_iter().map(TaskResponse::from).collect();
            (StatusCode::OK, Json(tasks)).into_response()
        }
        Err(err) => {
            eprintln!("database error while fetching tasks: {err}");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({ "error": "failed to fetch tasks" })),
            )
                .into_response()
        }
    }
}
