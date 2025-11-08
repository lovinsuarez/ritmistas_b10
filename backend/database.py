# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\database.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Cole aqui a URL de conexão do seu NOVO banco de dados do Render
DATABASE_URL = "postgresql://ritmistas_db_user:1ohdtnoKV0hvdDXfzR85dCUA3fZcPzzB@dpg-d47cvmfdiees7399dt0g-a/ritmistas_db_data" 

# Configuração do motor (Engine) do SQLAlchemy
engine = create_engine(DATABASE_URL)

# Cria uma sessão local (fábrica de sessões)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base declarativa que nossos modelos (tabelas) usarão
Base = declarative_base()

# Função helper para obter uma sessão do banco de dados em cada requisição
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()