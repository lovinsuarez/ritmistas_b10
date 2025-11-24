from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Substitua pela URL do seu NOVO banco de dados no Render
# Ex: postgresql://user:pass@host/dbname
DATABASE_URL = "postgresql://ritmistas_db_9t5m_user:xq4GQM17ffTaMDtTfkKUjw9xsIbNfRql@dpg-d4idb7vgi27c73ea0hdg-a/ritmistas_db_9t5m"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()