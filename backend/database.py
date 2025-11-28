from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os

# Use DATABASE_URL da variável de ambiente quando disponível.
# Para desenvolvimento local sem Postgres, o fallback é um SQLite file `./dev.db`.
# Render provisiona DATABASE_URL no formato `postgres://...` — normalizamos para
# `postgresql://` porque SQLAlchemy/psycopg2 esperam esse esquema.
DATABASE_URL = os.getenv("postgresql://ritmistas_db_3u5z_user:e3DTpnLLW4hR4w3QzJa5dfD205Dt5zYp@dpg-d4kcdhc9c44c73es884g-a/ritmistas_db_3u5z", "sqlite:///./dev.db")

# Normaliza esquema "postgres://" para "postgresql://"
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Força sslmode=require quando não especificado (Render exige conexões TLS)
if isinstance(DATABASE_URL, str) and DATABASE_URL.startswith("postgresql://") and "sslmode" not in DATABASE_URL:
    if "?" in DATABASE_URL:
        DATABASE_URL = DATABASE_URL + "&sslmode=require"
    else:
        DATABASE_URL = DATABASE_URL + "?sslmode=require"

if DATABASE_URL.startswith("sqlite"):
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