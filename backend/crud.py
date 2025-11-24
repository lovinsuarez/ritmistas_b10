# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\crud.py
from sqlalchemy import func, extract, desc
from sqlalchemy.orm import Session
import models, schemas, security
import csv
import io
from datetime import datetime

# --- LEITURA BÁSICA ---
def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_id(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.user_id == user_id).first()

def get_sector_by_id(db: Session, sector_id: int):
    return db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()

def get_sector_by_invite_code(db: Session, invite_code: str):
    try:
        return db.query(models.Sector).filter(models.Sector.invite_code == invite_code).first()
    except:
        return None

def get_code_by_string(db: Session, code_string: str):
    return db.query(models.RedeemCode).filter(models.RedeemCode.code_string == code_string).first()

# --- CRIAÇÃO DE USUÁRIOS ---
def create_admin_master(db: Session, admin_data: schemas.UserCreate):
    hashed_password = security.get_password_hash(admin_data.password)
    db_admin = models.User(
        email=admin_data.email,
        username=admin_data.username,
        hashed_password=hashed_password,
        role=models.UserRole.admin,
        status=models.UserStatus.ACTIVE,
    )
    db.add(db_admin)
    db.commit()
    db.refresh(db_admin)
    return db_admin

def create_user_from_invite(db: Session, user_data: schemas.UserRegister):
    sector = get_sector_by_invite_code(db, invite_code=user_data.invite_code)
    if not sector: return None 

    hashed_password = security.get_password_hash(user_data.password)
    db_user = models.User(
        email=user_data.email,
        username=user_data.username,
        hashed_password=hashed_password,
        role=models.UserRole.user,
        status=models.UserStatus.PENDING,
    )
    # Adiciona ao setor (N para N)
    db_user.sectors.append(sector)

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# --- GESTÃO DE SETORES E LIDERANÇA ---
def create_sector(db: Session, sector_name: str):
    db_sector = models.Sector(name=sector_name)
    db.add(db_sector)
    db.commit()
    db.refresh(db_sector)
    return db_sector

def get_all_sectors(db: Session):
    return db.query(models.Sector).all()

def join_sector(db: Session, user: models.User, invite_code: str):
    sector = get_sector_by_invite_code(db, invite_code)
    if not sector: return "Código inválido."
    if sector in user.sectors: return "Você já está neste setor."
        
    user.sectors.append(sector)
    db.commit()
    return f"Bem-vindo ao setor {sector.name}!"

def update_user_role(db: Session, user_to_update: models.User, new_role: models.UserRole):
    # Se foi rebaixado para USER, remove liderança
    if new_role == models.UserRole.user and user_to_update.led_sector:
        user_to_update.led_sector.lider_id = None
        
    user_to_update.role = new_role
    # Se virou líder/admin, ativa automaticamente
    if new_role in [models.UserRole.lider, models.UserRole.admin]:
        user_to_update.status = models.UserStatus.ACTIVE
        
    db.commit()
    db.refresh(user_to_update)
    return user_to_update

def assign_lider_to_sector(db: Session, lider_id: int, sector_id: int):
    sector = get_sector_by_id(db, sector_id)
    lider = get_user_by_id(db, lider_id)
    
    if sector and lider:
        if sector not in lider.sectors:
            lider.sectors.append(sector)
        sector.lider_id = lider.user_id
        db.commit()
        return sector
    return None

# --- SISTEMA DE PONTOS E ATIVIDADES ---

def create_activity(db: Session, activity_data: schemas.ActivityCreate, creator: models.User):
    # Se quem criou foi Admin Master, é uma atividade GERAL
    is_general = (creator.role == models.UserRole.admin) or activity_data.is_general
    
    # Se for líder, pega o setor dele. Se for admin, pode ser nulo (geral)
    sector_id = creator.led_sector.sector_id if creator.led_sector else None

    new_activity = models.Activity(
        title=activity_data.title,
        description=activity_data.description,
        type=activity_data.type,
        address=activity_data.address,
        activity_date=activity_data.activity_date,
        points_value=activity_data.points_value,
        sector_id=sector_id, 
        created_by=creator.user_id,
        is_general=is_general # Define se conta pro ranking geral
    )
    db.add(new_activity)
    db.commit()
    db.refresh(new_activity)
    return new_activity

