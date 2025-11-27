import models
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from datetime import datetime, date
import uuid
from models import UserRole, UserStatus

# Configuração Global
class BaseConfig(BaseModel):
    model_config = ConfigDict(from_attributes=True, use_enum_values=True)

class SystemInvite(BaseConfig):
    code: str
    is_used: bool

class BadgeBase(BaseConfig):
    name: str
    description: str | None = None
    icon_url: str | None = None
class BadgeCreate(BadgeBase): pass
class Badge(BadgeBase):
    badge_id: int
class UserBadge(BaseConfig):
    badge: Badge
    awarded_at: datetime

class Token(BaseConfig):
    access_token: str
    token_type: str
class TokenData(BaseConfig):
    email: str | None = None

class UserBase(BaseConfig):
    email: EmailStr
    username: str
    nickname: str | None = None

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=72)
class UserRegister(UserCreate): 
    invite_code: str 

class UserUpdateProfile(BaseConfig):
    nickname: str | None = None
    birth_date: date | None = None
    profile_pic: str | None = None

class UserSectorPoints(BaseConfig):
    sector_id: int
    sector_name: str
    points: int

class User(UserBase):
    user_id: int
    role: UserRole 
    status: UserStatus
    birth_date: date | None = None
    profile_pic: str | None = None
    points_budget: int = 0
    points_by_sector: list[UserSectorPoints] | None = None
    total_global_points: int | None = None
    badges: list[UserBadge] = []

class Sector(BaseConfig):
    sector_id: int
    name: str
    invite_code: uuid.UUID
    lider_id: int | None

class RedeemCodeRequest(BaseConfig): code_string: str
class JoinSectorRequest(BaseConfig): invite_code: str
class DistributePointsRequest(BaseConfig):
    user_id: int
    points: int
    description: str
class AddBudgetRequest(BaseConfig):
    lider_id: int
    points: int

class CodeCreateGeneral(BaseConfig):
    code_string: str
    points_value: int = 10
    is_general: bool = False
    # NOVOS CAMPOS
    title: str | None = None
    description: str | None = None
class CodeCreateUnique(BaseConfig):
    code_string: str
    points_value: int = 10
    assigned_user_id: int
    is_general: bool = False

# MUDANÇA: Agora o CheckIn recebe um código string, não um ID int
class CheckInRequest(BaseConfig): 
    activity_code: str 

class RankingEntry(BaseConfig):
    user_id: int
    username: str
    nickname: str | None = None
    profile_pic: str | None = None
    total_points: int

class RankingResponse(BaseConfig):
    my_user_id: int
    ranking: list[RankingEntry]

class SectorInfo(BaseConfig):
    name: str
    invite_code: uuid.UUID

class ActivityCreate(BaseConfig):
    title: str = Field(..., max_length=150)
    description: str | None = None
    type: models.ActivityType 
    address: str | None = None 
    activity_date: datetime 
    points_value: int = Field(..., gt=0) 
    is_general: bool = False

class Activity(ActivityCreate): 
    activity_id: int
    created_by: int
    sector_id: int | None
    # CAMPO QUE FALTAVA:
    checkin_code: str | None = None

class UserAdminView(UserBase): 
    user_id: int
    role: UserRole
    status: UserStatus

class CheckInDetail(BaseConfig):
    title: str
    points: int
    date: datetime
    is_general: bool = False

class CodeDetail(BaseConfig):
    code_string: str
    points_value: int
    created_at: datetime
    is_general: bool = False
    # NOVOS CAMPOS
    title: str | None = None
    description: str | None = None

class UserDashboard(BaseConfig):
    user_id: int
    username: str
    total_points: int
    checkins: list[CheckInDetail]
    redeemed_codes: list[CodeDetail]

class UserResponse(User): 
    invite_code: uuid.UUID | None = None 

class AuditLogItem(BaseConfig):
    timestamp: datetime
    type: str 
    user_name: str
    lider_name: str
    sector_name: str
    description: str
    points: int
    is_general: bool