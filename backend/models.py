# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\models.py

import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Enum, ForeignKey, UniqueConstraint, UUID
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from database import Base # Importa a Base do nosso arquivo database.py

# Define os ENUMs (tipos especiais) que o PostgreSQL usará
class UserRole(enum.Enum):
    admin = "admin"
    user = "user"

class ActivityType(enum.Enum):
    online = "online"
    presencial = "presencial"

class CodeType(enum.Enum):
    general = "general"
    unique = "unique"

# Modelo da Tabela 'Sectors' (Setores/Grupos)
class Sector(Base):
    __tablename__ = "sectors"
    
    sector_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    invite_code = Column(UUID(as_uuid=True), unique=True, default=uuid.uuid4)
    
    # Relacionamentos (o que este setor possui)
    users = relationship("User", back_populates="sector")
    activities = relationship("Activity", back_populates="sector")
    redeem_codes = relationship("RedeemCode", back_populates="sector")

# Modelo da Tabela 'Users' (Usuários)
class User(Base):
    __tablename__ = "users"
    
    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), unique=True, index=True, nullable=False)
    username = Column(String(50), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.user)
    
    sector_id = Column(Integer, ForeignKey("sectors.sector_id"), nullable=False)
    
    # Relacionamentos (a quem este usuário pertence)
    sector = relationship("Sector", back_populates="users")
    checkins = relationship("CheckIn", back_populates="user")
    created_activities = relationship("Activity", back_populates="creator")
    created_codes = relationship("RedeemCode", back_populates="creator", foreign_keys="[RedeemCode.created_by]")
    assigned_codes = relationship("RedeemCode", back_populates="assigned_user", foreign_keys="[RedeemCode.assigned_user_id]")
    general_redemptions = relationship("GeneralCodeRedemption", back_populates="user")

# Modelo da Tabela 'Activities' (Eventos/Atividades)
class Activity(Base):
    __tablename__ = "activities"
    
    activity_id = Column(Integer, primary_key=True, index=True)
    title = Column(String(150), nullable=False)
    description = Column(String, nullable=True)
    type = Column(Enum(ActivityType), nullable=False)
    address = Column(String(255), nullable=True) # Só para presenciais
    activity_date = Column(DateTime, nullable=False)
    points_value = Column(Integer, nullable=False, default=10) # Pontos por presença
    
    sector_id = Column(Integer, ForeignKey("sectors.sector_id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False) # ID do Admin
    
    sector = relationship("Sector", back_populates="activities")
    creator = relationship("User", back_populates="created_activities")
    checkins = relationship("CheckIn", back_populates="activity")

# Modelo da Tabela 'CheckIns' (Presenças)
class CheckIn(Base):
    __tablename__ = "checkins"
    
    checkin_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    activity_id = Column(Integer, ForeignKey("activities.activity_id"), nullable=False)
    timestamp = Column(DateTime, server_default=func.now())
    
    user = relationship("User", back_populates="checkins")
    activity = relationship("Activity", back_populates="checkins")
    
    __table_args__ = (UniqueConstraint('user_id', 'activity_id', name='_user_activity_uc'),)

# Modelo da Tabela 'RedeemCodes' (Códigos de Resgate)
class RedeemCode(Base):
    __tablename__ = "redeem_codes"
    
    code_id = Column(Integer, primary_key=True, index=True)
    code_string = Column(String(50), unique=True, index=True, nullable=False)
    points_value = Column(Integer, nullable=False, default=10)
    type = Column(Enum(CodeType), nullable=False)
    is_redeemed = Column(Boolean, default=False)
    general_redemptions = relationship("GeneralCodeRedemption", back_populates="code")

    sector_id = Column(Integer, ForeignKey("sectors.sector_id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False) # Admin
    assigned_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True) # Para tipo 'unique'

    sector = relationship("Sector", back_populates="redeem_codes")
    creator = relationship("User", back_populates="created_codes", foreign_keys=[created_by])
    assigned_user = relationship("User", back_populates="assigned_codes", foreign_keys=[assigned_user_id])
    general_redemptions = relationship("GeneralCodeRedemption", back_populates="code")

# Modelo da Tabela 'GeneralCodeRedemptions' (Resgates de Códigos Gerais)
class GeneralCodeRedemption(Base):
    __tablename__ = "general_code_redemptions"
    
    redemption_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    code_id = Column(Integer, ForeignKey("redeem_codes.code_id"), nullable=False)
    timestamp = Column(DateTime, server_default=func.now())
    
    user = relationship("User", back_populates="general_redemptions")
    code = relationship("RedeemCode", back_populates="general_redemptions")
    
    __table_args__ = (UniqueConstraint('user_id', 'code_id', name='_user_code_uc'),)