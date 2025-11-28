from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
import logging

logger = logging.getLogger(__name__)

# --- CONFIGURAÇÃO DA CONEXÃO ---

# URL direta do Render (Hardcoded para garantir que funcione)
# NOTA: Em projetos grandes, idealmente isso fica em variáveis de ambiente, mas aqui garante a conexão.
DATABASE_URL = "postgresql://ritmistas_db_r733_user:F9yMNPivBXlE94LeLfrRuxZTS8UkBi85@dpg-d4kul549c44c73f78bag-a/ritmistas_db_r733"

# Fallback de segurança (caso a string acima seja apagada acidentalmente)
if not DATABASE_URL:
    logger.warning("DATABASE_URL não definido — usando fallback sqlite local (./dev.db)")
    DATABASE_URL = "sqlite:///./dev.db"

# Normaliza esquema "postgres://" para "postgresql://" (Correção para SQLAlchemy moderno)
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Força sslmode=require (Render exige conexões seguras)
# Isso evita erros de "SSL off"
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("postgresql://"):
    if "sslmode" not in DATABASE_URL:
        if "?" in DATABASE_URL:
            DATABASE_URL = DATABASE_URL + "&sslmode=require"
        else:
            DATABASE_URL = DATABASE_URL + "?sslmode=require"

# Criação da Engine
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # Para Postgres (Render): pool_pre_ping evita quedas de conexão ociosa
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()