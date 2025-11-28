from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
import logging

logger = logging.getLogger(__name__)

# Lê a variável de ambiente DATABASE_URL corretamente.
# Se não definida, usa um SQLite local para desenvolvimento.
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    logger.warning("DATABASE_URL não definido — usando fallback sqlite local (./dev.db)")
    DATABASE_URL = "sqlite:///./dev.db"

# Normaliza esquema "postgres://" para "postgresql://"
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Força sslmode=require quando não especificado (Render exige conexões TLS)
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("postgresql://") and "sslmode" not in DATABASE_URL:
    if "?" in DATABASE_URL:
        DATABASE_URL = DATABASE_URL + "&sslmode=require"
    else:
        DATABASE_URL = DATABASE_URL + "?sslmode=require"

if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # Para Postgres em produção: habilitamos pool_pre_ping para conexões mais estáveis
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()