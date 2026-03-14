from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
import logging

logger = logging.getLogger(__name__)

# --- CONFIGURATION FROM ENVIRONMENT ---
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./dev.db")

# Automatically fix "postgres://" -> "postgresql://" for SQLAlchemy
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Configuration for Engine
engine_args = {}

if DATABASE_URL.startswith("sqlite"):
    engine_args["connect_args"] = {"check_same_thread": False}
else:
    # Production-ready PostgreSQL settings
    engine_args.update({
        "pool_pre_ping": True,
        "pool_size": 20,
        "max_overflow": 10,
    })

engine = create_engine(DATABASE_URL, **engine_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()