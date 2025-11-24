from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Substitua pela URL do seu NOVO banco de dados no Render
# Ex: postgresql://user:pass@host/dbname
DATABASE_URL = "postgresql://ritmistas_db_paos_user:LTISbykM3dXNeK22Wb8IA59ofpqOXZ3T@dpg-d4idvc24d50c7383i4d0-a/ritmistas_db_paos"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()