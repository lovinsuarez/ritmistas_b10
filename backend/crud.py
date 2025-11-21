# backend/crud.py
from sqlalchemy import func, text
from sqlalchemy.orm import Session
import models, schemas, security
import csv
import io

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

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

def get_sector_by_invite_code(db: Session, invite_code: str):
    try:
        return db.query(models.Sector).filter(models.Sector.invite_code == invite_code).first()
    except:
        return None

def create_user_from_invite(db: Session, user_data: schemas.UserRegister):
    sector = get_sector_by_invite_code(db, invite_code=user_data.invite_code)
    if not sector:
        return None 

    hashed_password = security.get_password_hash(user_data.password)
    db_user = models.User(
        email=user_data.email,
        username=user_data.username,
        hashed_password=hashed_password,
        role=models.UserRole.user,
        status=models.UserStatus.PENDING,
    )
    # Adiciona o usuário ao setor do convite
    db_user.sectors.append(sector)

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# NOVO: Entrar em um novo setor
def join_sector(db: Session, user: models.User, invite_code: str):
    sector = get_sector_by_invite_code(db, invite_code)
    if not sector:
        return "Código inválido."
    
    if sector in user.sectors:
        return "Você já está neste setor."
        
    user.sectors.append(sector)
    db.commit()
    return f"Você entrou no setor {sector.name}!"

