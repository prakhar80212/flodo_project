from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routes import router

# Create all database tables on startup
# If tasks.db doesn't exist yet, this creates it
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Flodo Task API", version="1.0.0")

# CORS — without this, Flutter (running on Android emulator at
# 10.0.2.2) cannot make requests to our server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:51195","http://localhost:58465"],   # in production you'd restrict this
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register all our routes under /api prefix
app.include_router(router, prefix="/api")

# Health check — useful to verify server is running
@app.get("/")
def root():
    return {"status": "Flodo API is running"}