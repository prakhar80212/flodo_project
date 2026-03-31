from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# This is the SQLite file that will be created on your disk
# The three slashes mean "relative path" — file appears in flodo_backend/
DATABASE_URL = "sqlite:///./tasks.db"

# create_engine is SQLAlchemy's way of connecting to a database
# check_same_thread=False is required for SQLite when used with FastAPI
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)

# SessionLocal is a factory — every time you call SessionLocal()
# you get a fresh database session (like a temporary connection)
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base is the parent class all our database models will inherit from
Base = declarative_base()

# This is a "dependency" — FastAPI calls this automatically
# for each request to give it a DB session, then closes it after
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()