# NOVO: Calcular pontos por setor para um usuário
def get_user_points_breakdown(db: Session, user: models.User):
    points_data = []
    total_global = 0

    for sector in user.sectors:
        # Pontos de Checkin neste setor
        checkin_points = db.query(func.sum(models.Activity.points_value))\
            .join(models.CheckIn)\
            .filter(models.CheckIn.user_id == user.user_id, models.Activity.sector_id == sector.sector_id)\
            .scalar() or 0
            
        # Pontos de Códigos neste setor (Gerais e Únicos)
        code_points = db.query(func.sum(models.RedeemCode.points_value))\
            .join(models.GeneralCodeRedemption, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
            .filter(models.GeneralCodeRedemption.user_id == user.user_id, models.RedeemCode.sector_id == sector.sector_id)\
            .scalar() or 0
            
        unique_points = db.query(func.sum(models.RedeemCode.points_value))\
            .filter(models.RedeemCode.assigned_user_id == user.user_id, 
                    models.RedeemCode.sector_id == sector.sector_id,
                    models.RedeemCode.is_redeemed == True)\
            .scalar() or 0

        total_sector = checkin_points + code_points + unique_points
        total_global += total_sector
        
        points_data.append(schemas.UserSectorPoints(
            sector_id=sector.sector_id,
            sector_name=sector.name,
            points=total_sector
        ))
        
    return points_data, total_global

# --- Lógica de Auditoria e Relatórios ---

def generate_audit_csv(db: Session):
    """Gera um CSV com TODAS as transações de pontos para auditoria."""
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Cabeçalho
    writer.writerow(['Data', 'Tipo', 'Usuário (Aluno)', 'Responsável (Líder)', 'Setor', 'Detalhe', 'Pontos'])
    
    # 1. Check-ins (Presença em Eventos)
    checkins = db.query(models.CheckIn, models.Activity, models.User, models.Sector)\
        .join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
        .join(models.User, models.CheckIn.user_id == models.User.user_id)\
        .join(models.Sector, models.Activity.sector_id == models.Sector.sector_id)\
        .all()
        
    for ci, act, usr, sec in checkins:
        # Busca quem criou a atividade
        creator = db.query(models.User).filter(models.User.user_id == act.created_by).first()
        creator_name = creator.username if creator else "Desconhecido"
        
        writer.writerow([
            ci.timestamp, 'CHECK-IN', usr.username, creator_name, sec.name, f"Evento: {act.title}", act.points_value
        ])

    # 2. Códigos Gerais Resgatados
    general_redemptions = db.query(models.GeneralCodeRedemption, models.RedeemCode, models.User, models.Sector)\
        .join(models.RedeemCode, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
        .join(models.User, models.GeneralCodeRedemption.user_id == models.User.user_id)\
        .join(models.Sector, models.RedeemCode.sector_id == models.Sector.sector_id)\
        .all()
        
    for red, code, usr, sec in general_redemptions:
        creator = db.query(models.User).filter(models.User.user_id == code.created_by).first()
        creator_name = creator.username if creator else "Desconhecido"
        
        writer.writerow([
            red.timestamp, 'CÓDIGO GERAL', usr.username, creator_name, sec.name, f"Código: {code.code_string}", code.points_value
        ])

    # 3. Códigos Únicos (Atribuídos)
    unique_codes = db.query(models.RedeemCode, models.User, models.Sector)\
        .join(models.User, models.RedeemCode.assigned_user_id == models.User.user_id)\
        .join(models.Sector, models.RedeemCode.sector_id == models.Sector.sector_id)\
        .filter(models.RedeemCode.type == models.CodeType.unique, models.RedeemCode.is_redeemed == True)\
        .all()
        
    for code, usr, sec in unique_codes:
        creator = db.query(models.User).filter(models.User.user_id == code.created_by).first()
        creator_name = creator.username if creator else "Desconhecido"
        
        writer.writerow([
            "N/A", 'CÓDIGO ÚNICO', usr.username, creator_name, sec.name, f"Código: {code.code_string}", code.points_value
        ])

    return output.getvalue()

# --- Funções Auxiliares Mantidas e Adaptadas ---

def get_sector_ranking(db: Session, sector_id: int):
    # Lógica adaptada para a tabela de associação
    # Busca todos os usuários que pertencem ao setor
    sector = db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
    if not sector: return []
    
    ranking = []
    for user in sector.members:
        if user.status == models.UserStatus.ACTIVE:
            # Reutiliza a lógica de cálculo de pontos, mas filtrando só pra esse setor
            # (Simplificação: Para performance real, isso deveria ser uma query SQL pura, 
            # mas para MVP, o loop funciona)
            checkin_points = db.query(func.sum(models.Activity.points_value))\
                .join(models.CheckIn)\
                .filter(models.CheckIn.user_id == user.user_id, models.Activity.sector_id == sector_id)\
                .scalar() or 0
            
            code_points = db.query(func.sum(models.RedeemCode.points_value))\
                .join(models.GeneralCodeRedemption, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
                .filter(models.GeneralCodeRedemption.user_id == user.user_id, models.RedeemCode.sector_id == sector_id)\
                .scalar() or 0
            
            unique_points = db.query(func.sum(models.RedeemCode.points_value))\
                .filter(models.RedeemCode.assigned_user_id == user.user_id, models.RedeemCode.sector_id == sector_id, models.RedeemCode.is_redeemed == True)\
                .scalar() or 0
            
            total = checkin_points + code_points + unique_points
            ranking.append({"user_id": user.user_id, "username": user.username, "total_points": total})
    
    # Ordena
    ranking.sort(key=lambda x: x['total_points'], reverse=True)
    return ranking

def get_geral_ranking(db: Session):
    # Ranking Global (Soma de tudo)
    users = db.query(models.User).filter(models.User.status == models.UserStatus.ACTIVE, models.User.role != models.UserRole.admin).all()
    ranking = []
    for user in users:
        # Calcula pontos totais em TODOS os setores
        points_data, total = get_user_points_breakdown(db, user)
        ranking.append({"user_id": user.user_id, "username": user.username, "total_points": total})
    
    ranking.sort(key=lambda x: x['total_points'], reverse=True)
    return ranking

def get_code_by_string(db: Session, code_string: str):
    return db.query(models.RedeemCode).filter(models.RedeemCode.code_string == code_string).first()

def create_checkin(db: Session, user: models.User, activity_id: int):
    activity = db.query(models.Activity).filter(models.Activity.activity_id == activity_id).first()
    if not activity: return "Atividade não encontrada."
    
    # Verifica se o usuário pertence ao setor da atividade
    if activity.sector not in user.sectors:
        return "Você não pertence ao setor desta atividade."

    existing = db.query(models.CheckIn).filter(models.CheckIn.user_id==user.user_id, models.CheckIn.activity_id==activity_id).first()
    if existing: return "Check-in já realizado."

    new_checkin = models.CheckIn(user_id=user.user_id, activity_id=activity_id)
    db.add(new_checkin)
    db.commit()
    return f"Check-in realizado! +{activity.points_value} pts"

def create_sector(db: Session, sector_name: str):
    db_sector = models.Sector(name=sector_name)
    db.add(db_sector)
    db.commit()
    db.refresh(db_sector)
    return db_sector

def get_all_sectors(db: Session):
    """Retorna todos os setores."""
    # Simplificamos para evitar erros de transação durante a leitura
    return db.query(models.Sector).all()

def get_liders(db: Session):
    return db.query(models.User).filter(models.User.role == models.UserRole.lider).all()

def get_all_users(db: Session):
    return db.query(models.User).filter(models.User.role == models.UserRole.user).all()

def update_user_role(db: Session, user_to_update: models.User, new_role: models.UserRole):
    """Atualiza o 'role' de um usuário."""
    user_to_update.role = new_role
    
    # Se virou Lider ou Admin, ativa automaticamente
    if new_role in [models.UserRole.lider, models.UserRole.admin]:
        user_to_update.status = models.UserStatus.ACTIVE
        
    db.commit()
    db.refresh(user_to_update)
    return user_to_update

def assign_lider_to_sector(db: Session, lider_id: int, sector_id: int):
    sector = db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
    lider = db.query(models.User).filter(models.User.user_id == lider_id).first()
    
    if sector and lider:
        # Adiciona o lider como membro se não for
        if sector not in lider.sectors:
            lider.sectors.append(sector)
        
        sector.lider_id = lider.user_id
        db.commit()
        return sector
    return None

def get_sector_by_id(db: Session, sector_id: int):
    return db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()

def get_users_by_sector(db: Session, sector_id: int):
    sector = db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
    if not sector: return []
    # Filtra apenas membros ativos
    return [u for u in sector.members if u.status == models.UserStatus.ACTIVE]

def get_pending_users_by_sector(db: Session, sector_id: int):
    sector = db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
    if not sector: return []
    return [u for u in sector.members if u.status == models.UserStatus.PENDING]

def update_user_status(db: Session, user_to_update: models.User, new_status: models.UserStatus):
    user_to_update.status = new_status
    db.commit()
    db.refresh(user_to_update)
    return user_to_update

def delete_user(db: Session, user_to_delete: models.User):
    # Limpa dados dependentes
    db.query(models.GeneralCodeRedemption).filter(models.GeneralCodeRedemption.user_id == user_to_delete.user_id).delete()
    db.query(models.CheckIn).filter(models.CheckIn.user_id == user_to_delete.user_id).delete()
    db.delete(user_to_delete)
    db.commit()
    return True

def create_activity(db: Session, activity_data: schemas.ActivityCreate, creator: models.User):
    new_activity = models.Activity(
        title=activity_data.title,
        description=activity_data.description,
        type=activity_data.type,
        address=activity_data.address,
        activity_date=activity_data.activity_date,
        points_value=activity_data.points_value,
        sector_id=creator.led_sector.sector_id if creator.led_sector else None, # Assume setor liderado
        created_by=creator.user_id
    )
    db.add(new_activity)
    db.commit()
    db.refresh(new_activity)
    return new_activity

def get_activities_by_sector(db: Session, sector_id: int):
    return db.query(models.Activity).filter(models.Activity.sector_id == sector_id).order_by(models.Activity.activity_date.desc()).all()

def get_user_dashboard_details(db: Session, user_id: int, sector_id: int):
    # Simplificado para retornar dados base
    user = get_user_by_id(db, user_id)
    points, total = get_user_points_breakdown(db, user)
    return {
        "user_id": user.user_id,
        "username": user.username,
        "total_points": total,
        "checkins": [], # Pode popular se necessário
        "redeemed_codes": []
    }