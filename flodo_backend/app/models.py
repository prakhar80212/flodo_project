from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class Task(Base):
    # This becomes the table name in SQLite
    __tablename__ = "tasks"

    # Primary key — auto-increments for each new task
    id = Column(Integer, primary_key=True, index=True)

    # The 5 required fields from the assignment
    title       = Column(String, nullable=False)
    description = Column(String, nullable=True, default="")
    due_date    = Column(String, nullable=True)   # stored as "YYYY-MM-DD" string
    status      = Column(String, default="To-Do") # "To-Do", "In Progress", "Done"

    # Stretch goal: recurring tasks
    is_recurring      = Column(Boolean, default=False)
    recurrence_type   = Column(String, nullable=True)  # "Daily" or "Weekly"

    # Stretch goal: drag-and-drop order
    # Each task has a position number — we sort by this
    position = Column(Integer, default=0)

    # Blocked By — optional foreign key pointing to another task in the same table
    # This is a "self-referential" relationship
    blocked_by_id = Column(Integer, ForeignKey("tasks.id"), nullable=True)

    # This lets you write task.blocked_by_task to get the blocking Task object
    blocked_by_task = relationship(
        "Task",
        remote_side=[id],   # "id" is the parent side
        foreign_keys=[blocked_by_id]
    )

    # Timestamps — auto-set, never touched manually
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)