import enum
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Enum, ForeignKey, UniqueConstraint, UUID, Table
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from database import Base 

# --- ENUMS ---
class UserRole(enum.Enum):
    admin = "0"   # Admin Master
    lider = "1"   # Líder de Setor
    user = "2"    # Usuário Padrão

class UserStatus(enum.Enum):
    PENDING = "PENDING"
    ACTIVE = "ACTIVE"

class ActivityType(enum.Enum):
    online = "online"
    presencial = "presencial"

class CodeType(enum.Enum):
    general = "general"
    unique = "unique"

# --- TABELA DE ASSOCIAÇÃO (Muitos para Muitos) ---
user_sectors = Table(
    'user_sectors', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.user_id')),
    Column('sector_id', Integer, ForeignKey('sectors.sector_id'))
)

# --- INSÍGNIAS ---
class Badge(Base):
    __tablename__ = "badges"
    badge_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    description = Column(String(200))
    icon_url = Column(String(500))
    created_at = Column(DateTime, server_default=func.now())
    awards = relationship("UserBadge", back_populates="badge")

class UserBadge(Base):
    __tablename__ = "user_badges"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    badge_id = Column(Integer, ForeignKey("badges.badge_id"), nullable=False)
    awarded_at = Column(DateTime, server_default=func.now())
    user = relationship("User", back_populates="badges")
    badge = relationship("Badge", back_populates="awards")

# --- MODELOS PRINCIPAIS ---
class Sector(Base):
    __tablename__ = "sectors"
    sector_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    invite_code = Column(UUID(as_uuid=True), unique=True, default=uuid.uuid4)
    
    lider_id = Column(Integer, ForeignKey("users.user_id", use_alter=True, name="fk_sector_lider"), nullable=True)
    lider = relationship("User", foreign_keys=[lider_id], back_populates="led_sector")
    
    members = relationship("User", secondary=user_sectors, back_populates="sectors")
    activities = relationship("Activity", back_populates="sector")
    redeem_codes = relationship("RedeemCode", back_populates="sector")

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), unique=True, index=True, nullable=False)
    username = Column(String(50), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.user)
    status = Column(Enum(UserStatus), nullable=False, default=UserStatus.PENDING)
    
    # Perfil
    nickname = Column(String(50), nullable=True)
    birth_date = Column(DateTime, nullable=True)
    profile_pic = Column(String(500), nullable=True)
    points_budget = Column(Integer, default=0) 
    
    # Relacionamentos
    sectors = relationship("Sector", secondary=user_sectors, back_populates="members")
    led_sector = relationship("Sector", back_populates="lider", foreign_keys="[Sector.lider_id]", uselist=False)
    badges = relationship("UserBadge", back_populates="user")
    
    checkins = relationship("CheckIn", back_populates="user")
    created_activities = relationship("Activity", back_populates="creator")
    created_codes = relationship("RedeemCode", back_populates="creator", foreign_keys="[RedeemCode.created_by]")
    assigned_codes = relationship("RedeemCode", back_populates="assigned_user", foreign_keys="[RedeemCode.assigned_user_id]")
    general_redemptions = relationship("GeneralCodeRedemption", back_populates="user")

class Activity(Base):
    __tablename__ = "activities"
    activity_id = Column(Integer, primary_key=True, index=True)
    title = Column(String(150), nullable=False)
    description = Column(String, nullable=True)
    type = Column(Enum(ActivityType), nullable=False)
    address = Column(String(255), nullable=True) 
    activity_date = Column(DateTime, nullable=False)
    points_value = Column(Integer, nullable=False, default=10) 
    created_at = Column(DateTime, server_default=func.now())
    is_general = Column(Boolean, default=False) 

    sector_id = Column(Integer, ForeignKey("sectors.sector_id"), nullable=True)
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False) 
    
    sector = relationship("Sector", back_populates="activities")
    creator = relationship("User", back_populates="created_activities")
    checkins = relationship("CheckIn", back_populates="activity")

class CheckIn(Base):
    __tablename__ = "checkins"
    checkin_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    activity_id = Column(Integer, ForeignKey("activities.activity_id"), nullable=False)
    timestamp = Column(DateTime, server_default=func.now())
    
    user = relationship("User", back_populates="checkins")
    activity = relationship("Activity", back_populates="checkins")
    __table_args__ = (UniqueConstraint('user_id', 'activity_id', name='_user_activity_uc'),)

class RedeemCode(Base):
    __tablename__ = "redeem_codes"
    code_id = Column(Integer, primary_key=True, index=True)
    code_string = Column(String(50), unique=True, index=True, nullable=False)
    points_value = Column(Integer, nullable=False, default=10)
    type = Column(Enum(CodeType), nullable=False)
    is_redeemed = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    is_general = Column(Boolean, default=False) 

    sector_id = Column(Integer, ForeignKey("sectors.sector_id"), nullable=True)
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False) 
    assigned_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True) 

    sector = relationship("Sector", back_populates="redeem_codes")
    creator = relationship("User", back_populates="created_codes", foreign_keys=[created_by])
    assigned_user = relationship("User", back_populates="assigned_codes", foreign_keys=[assigned_user_id])
    general_redemptions = relationship("GeneralCodeRedemption", back_populates="code")

class GeneralCodeRedemption(Base):
    __tablename__ = "general_code_redemptions"
    redemption_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    code_id = Column(Integer, ForeignKey("redeem_codes.code_id"), nullable=False)
    timestamp = Column(DateTime, server_default=func.now())
    
    user = relationship("User", back_populates="general_redemptions")
    code = relationship("RedeemCode", back_populates="general_redemptions")
    __table_args__ = (UniqueConstraint('user_id', 'code_id', name='_user_code_uc'),)