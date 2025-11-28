from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
import logging

logger = logging.getLogger(__name__)

# --- CORREÇÃO: URL DIRETA (SEM OS.GETENV ERRADO) ---
# Isso garante que ele vai conectar no Render e não no local.
DATABASE_URL = "postgresql://ritmistas_db_r733_user:F9yMNPivBXlE94LeLfrRuxZTS8UkBi85@dpg-d4kul549c44c73f78bag-a/ritmistas_db_r733"

# Fallback de segurança apenas se a string acima estiver vazia (o que não vai acontecer)
if not DATABASE_URL:
    logger.warning("DATABASE_URL não definido — usando fallback sqlite local (./dev.db)")
    DATABASE_URL = "sqlite:///./dev.db"

# Corrige o prefixo para versões novas do SQLAlchemy (postgres:// -> postgresql://)
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# O Render exige conexão segura (SSL), então forçamos aqui se for Postgres
if DATABASE_URL.startswith("postgresql://") and "sslmode" not in DATABASE_URL:
    if "?" in DATABASE_URL:
        DATABASE_URL = DATABASE_URL + "&sslmode=require"
    else:
        DATABASE_URL = DATABASE_URL + "?sslmode=require"

# Configuração da Engine
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # pool_pre_ping ajuda a manter a conexão ativa no Render
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()