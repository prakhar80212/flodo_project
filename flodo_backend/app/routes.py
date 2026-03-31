import asyncio
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timedelta

from .database import get_db
from .models import Task
from .schemas import TaskCreate, TaskUpdate, TaskResponse, TaskReorder

router = APIRouter()


# ── GET /tasks ────────────────────────────────────────────────────────────────
# Returns all tasks. Supports ?search=keyword and ?status=To-Do filtering.
@router.get("/tasks", response_model=list[TaskResponse])
def get_tasks(
    search: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Task)

    # Filter by title if search param provided
    if search:
        query = query.filter(Task.title.ilike(f"%{search}%"))

    # Filter by status if status param provided
    if status and status != "All":
        query = query.filter(Task.status == status)

    # Always return in user-defined position order
    tasks = query.order_by(Task.position).all()
    return tasks


# ── POST /tasks ───────────────────────────────────────────────────────────────
# Creates a new task. Simulates 2-second processing delay.
@router.post("/tasks", response_model=TaskResponse)
async def create_task(task_data: TaskCreate, db: Session = Depends(get_db)):

    # Assignment requirement: simulate 2-second delay
    await asyncio.sleep(2)

    # Find what the next position should be
    max_position = db.query(Task).count()

    new_task = Task(
        title=task_data.title,
        description=task_data.description,
        due_date=task_data.due_date,
        status=task_data.status,
        blocked_by_id=task_data.blocked_by_id,
        is_recurring=task_data.is_recurring,
        recurrence_type=task_data.recurrence_type,
        position=max_position,  # new tasks go to the end
    )

    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task


# ── PUT /tasks/{task_id} ──────────────────────────────────────────────────────
# Updates an existing task. Also handles recurring task logic here.
@router.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: int,
    task_data: TaskUpdate,
    db: Session = Depends(get_db)
):
    # Assignment requirement: simulate 2-second delay
    await asyncio.sleep(2)

    # Find the task or return 404
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Check if status is being changed to "Done"
    being_marked_done = (
        task_data.status == "Done" and task.status != "Done"
    )

    # Update only the fields that were sent
    update_fields = task_data.model_dump(exclude_unset=True)
    for field, value in update_fields.items():
        setattr(task, field, value)

    task.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(task)

    # ── Stretch goal: Recurring task logic ────────────────────────────────────
    # If this task is recurring AND just got marked Done,
    # automatically create a duplicate with the next due date
    if being_marked_done and task.is_recurring and task.due_date:
        try:
            current_due = datetime.strptime(task.due_date, "%Y-%m-%d")
            if task.recurrence_type == "Daily":
                next_due = current_due + timedelta(days=1)
            elif task.recurrence_type == "Weekly":
                next_due = current_due + timedelta(weeks=1)
            else:
                next_due = None

            if next_due:
                max_position = db.query(Task).count()
                duplicate = Task(
                    title=task.title,
                    description=task.description,
                    due_date=next_due.strftime("%Y-%m-%d"),
                    status="To-Do",          # reset to To-Do
                    blocked_by_id=None,      # fresh task, no blocker
                    is_recurring=True,
                    recurrence_type=task.recurrence_type,
                    position=max_position,
                )
                db.add(duplicate)
                db.commit()
        except ValueError:
            pass  # if date parsing fails, skip silently

    return task


# ── DELETE /tasks/{task_id} ───────────────────────────────────────────────────
# Deletes a task. Also clears blocked_by references pointing to this task.
@router.delete("/tasks/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # If any other task was blocked by this one, clear that reference
    # so we don't have dangling foreign keys
    db.query(Task).filter(Task.blocked_by_id == task_id).update(
        {"blocked_by_id": None}
    )

    db.delete(task)
    db.commit()
    return {"message": "Task deleted successfully"}


# ── PATCH /tasks/reorder ──────────────────────────────────────────────────────
# Stretch goal: saves the new drag-and-drop order to the database
# Flutter sends: [{"id": 3, "position": 0}, {"id": 1, "position": 1}, ...]
@router.patch("/tasks/reorder")
def reorder_tasks(
    reorder_data: list[TaskReorder],
    db: Session = Depends(get_db)
):
    for item in reorder_data:
        db.query(Task).filter(Task.id == item.id).update(
            {"position": item.position}
        )
    db.commit()
    return {"message": "Order saved"}