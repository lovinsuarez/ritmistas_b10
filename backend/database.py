from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Substitua pela URL do seu NOVO banco de dados no Render
# Ex: postgresql://user:pass@host/dbname
DATABASE_URL = "postgresql://ritmistas_db_3u5z_user:e3DTpnLLW4hR4w3QzJa5dfD205Dt5zYp@dpg-d4kcdhc9c44c73es884g-a/ritmistas_db_3u5z"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()