from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Substitua pela URL do seu NOVO banco de dados no Render
# Ex: postgresql://user:pass@host/dbname
DATABASE_URL = "postgresql://ritmistas_db_h97j_user:gFVPmMRQmUzvQhaNUEofQHhdebrwWH1H@dpg-d4j79lumcj7s73bbj18g-a/ritmistas_db_h97j"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()