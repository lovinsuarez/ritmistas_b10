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


def drop_legacy_system_invites_table() -> None:
    from sqlalchemy import inspect, text

    try:
        insp = inspect(engine)
        if not insp.has_table("system_invites"):
            return
    except Exception:
        logger.exception("system_invites schema check failed")
        return

    is_sqlite = DATABASE_URL.startswith("sqlite")
    sql = "DROP TABLE IF EXISTS system_invites" if is_sqlite else "DROP TABLE IF EXISTS system_invites CASCADE"
    with engine.begin() as conn:
        conn.execute(text(sql))
    logger.info("Dropped legacy system_invites table")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()