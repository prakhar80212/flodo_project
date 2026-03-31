# Flodo — Task Management App

A full-stack task management application built with Flutter (frontend)
and FastAPI + SQLite (backend), submitted as part of the Flodo AI
take-home assignment.

---

## Track & Stretch Goals

- **Track chosen:** Track A — Full-Stack Builder
- **Stretch goals implemented:** All three
  - Debounced Autocomplete Search (300ms debounce)
  - Recurring Tasks Logic (Daily / Weekly auto-duplication on Done)
  - Persistent Drag-and-Drop Reordering (saved to DB, survives restart)

---

## Tech Stack

| Layer     | Technology                        |
|-----------|-----------------------------------|
| Frontend  | Flutter 3.x + Dart                |
| Backend   | Python 3.11 + FastAPI             |
| Database  | SQLite via SQLAlchemy ORM         |
| State     | Riverpod (FutureProvider + Notifier) |
| HTTP      | Dio                               |
| Storage   | SharedPreferences (draft saving)  |

---

## Project Structure
```
flodo_project/
├── flodo_backend/          ← Python FastAPI server
│   └── app/
│       ├── main.py         ← server entry point + CORS
│       ├── database.py     ← SQLite connection
│       ├── models.py       ← SQLAlchemy Task model
│       ├── schemas.py      ← Pydantic request/response schemas
│       └── routes.py       ← all API endpoints
│
└── flodo_app/              ← Flutter Android app
    └── lib/
        ├── main.dart
        ├── models/         ← Dart Task model
        ├── services/       ← Dio HTTP client
        ├── providers/      ← Riverpod state management
        ├── screens/        ← task list + form screens
        ├── widgets/        ← TaskCard + HighlightedText
        └── utils/          ← constants (base URL, options)
```

---

## Setup Instructions

### Prerequisites
- Python 3.10 or higher
- Flutter SDK 3.x
- Android emulator or physical Android device
- Git

---

### Step 1 — Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/flodo_project.git
cd flodo_project
```

---

### Step 2 — Run the backend
```bash
cd flodo_backend

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# Install dependencies
pip install fastapi uvicorn sqlalchemy pydantic python-multipart

# Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server runs at: `http://localhost:8000`
API docs at: `http://localhost:8000/docs`

The SQLite database file (`tasks.db`) is created automatically on
first run — no manual setup needed.

---

### Step 3 — Run the Flutter app

Open a new terminal:
```bash
cd flodo_app

# Install Flutter packages
flutter pub get

# Run on Android emulator
flutter run
```

> **Note:** The app connects to `http://10.0.2.2:8000/api` by default.
> This is the Android emulator's address for your computer's localhost.
> If running on a physical device, update `baseUrl` in
> `lib/utils/constants.dart` to your computer's local IP address
> (e.g. `http://192.168.1.5:8000/api`).

---

## API Endpoints

| Method | Endpoint            | Description                        |
|--------|---------------------|------------------------------------|
| GET    | /api/tasks          | List all tasks (supports ?search= and ?status=) |
| POST   | /api/tasks          | Create a task (2s simulated delay) |
| PUT    | /api/tasks/{id}     | Update a task (2s simulated delay) |
| DELETE | /api/tasks/{id}     | Delete a task                      |
| PATCH  | /api/tasks/reorder  | Save drag-and-drop order           |

---

## Key Technical Decisions

### Why Riverpod over Provider or BLoC?
Riverpod's `FutureProvider` handles loading, error, and data states
automatically. When `searchQueryProvider` or `statusFilterProvider`
changes, `taskListProvider` refetches without any manual subscription
management. This made the search + filter feature trivial to implement.

### Why Dio over the built-in http package?
Dio gives us timeout configuration, interceptors, and cleaner error
handling out of the box. The 10-second timeout is important here
because POST and PUT have a mandatory 2-second server-side delay.

### Draft saving strategy
Drafts are saved to SharedPreferences inside `dispose()` — this fires
when the user swipes back, minimizes the app, or navigates away.
On screen open, we load the draft before the first build. This means
zero milliseconds of empty-screen flicker.

### Recurring task duplication
The duplication logic lives entirely in the backend (`routes.py`).
When a recurring task is marked Done, the PUT endpoint checks the
recurrence type and creates a new task with the next due date before
returning. The Flutter app just sees the updated task — it has no
knowledge of the duplication logic.

### Drag-and-drop persistence
Every task has a `position` integer column. On reorder, Flutter sends
the full new ordered list as `[{id, position}]` pairs to `PATCH
/api/tasks/reorder`. The backend updates all positions in one
transaction. All GET requests return tasks sorted by `position`.

---

## AI Usage Report

### Tools used
- Claude (Anthropic) — primary assistant throughout development

### Prompts that gave the most helpful code

1. **SQLAlchemy self-referential relationship:**
   > "Write a SQLAlchemy model for a Task that can optionally reference
   > another Task in the same table via a blocked_by_id foreign key.
   > Include the relationship definition."

2. **Riverpod FutureProvider with multiple dependencies:**
   > "Show me a Riverpod FutureProvider that re-runs whenever either
   > of two StateProviders change. Use flutter_riverpod 2.x syntax."

3. **RichText highlight widget:**
   > "Write a Flutter widget that takes a full string and a search
   > query, then renders the matching substring with a highlighted
   > background using RichText and TextSpan."

### When AI gave wrong code and how I fixed it

The initial Riverpod `NotifierProvider` syntax Claude suggested used
the older `StateNotifier` API which is deprecated in Riverpod 2.x.
The `ref.invalidate()` call was also missing — it suggested
`ref.refresh()` which doesn't force a rebuild in all cases.

**Fix:** Checked the official Riverpod 2.x migration docs and updated
to `Notifier` + `NotifierProvider` with `ref.invalidate()`.

---

## Demo Video

[[Google Drive Link — ](https://www.loom.com/share/ffad2b88d67b442095bebbca84d6a465)]

---

## Contact

Submitted by: YOUR NAME
Email: YOUR EMAIL
