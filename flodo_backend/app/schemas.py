from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# ── What Flutter sends when CREATING a task ──────────────────────────────────
class TaskCreate(BaseModel):
    title:          str
    description:    Optional[str] = ""
    due_date:       Optional[str] = None   # "YYYY-MM-DD"
    status:         Optional[str] = "To-Do"
    blocked_by_id:  Optional[int] = None
    is_recurring:   Optional[bool] = False
    recurrence_type: Optional[str] = None  # "Daily" or "Weekly"
    position:       Optional[int] = 0


# ── What Flutter sends when UPDATING a task ───────────────────────────────────
# Every field is Optional — Flutter only sends fields it wants to change
class TaskUpdate(BaseModel):
    title:           Optional[str] = None
    description:     Optional[str] = None
    due_date:        Optional[str] = None
    status:          Optional[str] = None
    blocked_by_id:   Optional[int] = None
    is_recurring:    Optional[bool] = None
    recurrence_type: Optional[str] = None
    position:        Optional[int] = None


# ── What we send BACK to Flutter ──────────────────────────────────────────────
class TaskResponse(BaseModel):
    id:              int
    title:           str
    description:     Optional[str]
    due_date:        Optional[str]
    status:          str
    blocked_by_id:   Optional[int]
    is_recurring:    bool
    recurrence_type: Optional[str]
    position:        int
    created_at:      datetime
    updated_at:      datetime

    # This tells Pydantic to read from SQLAlchemy objects (not just dicts)
    class Config:
        from_attributes = True


# ── For reorder endpoint — Flutter sends a list of {id, position} pairs ──────
class TaskReorder(BaseModel):
    id:       int
    position: int