def create_checkin(db: Session, user: models.User, activity_id: int):
    activity = db.query(models.Activity).filter(models.Activity.activity_id == activity_id).first()
    if not activity: return "Atividade não encontrada."
    
    # Regra: Se não é geral, usuário deve estar no setor
    if not activity.is_general and activity.sector not in user.sectors:
        return "Você não pertence ao setor desta atividade."

    existing = db.query(models.CheckIn).filter(models.CheckIn.user_id==user.user_id, models.CheckIn.activity_id==activity_id).first()
    if existing: return "Check-in já realizado."

    new_checkin = models.CheckIn(user_id=user.user_id, activity_id=activity_id)
    db.add(new_checkin)
    db.commit()
    return f"Check-in realizado! +{activity.points_value} pts"

def create_general_code(db: Session, code_data: schemas.CodeCreateGeneral, creator: models.User):
    is_general = (creator.role == models.UserRole.admin) or code_data.is_general
    sector_id = creator.led_sector.sector_id if creator.led_sector else None

    new_code = models.RedeemCode(
        code_string=code_data.code_string,
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
    # Se não for geral, verifica setor
    if not code.is_general and code.sector not in user.sectors:
        return "Este código é exclusivo de um setor que você não participa."

    # Lógica Única
    if code.type == models.CodeType.unique:
        if code.assigned_user_id != user.user_id: return "Este código não é para você."
        if code.is_redeemed: return "Código já utilizado."
        code.is_redeemed = True
        db.commit()
        return f"Resgatado! +{code.points_value} pts"

    # Lógica Geral
    if code.type == models.CodeType.general:
        existing = db.query(models.GeneralCodeRedemption).filter(
            models.GeneralCodeRedemption.user_id == user.user_id,
            models.GeneralCodeRedemption.code_id == code.code_id
        ).first()
        if existing: return "Você já usou este código."
        
        new_redemption = models.GeneralCodeRedemption(user_id=user.user_id, code_id=code.code_id)
        db.add(new_redemption)
        db.commit()
        return f"Resgatado! +{code.points_value} pts"

# --- NOVO: SISTEMA DE ORÇAMENTO (BUDGET) ---

def add_budget_to_lider(db: Session, lider_id: int, points: int):
    """Admin dá pontos para o líder distribuir."""
    lider = get_user_by_id(db, lider_id)
    if lider:
        lider.points_budget += points
        db.commit()
        return lider
    return None

def distribute_points_from_budget(db: Session, lider: models.User, target_user_id: int, points: int, description: str):
    """Líder tira do bolso e dá para o usuário (Isso cria um código único auto-resgatado para registro)."""
    
    if lider.points_budget < points:
        return False, "Orçamento insuficiente."
        
    target_user = get_user_by_id(db, target_user_id)
    if not target_user: return False, "Usuário não encontrado."

    # 1. Desconta do Líder
    lider.points_budget -= points
    
    # 2. Cria o registro (Um código único já resgatado)
    # Importante: Esses pontos contam para o GERAL se o líder quiser? 
    # Regra: Pontos de orçamento do líder contam para o GERAL (conforme pedido).
    transaction_record = models.RedeemCode(
        code_string=f"BONUS-{target_user.user_id}-{datetime.now().timestamp()}", # Código interno
        points_value=points,
        type=models.CodeType.unique,
        is_redeemed=True,
        is_general=True, # <--- CONTA NO GERAL
        sector_id=lider.led_sector.sector_id if lider.led_sector else None,
        created_by=lider.user_id,
        assigned_user_id=target_user.user_id
    )
    
    db.add(transaction_record)
    db.commit()
    return True, "Pontos enviados com sucesso!"

# --- CÁLCULOS DE PONTOS COM FILTRO DE DATA ---

def apply_date_filter(query, model_date_column, month: int = None, year: int = None):
    """Helper para filtrar queries por data."""
    if year:
        query = query.filter(extract('year', model_date_column) == year)
    if month:
        query = query.filter(extract('month', model_date_column) == month)
    return query

def calculate_points(db: Session, user_id: int, sector_id: int = None, is_general: bool = False, month: int = None, year: int = None):
    """Função mestre para calcular pontos."""
    
    # 1. Check-ins
    q_checkin = db.query(func.sum(models.Activity.points_value))\
        .join(models.CheckIn)\
        .filter(models.CheckIn.user_id == user_id)
    
    if is_general:
        q_checkin = q_checkin.filter(models.Activity.is_general == True)
    elif sector_id:
        q_checkin = q_checkin.filter(models.Activity.sector_id == sector_id)
    
    q_checkin = apply_date_filter(q_checkin, models.Activity.activity_date, month, year)
    points_checkin = q_checkin.scalar() or 0

    # 2. Códigos Gerais
    q_general = db.query(func.sum(models.RedeemCode.points_value))\
        .join(models.GeneralCodeRedemption)\
        .filter(models.GeneralCodeRedemption.user_id == user_id)
    
    if is_general:
        q_general = q_general.filter(models.RedeemCode.is_general == True)
    elif sector_id:
        q_general = q_general.filter(models.RedeemCode.sector_id == sector_id)
        
    q_general = apply_date_filter(q_general, models.RedeemCode.created_at, month, year) # Data de criação do código ou resgate? Usando criação para simplificar
    points_general = q_general.scalar() or 0

    # 3. Códigos Únicos (inclui bônus do líder)
    q_unique = db.query(func.sum(models.RedeemCode.points_value))\
        .filter(models.RedeemCode.assigned_user_id == user_id, models.RedeemCode.is_redeemed == True)
        
    if is_general:
        q_unique = q_unique.filter(models.RedeemCode.is_general == True)
    elif sector_id:
        q_unique = q_unique.filter(models.RedeemCode.sector_id == sector_id)

    q_unique = apply_date_filter(q_unique, models.RedeemCode.created_at, month, year)
    points_unique = q_unique.scalar() or 0

    return points_checkin + points_general + points_unique

# --- NOVO: Helper para calcular pontos por setor (para o perfil) ---
def get_user_points_breakdown(db: Session, user: models.User):
    points_data = []
    total_global = calculate_points(db, user.user_id, is_general=True)

    for sector in user.sectors:
        pts = calculate_points(db, user.user_id, sector_id=sector.sector_id)
        points_data.append(schemas.UserSectorPoints(
            sector_id=sector.sector_id,
            sector_name=sector.name,
            points=pts
        ))
        
    return points_data, total_global

# --- RANKINGS ---

def get_geral_ranking(db: Session, month: int = None, year: int = None):
    """Ranking Geral (Apenas pontos marcados como is_general=True)."""
    users = db.query(models.User).filter(models.User.status == models.UserStatus.ACTIVE, models.User.role != models.UserRole.admin).all()
    ranking = []
    for user in users:
        total = calculate_points(db, user.user_id, is_general=True, month=month, year=year)
        ranking.append(user_to_ranking_entry(user, total))
    
    ranking.sort(key=lambda x: x.total_points, reverse=True)
    return ranking

def get_sector_ranking(db: Session, sector_id: int, month: int = None, year: int = None):
    """Ranking do Setor (Pontos específicos daquele setor)."""
    sector = get_sector_by_id(db, sector_id)
    if not sector: return []
    
    ranking = []
    for user in sector.members:
        if user.status == models.UserStatus.ACTIVE:
            total = calculate_points(db, user.user_id, sector_id=sector_id, month=month, year=year)
            ranking.append(user_to_ranking_entry(user, total))

    ranking.sort(key=lambda x: x.total_points, reverse=True)
    return ranking

def user_to_ranking_entry(user, total):
    return schemas.RankingEntry(
        user_id=user.user_id,
        username=user.username,
        nickname=user.nickname,
        profile_pic=user.profile_pic,
        total_points=total
    )

# --- INSÍGNIAS (BADGES) ---
def create_badge(db: Session, badge: schemas.BadgeCreate):
    db_badge = models.Badge(**badge.dict())
    db.add(db_badge)
    db.commit()
    db.refresh(db_badge)
    return db_badge

def award_badge(db: Session, user_id: int, badge_id: int):
    existing = db.query(models.UserBadge).filter_by(user_id=user_id, badge_id=badge_id).first()
    if existing: return "Usuário já possui esta insígnia."
    
    award = models.UserBadge(user_id=user_id, badge_id=badge_id)
    db.add(award)
    db.commit()
    return "Insígnia concedida!"

def get_all_badges(db: Session):
    return db.query(models.Badge).all()

def get_user_badges(db: Session, user_id: int):
    user = get_user_by_id(db, user_id)
    return user.badges

# --- AUDITORIA ---
def generate_audit_csv(db: Session):
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Data', 'Tipo', 'Aluno', 'Lider', 'Setor', 'Detalhe', 'Pontos', 'Geral?'])
    
    # Exemplo simplificado de Checkin (Poderia expandir para outros tipos)
    checkins = db.query(models.CheckIn, models.Activity, models.User, models.Sector)\
        .join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
        .join(models.User, models.CheckIn.user_id == models.User.user_id)\
        .outerjoin(models.Sector, models.Activity.sector_id == models.Sector.sector_id)\
        .all()

    for ci, act, usr, sec in checkins:
        creator = db.query(models.User).filter(models.User.user_id == act.created_by).first()
        creator_name = creator.username if creator else "Desconhecido"
        sec_name = sec.name if sec else "Geral"
        writer.writerow([ci.timestamp, 'CHECK-IN', usr.username, creator_name, sec_name, act.title, act.points_value, act.is_general])
    
    # Aqui você adicionaria as queries para RedeemCode Geral e Único similarmente
        
    return output.getvalue()

def get_audit_logs_json(db: Session, limit=100):
    logs = []
    # 1. Check-ins
    checkins = db.query(models.CheckIn, models.Activity, models.User, models.Sector)\
        .join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
        .join(models.User, models.CheckIn.user_id == models.User.user_id)\
        .outerjoin(models.Sector, models.Activity.sector_id == models.Sector.sector_id)\
        .order_by(models.CheckIn.timestamp.desc())\
        .limit(limit)\
        .all()
        
    for ci, act, usr, sec in checkins:
        creator = db.query(models.User).filter(models.User.user_id == act.created_by).first()
        logs.append({
            "timestamp": ci.timestamp,
            "type": "CHECK-IN",
            "user_name": usr.username,
            "lider_name": creator.username if creator else "?",
            "sector_name": sec.name if sec else "Geral",
            "description": f"Evento: {act.title}",
            "points": act.points_value,
            "is_general": act.is_general
        })
    
    logs.sort(key=lambda x: x['timestamp'], reverse=True)
    return logs[:limit]

# --- APROVAÇÃO ---
def get_pending_users_by_sector(db: Session, sector_id: int):
    sector = get_sector_by_id(db, sector_id)
    if not sector: return []
    return [u for u in sector.members if u.status == models.UserStatus.PENDING]

def update_user_status(db: Session, user: models.User, status: models.UserStatus):
    user.status = status
    db.commit()
    db.refresh(user)
    return user

# --- PERFIL ---
def update_user_profile(db: Session, user: models.User, data: schemas.UserUpdateProfile):
    if data.nickname: user.nickname = data.nickname
    if data.birth_date: user.birth_date = data.birth_date
    if data.profile_pic: user.profile_pic = data.profile_pic
    db.commit()
    db.refresh(user)
    return user

# --- ATIVIDADES ---
def get_activities_by_sector(db: Session, sector_id: int):
    return db.query(models.Activity)\
             .filter(models.Activity.sector_id == sector_id)\
             .order_by(models.Activity.activity_date.desc())\
             .all()

def get_users_by_sector(db: Session, sector_id: int):
    sector = db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
    if not sector: return []
    return [u for u in sector.members if u.status == models.UserStatus.ACTIVE]

def delete_user(db: Session, user_to_delete: models.User):
    db.query(models.GeneralCodeRedemption).filter(models.GeneralCodeRedemption.user_id == user_to_delete.user_id).delete()
    db.query(models.CheckIn).filter(models.CheckIn.user_id == user_to_delete.user_id).delete()
    db.delete(user_to_delete)
    db.commit()
    return True

def get_user_dashboard_details(db: Session, user_id: int, sector_id: int):
    user = get_user_by_id(db, user_id)
    points_data, total = get_user_points_breakdown(db, user)
    
    return {
        "user_id": user.user_id,
        "username": user.username,
        "total_points": total,
        "checkins": [], 
        "redeemed_codes": []
    }