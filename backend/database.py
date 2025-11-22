# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\database.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# IMPORTANTE: Cole aqui a URL de conexão do seu NOVO banco de dados do Render
DATABASE_URL = "postgresql://ritmistas_db_i51m_user:azPnGzAVPSzM7bSc9O1lRtPypVrJY03H@dpg-d4h1epumcj7s73boa78g-a/ritmistas_db_i51m" 

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