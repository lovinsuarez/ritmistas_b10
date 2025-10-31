# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\database.py

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# IMPORTANTE: Substitua pela sua URL de conexão externa do Render.com
# Ela se parece com: "postgres://usuario:senha@host.com/banco_de_dados"
DATABASE_URL = "postgresql://ritmistas_b10_user:th553Bsn2QpXuleVOKKnmzCb2ZSFlo1F@dpg-d4203sodl3ps73e8j4j0-a.oregon-postgres.render.com/ritmistas_b10" 

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