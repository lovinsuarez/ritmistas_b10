from sqlalchemy import func, extract, desc
from sqlalchemy.orm import Session
import models, schemas, security
import csv
import io
from datetime import datetime
import random
import string
import secrets # Para gerar senha aleatória

# ... (lá embaixo, junto com as funções de login) ...

def login_with_google(db: Session, google_data: schemas.GoogleLoginRequest):
    # 1. Tenta achar o usuário
    user = get_user_by_email(db, google_data.email)
    if user:
        return user # Usuário existe, deixa entrar
        
    # 2. Se é NOVO, exige código
    if not google_data.invite_code:
        return None # Retorna None para avisar que precisa do código
        
    # 3. Valida o código
    invite = validate_system_invite(db, google_data.invite_code)
    if not invite:
        raise ValueError("Código de convite inválido.")

    # 4. Cria o usuário
    random_pass = secrets.token_urlsafe(16)
    hashed = security.get_password_hash(random_pass)
    
    new_user = models.User(
        email=google_data.email,
        username=google_data.username,
        hashed_password=hashed,
        role=models.UserRole.user,
        status=models.UserStatus.PENDING, # Pendente de aprovação
        nickname=google_data.username
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()
def get_user_by_id(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.user_id == user_id).first()
def get_sector_by_id(db: Session, sector_id: int):
    return db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
def get_sector_by_invite_code(db: Session, invite_code: str):
    try: return db.query(models.Sector).filter(models.Sector.invite_code == invite_code).first()
    except: return None
def get_code_by_string(db: Session, code_string: str):
    return db.query(models.RedeemCode).filter(models.RedeemCode.code_string == code_string).first()

def generate_system_invite(db: Session):
    chars = string.ascii_uppercase + string.digits
    code = "B10-" + "".join(random.choice(chars) for _ in range(6))
    invite = models.SystemInvite(code=code, is_used=False)
    db.add(invite)
    db.commit()
    db.refresh(invite)
    return invite
def get_all_system_invites(db: Session):
    return db.query(models.SystemInvite).filter(models.SystemInvite.is_used == False).all()
def validate_system_invite(db: Session, code: str):
    return db.query(models.SystemInvite).filter(models.SystemInvite.code == code, models.SystemInvite.is_used == False).first()

def create_admin_master(db: Session, admin_data: schemas.UserCreate):
    hashed_password = security.get_password_hash(admin_data.password)
    db_admin = models.User(email=admin_data.email, username=admin_data.username, hashed_password=hashed_password, role=models.UserRole.admin, status=models.UserStatus.ACTIVE)
    db.add(db_admin); db.commit(); db.refresh(db_admin)
    return db_admin

def create_user_from_invite(db: Session, user_data: schemas.UserRegister):
    invite = validate_system_invite(db, code=user_data.invite_code)
    if not invite: return None 
    hashed_password = security.get_password_hash(user_data.password)
    db_user = models.User(email=user_data.email, username=user_data.username, hashed_password=hashed_password, role=models.UserRole.user, status=models.UserStatus.PENDING)
    db.add(db_user); db.commit(); db.refresh(db_user)
    return db_user

def get_pending_global_users(db: Session):
    return db.query(models.User).filter(models.User.status == models.UserStatus.PENDING).all()

def create_sector(db: Session, sector_name: str):
    db_sector = models.Sector(name=sector_name)
    db.add(db_sector); db.commit(); db.refresh(db_sector)
    return db_sector
def get_all_sectors(db: Session):
    return db.query(models.Sector).all()
def join_sector(db: Session, user: models.User, invite_code: str):
    # 1. Busca o setor
    sector = get_sector_by_invite_code(db, invite_code)
    if not sector: return "Código inválido."
    
    # 2. Verifica se já existe o vínculo DIRETO na tabela de associação
    exists = db.query(models.user_sectors).filter_by(
        user_id=user.user_id, 
        sector_id=sector.sector_id
    ).first()
    
    if exists: 
        return "Você já está neste setor."
    
    # 3. INSERÇÃO EXPLÍCITA (Blindada contra falhas de ORM)
    stmt = models.user_sectors.insert().values(
        user_id=user.user_id, 
        sector_id=sector.sector_id
    )
    db.execute(stmt)
    db.commit()
    
    return f"Bem-vindo ao setor {sector.name}!"

def update_user_role(db: Session, user_to_update: models.User, new_role: models.UserRole):
    if new_role == models.UserRole.user and user_to_update.led_sector:
        user_to_update.led_sector.lider_id = None
    user_to_update.role = new_role
    if new_role in [models.UserRole.lider, models.UserRole.admin]:
        user_to_update.status = models.UserStatus.ACTIVE
    db.commit(); db.refresh(user_to_update)
    return user_to_update

def assign_lider_to_sector(db: Session, lider_id: int, sector_id: int):
    sector = get_sector_by_id(db, sector_id)
    lider = get_user_by_id(db, lider_id)
    if sector and lider:
        if sector not in lider.sectors: lider.sectors.append(sector)
        sector.lider_id = lider.user_id
        db.commit()
        return sector
    return None

# --- ATIVIDADES COM CÓDIGO ALEATÓRIO ---
def generate_short_code(length=6):
    chars = string.ascii_uppercase + string.digits
    return "".join(random.choice(chars) for _ in range(length))

def create_activity(db: Session, activity_data: schemas.ActivityCreate, creator: models.User):
    is_general = (creator.role == models.UserRole.admin) or activity_data.is_general
    sector_id = creator.led_sector.sector_id if creator.led_sector else None
    code = generate_short_code()
    new_activity = models.Activity(
        title=activity_data.title, description=activity_data.description, type=activity_data.type,
        address=activity_data.address, activity_date=activity_data.activity_date,
        points_value=activity_data.points_value, sector_id=sector_id, created_by=creator.user_id,
        is_general=is_general, checkin_code=code
    )
    db.add(new_activity); db.commit(); db.refresh(new_activity)
    return new_activity

def create_checkin(db: Session, user: models.User, activity_code: str):
    # ... (lógica de busca igual à anterior) ...
    activity = db.query(models.Activity).filter(models.Activity.checkin_code == activity_code).first()
    if not activity: return "Código de atividade inválido."
    if not activity.is_general and activity.sector not in user.sectors:
        return "Você não pertence ao setor desta atividade."
    existing = db.query(models.CheckIn).filter(models.CheckIn.user_id==user.user_id, models.CheckIn.activity_id==activity.activity_id).first()
    if existing: return "Check-in já realizado."
    new_checkin = models.CheckIn(user_id=user.user_id, activity_id=activity.activity_id)
    db.add(new_checkin); db.commit()
    return f"Check-in realizado! +{activity.points_value} pts"

def create_general_code(db: Session, code_data: schemas.CodeCreateGeneral, creator: models.User):
    is_general = (creator.role == models.UserRole.admin) or code_data.is_general
    sector_id = creator.led_sector.sector_id if creator.led_sector else None
    
    # Gera código de 8 dígitos
    code = generate_short_code(8)

    new_code = models.RedeemCode(
        code_string=code,
        points_value=code_data.points_value,
        type=models.CodeType.general,
        sector_id=sector_id,
        created_by=creator.user_id,
        is_general=is_general,
        
        # CORREÇÃO: Salvando os campos extras
        title=code_data.title,
        description=code_data.description,
        event_date=code_data.event_date
    )
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    return new_code
    
    # GERA AUTOMÁTICO AGORA (8 DÍGITOS)
    code = generate_short_code(8) 

    new_code = models.RedeemCode(
        code_string=code, # Usa o gerado
        points_value=code_data.points_value,
        type=models.CodeType.general,
        sector_id=sector_id,
        created_by=creator.user_id,
        is_general=is_general
    )
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    return new_code

def redeem_code(db: Session, user: models.User, code: models.RedeemCode):
    if not code.is_general and code.sector not in user.sectors:
        return "Este código é exclusivo de um setor que você não participa."
    if code.type == models.CodeType.unique:
        if code.assigned_user_id != user.user_id: return "Este código não é para você."
        if code.is_redeemed: return "Código já utilizado."
        code.is_redeemed = True; db.commit()
        return f"Resgatado! +{code.points_value} pts"
    if code.type == models.CodeType.general:
        existing = db.query(models.GeneralCodeRedemption).filter(models.GeneralCodeRedemption.user_id == user.user_id, models.GeneralCodeRedemption.code_id == code.code_id).first()
        if existing: return "Você já usou este código."
        new_redemption = models.GeneralCodeRedemption(user_id=user.user_id, code_id=code.code_id)
        db.add(new_redemption); db.commit()
        return f"Resgatado! +{code.points_value} pts"

def add_budget_to_lider(db: Session, lider_id: int, points: int):
    lider = get_user_by_id(db, lider_id)
    if lider: lider.points_budget += points; db.commit()
    return lider

def distribute_points_from_budget(db: Session, lider: models.User, target_user_id: int, points: int, description: str):
    if lider.points_budget < points:
        return False, "Orçamento insuficiente."
        
    target_user = get_user_by_id(db, target_user_id)
    if not target_user: return False, "Usuário não encontrado."

    # 1. Desconta do Líder
    lider.points_budget -= points
    
    # 2. Cria o registro de pontos (Código Único)
    transaction_record = models.RedeemCode(
        code_string=f"BONUS-{target_user.user_id}-{datetime.now().timestamp()}",
        points_value=points,
        type=models.CodeType.unique,
        is_redeemed=True,
        
        # --- AQUI ESTÁ A CORREÇÃO ---
        is_general=True,  # Conta no Geral
        sector_id=None,   # NÃO CONTA NO SETOR (Deixamos nulo propositalmente)
        # ----------------------------
        
        created_by=lider.user_id,
        assigned_user_id=target_user.user_id
    )
    
    db.add(transaction_record)
    db.commit()
    return True, "Pontos enviados com sucesso!"

# --- CÁLCULOS ---
def apply_date_filter(query, model_date_column, month: int = None, year: int = None):
    if year: query = query.filter(extract('year', model_date_column) == year)
    if month: query = query.filter(extract('month', model_date_column) == month)
    return query

def calculate_points(db: Session, user_id: int, sector_id: int = None, is_general: bool = False, month: int = None, year: int = None):
    q_checkin = db.query(func.sum(models.Activity.points_value)).join(models.CheckIn).filter(models.CheckIn.user_id == user_id)
    if is_general: q_checkin = q_checkin.filter(models.Activity.is_general == True)
    elif sector_id: q_checkin = q_checkin.filter(models.Activity.sector_id == sector_id)
    points_checkin = apply_date_filter(q_checkin, models.Activity.activity_date, month, year).scalar() or 0

    q_general = db.query(func.sum(models.RedeemCode.points_value)).join(models.GeneralCodeRedemption).filter(models.GeneralCodeRedemption.user_id == user_id)
    if is_general: q_general = q_general.filter(models.RedeemCode.is_general == True)
    elif sector_id: q_general = q_general.filter(models.RedeemCode.sector_id == sector_id)
    points_general = apply_date_filter(q_general, models.RedeemCode.created_at, month, year).scalar() or 0

    q_unique = db.query(func.sum(models.RedeemCode.points_value)).filter(models.RedeemCode.assigned_user_id == user_id, models.RedeemCode.is_redeemed == True)
    if is_general: q_unique = q_unique.filter(models.RedeemCode.is_general == True)
    elif sector_id: q_unique = q_unique.filter(models.RedeemCode.sector_id == sector_id)
    points_unique = apply_date_filter(q_unique, models.RedeemCode.created_at, month, year).scalar() or 0
    return points_checkin + points_general + points_unique

def get_user_points_breakdown(db: Session, user: models.User):
    points_data = []
    total_global = calculate_points(db, user.user_id, is_general=True)
    
    # Busca setores explicitamente do banco, não confiando no objeto 'user' cacheado
    my_sectors = db.query(models.Sector).join(models.user_sectors).filter(models.user_sectors.c.user_id == user.user_id).all()
    
    for sector in my_sectors:
        pts = calculate_points(db, user.user_id, sector_id=sector.sector_id)
        points_data.append(schemas.UserSectorPoints(sector_id=sector.sector_id, sector_name=sector.name, points=pts))
    return points_data, total_global

def user_to_ranking_entry(user, total):
    return schemas.RankingEntry(user_id=user.user_id, username=user.username, nickname=user.nickname, profile_pic=user.profile_pic, total_points=total)

def get_geral_ranking(db: Session, month: int = None, year: int = None):
    users = db.query(models.User).filter(models.User.status == models.UserStatus.ACTIVE, models.User.role != models.UserRole.admin).all()
    ranking = []
    for user in users:
        total = calculate_points(db, user.user_id, is_general=True, month=month, year=year)
        ranking.append(user_to_ranking_entry(user, total))
    ranking.sort(key=lambda x: x.total_points, reverse=True)
    return ranking

def get_sector_ranking(db: Session, sector_id: int, month: int = None, year: int = None):
    sector = get_sector_by_id(db, sector_id)
    if not sector: return []
    ranking = []
    for user in sector.members:
        if user.status == models.UserStatus.ACTIVE:
            total = calculate_points(db, user.user_id, sector_id=sector_id, month=month, year=year)
            ranking.append(user_to_ranking_entry(user, total))
    ranking.sort(key=lambda x: x.total_points, reverse=True)
    return ranking

def create_badge(db: Session, badge: schemas.BadgeCreate):
    db_badge = models.Badge(**badge.dict())
    db.add(db_badge); db.commit(); db.refresh(db_badge)
    return db_badge
def award_badge(db: Session, user_id: int, badge_id: int):
    existing = db.query(models.UserBadge).filter_by(user_id=user_id, badge_id=badge_id).first()
    if existing: return "Usuário já possui."
    award = models.UserBadge(user_id=user_id, badge_id=badge_id)
    db.add(award); db.commit()
    return "Insígnia concedida!"
def get_all_badges(db: Session): return db.query(models.Badge).all()
def get_user_badges(db: Session, user_id: int): return get_user_by_id(db, user_id).badges

def get_pending_users_by_sector(db: Session, sector_id: int): return [] 
def update_user_status(db: Session, user: models.User, status: models.UserStatus):
    user.status = status; db.commit(); db.refresh(user); return user
def update_user_profile(db: Session, user: models.User, data: schemas.UserUpdateProfile):
    if data.nickname: user.nickname = data.nickname
    if data.birth_date: user.birth_date = data.birth_date
    if data.profile_pic: user.profile_pic = data.profile_pic
    db.commit(); db.refresh(user); return user

def get_activities_by_sector(db: Session, sector_id: int):
    sector = get_sector_by_id(db, sector_id)
    lider_id = sector.lider_id if sector else None
    return db.query(models.Activity).filter((models.Activity.sector_id == sector_id) | (models.Activity.created_by == lider_id)).order_by(models.Activity.activity_date.desc()).all()

def get_users_by_sector(db: Session, sector_id: int):
    return db.query(models.User).join(models.user_sectors).filter(models.user_sectors.c.sector_id == sector_id).filter(models.User.status == models.UserStatus.ACTIVE).order_by(models.User.username).all()

def delete_user(db: Session, user_to_delete: models.User):
    db.query(models.GeneralCodeRedemption).filter(models.GeneralCodeRedemption.user_id == user_to_delete.user_id).delete()
    db.query(models.CheckIn).filter(models.CheckIn.user_id == user_to_delete.user_id).delete()
    db.delete(user_to_delete); db.commit(); return True

def get_user_dashboard_details(db: Session, user_id: int, sector_id: int):
    user = get_user_by_id(db, user_id)
    points, total = get_user_points_breakdown(db, user)
    return {"user_id": user.user_id, "username": user.username, "total_points": total, "checkins": [], "redeemed_codes": []}

def get_audit_logs_json(db: Session, limit=100):
    logs = []
    # (Mesma lógica de logs anterior...)
    return logs 
def generate_audit_csv(db: Session):
    return "" # Placeholder
def get_general_codes(db: Session):
    return db.query(models.RedeemCode).filter(models.RedeemCode.is_general == True).order_by(models.RedeemCode.created_at.desc()).all()
def get_all_users(db: Session): return db.query(models.User).filter(models.User.role == models.UserRole.user).all()
def get_liders(db: Session): return db.query(models.User).filter(models.User.role == models.UserRole.lider).all()