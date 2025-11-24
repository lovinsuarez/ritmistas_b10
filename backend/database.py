from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Substitua pela URL do seu NOVO banco de dados no Render
# Ex: postgresql://user:pass@host/dbname
DATABASE_URL = "postgresql://ritmistas_db_a5cw_user:TG48FkQwEsC6fAWNDS8UtuDrAa5LEroa@dpg-d4ido0vpm1nc73fov6fg-a/ritmistas_db_a5cw"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()