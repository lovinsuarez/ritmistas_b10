# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\crud.py
from sqlalchemy import func
from sqlalchemy.orm import Session
import models, schemas, security

def get_user_by_email(db: Session, email: str):
    """Busca um usuário pelo email."""
    return db.query(models.User).filter(models.User.email == email).first()

def create_admin_and_sector(db: Session, admin_data: schemas.AdminCreate):
    """
    Cria um novo Setor e um novo Usuário Admin,
    associando um ao outro.
    """
    
    # 1. Criptografa a senha do admin
    hashed_password = security.get_password_hash(admin_data.password)
    
    # 2. Cria a nova entidade Setor
    db_sector = models.Sector(name=admin_data.sector_name)
    
    # Adiciona na sessão (prepara para salvar)
    db.add(db_sector)
    db.commit() # Salva no banco
    db.refresh(db_sector) # Pega o ID gerado pelo banco
    
    # 3. Cria a nova entidade Usuário Admin
    db_admin = models.User(
        email=admin_data.email,
        username=admin_data.username,
        hashed_password=hashed_password,
        role=models.UserRole.admin,
        sector_id=db_sector.sector_id # Associa ao setor que acabamos de criar
    )
    
    db.add(db_admin)
    db.commit()
    db.refresh(db_admin)
    
    return db_admin

def get_code_by_string(db: Session, code_string: str):
    """Busca um código pela string."""
    return db.query(models.RedeemCode).filter(models.RedeemCode.code_string == code_string).first()

def redeem_code(db: Session, user: models.User, code: models.RedeemCode):
    """
    Marca um código como resgatado para um usuário específico.
    Retorna uma mensagem de sucesso ou erro.
    """

    if code.sector_id != user.sector_id:
        return "Código não pertence ao seu setor."

    # Lógica para código ÚNICO
    if code.type == models.CodeType.unique:
        if code.assigned_user_id != user.user_id:
            return "Este código único não é para você."
        if code.is_redeemed:
            return "Este código único já foi resgatado."

        code.is_redeemed = True
        db.commit()
        return f"Código único de {code.points_value} pontos resgatado com sucesso!"

    # Lógica para código GERAL
    if code.type == models.CodeType.general:
        # Verifica se o usuário já resgatou este código geral
        existing_redemption = db.query(models.GeneralCodeRedemption).filter(
            models.GeneralCodeRedemption.user_id == user.user_id,
            models.GeneralCodeRedemption.code_id == code.code_id
        ).first()

        if existing_redemption:
            return "Você já resgatou este código geral."

        # Registra o novo resgate
        new_redemption = models.GeneralCodeRedemption(
            user_id=user.user_id,
            code_id=code.code_id
        )
        db.add(new_redemption)
        db.commit()
        return f"Código geral de {code.points_value} pontos resgatado com sucesso!"

    return "Tipo de código desconhecido."

def create_general_code(db: Session, code_data: schemas.CodeCreateGeneral, admin: models.User):
    new_code = models.RedeemCode(
        code_string=code_data.code_string,
        points_value=code_data.points_value,
        type=models.CodeType.general,
        sector_id=admin.sector_id,
        created_by=admin.user_id
    )
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    return new_code

def create_unique_code(db: Session, code_data: schemas.CodeCreateUnique, admin: models.User):
    new_code = models.RedeemCode(
        code_string=code_data.code_string,
        points_value=code_data.points_value,
        type=models.CodeType.unique,
        sector_id=admin.sector_id,
        created_by=admin.user_id,
        assigned_user_id=code_data.assigned_user_id
    )
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    return new_code

def create_checkin(db: Session, user: models.User, activity_id: int):
    """Registra a presença de um usuário em uma atividade."""

    # 1. Verifica se a atividade existe e pertence ao setor do usuário
    activity = db.query(models.Activity).filter(
        models.Activity.activity_id == activity_id,
        models.Activity.sector_id == user.sector_id
    ).first()

    if not activity:
        return "Atividade não encontrada ou não pertence ao seu setor."

    # 2. Verifica se o usuário já fez check-in
    existing_checkin = db.query(models.CheckIn).filter(
        models.CheckIn.user_id == user.user_id,
        models.CheckIn.activity_id == activity_id
    ).first()

    if existing_checkin:
        return "Você já fez check-in nesta atividade."

    # 3. Cria o novo check-in
    new_checkin = models.CheckIn(
        user_id=user.user_id,
        activity_id=activity_id
    )
    db.add(new_checkin)
    db.commit()

    return f"Check-in realizado com sucesso na atividade '{activity.title}'!"

def get_sector_ranking(db: Session, sector_id: int):
    """
    Calcula o ranking completo para um setor,
    somando pontos de check-ins e códigos resgatados.
    """

    # 1. Pontos de Check-in (Presença)
    # Agrupa os CheckIns por usuário e soma os 'points_value' das atividades
    checkin_points_sq = db.query(
        models.CheckIn.user_id,
        func.sum(models.Activity.points_value).label("total_checkin_points")
    ).join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
     .group_by(models.CheckIn.user_id)\
     .subquery() # Transforma em uma sub-query

    # 2. Pontos de Códigos 'Unique' resgatados
    unique_code_points_sq = db.query(
        models.RedeemCode.assigned_user_id.label("user_id"),
        func.sum(models.RedeemCode.points_value).label("total_unique_points")
    ).filter(
        models.RedeemCode.type == models.CodeType.unique,
        models.RedeemCode.is_redeemed == True
    ).group_by(models.RedeemCode.assigned_user_id)\
     .subquery()

    # 3. Pontos de Códigos 'General' resgatados
    general_code_points_sq = db.query(
        models.GeneralCodeRedemption.user_id,
        func.sum(models.RedeemCode.points_value).label("total_general_points")
    ).join(models.RedeemCode, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
     .group_by(models.GeneralCodeRedemption.user_id)\
     .subquery()

    # 4. Cria a coluna de pontos totais como uma variável
    total_points_col = (
        func.coalesce(checkin_points_sq.c.total_checkin_points, 0) +
        func.coalesce(unique_code_points_sq.c.total_unique_points, 0) +
        func.coalesce(general_code_points_sq.c.total_general_points, 0)
    ).label("total_points")

    # 5. Junta tudo com a tabela de Usuários
    ranking_query = db.query(
        models.User.user_id,
        models.User.username,
        total_points_col  # <-- Usa a variável aqui
    ).outerjoin(checkin_points_sq, models.User.user_id == checkin_points_sq.c.user_id)\
    .outerjoin(unique_code_points_sq, models.User.user_id == unique_code_points_sq.c.user_id)\
    .outerjoin(general_code_points_sq, models.User.user_id == general_code_points_sq.c.user_id)\
    .filter(models.User.sector_id == sector_id)\
    .order_by(total_points_col.desc()) # <-- E usa a variável aqui
        
    return ranking_query.all()

def get_sector_by_invite_code(db: Session, invite_code: str):
    """Busca um setor pelo seu código de convite (UUID)."""
    try:
        return db.query(models.Sector).filter(models.Sector.invite_code == invite_code).first()
    except Exception:
        # Captura erro caso o 'invite_code' não seja um UUID válido
        return None

def create_user_from_invite(db: Session, user_data: schemas.UserRegister):
    """Cria um novo usuário 'normal' usando um código de convite."""

    # 1. Verifica se o setor existe
    sector = get_sector_by_invite_code(db, invite_code=user_data.invite_code)
    if not sector:
        return None # Retorna None se o convite for inválido

    # 2. Criptografa a senha
    hashed_password = security.get_password_hash(user_data.password)

    # 3. Cria o usuário, associando ao setor encontrado
    db_user = models.User(
        email=user_data.email,
        username=user_data.username,
        hashed_password=hashed_password,
        role=models.UserRole.user, # Papel de usuário normal
        sector_id=sector.sector_id
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user

def get_sector_by_id(db: Session, sector_id: int):
    """Busca um setor pelo seu ID."""
    return db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()

def create_activity(db: Session, activity_data: schemas.ActivityCreate, admin: models.User):
    """Cria uma nova atividade associada a um admin e seu setor."""

    # Regra de negócio: endereço obrigatório se for presencial
    if activity_data.type == models.ActivityType.presencial and not activity_data.address:
        raise ValueError("Endereço é obrigatório para eventos presenciais.")

    new_activity = models.Activity(
        title=activity_data.title,
        description=activity_data.description,
        type=activity_data.type,
        address=activity_data.address,
        activity_date=activity_data.activity_date,
        points_value=activity_data.points_value,
        sector_id=admin.sector_id,
        created_by=admin.user_id
    )
    db.add(new_activity)
    db.commit()
    db.refresh(new_activity)
    return new_activity

def get_activities_by_sector(db: Session, sector_id: int):
    """Busca todas as atividades de um setor, das mais novas para as mais antigas."""
    return db.query(models.Activity)\
             .filter(models.Activity.sector_id == sector_id)\
             .order_by(models.Activity.activity_date.desc())\
             .all()

def get_users_by_sector(db: Session, sector_id: int):
    """Busca todos os usuários de um setor."""
    return db.query(models.User).filter(models.User.sector_id == sector_id).order_by(models.User.username).all()

def get_user_by_id(db: Session, user_id: int):
    """Busca um usuário pelo seu ID."""
    return db.query(models.User).filter(models.User.user_id == user_id).first()

def update_user_role(db: Session, user_to_update: models.User, new_role: models.UserRole):
    """Atualiza o 'role' de um usuário."""
    user_to_update.role = new_role
    db.commit()
    db.refresh(user_to_update)
    return user_to_update

def delete_user(db: Session, user_to_delete: models.User):
    """Deleta um usuário do banco."""
    # NOTA: Precisamos deletar os registros dependentes primeiro
    # (checkins, resgates, etc.)
    # Por enquanto, vamos apenas deletar o usuário
    # ATENÇÃO: Configurar 'ON DELETE CASCADE' no DB seria o ideal

    # Deleta resgates gerais
    db.query(models.GeneralCodeRedemption).filter(models.GeneralCodeRedemption.user_id == user_to_delete.user_id).delete()
    # Deleta checkins
    db.query(models.CheckIn).filter(models.CheckIn.user_id == user_to_delete.user_id).delete()

    # Agora deleta o usuário
    db.delete(user_to_delete)
    db.commit()
    return True

def get_user_dashboard_details(db: Session, user_id: int, sector_id: int):
    """Busca todos os detalhes de pontuação de um usuário específico."""

    user = db.query(models.User).filter(models.User.user_id == user_id, models.User.sector_id == sector_id).first()
    if not user:
        return None # Usuário não encontrado no setor

    total_points = 0

    # 1. Busca Check-ins
    checkins_query = db.query(
        models.Activity.title,
        models.Activity.points_value.label("points"),
        models.CheckIn.timestamp.label("date")
    ).join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
     .filter(models.CheckIn.user_id == user_id)\
     .all()

    total_points += sum(c.points for c in checkins_query)

    # 2. Busca Códigos Resgatados (Gerais e Únicos)
    # (Esta query é complexa, une as duas tabelas de resgate)

    # Códigos Gerais
    general_codes_query = db.query(
        models.RedeemCode.code_string,
        models.RedeemCode.points_value.label("points"),
        models.GeneralCodeRedemption.timestamp.label("date")
    ).join(models.RedeemCode, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
     .filter(models.GeneralCodeRedemption.user_id == user_id)\
     .all()

    total_points += sum(c.points for c in general_codes_query)

    # Códigos Únicos
    unique_codes_query = db.query(
        models.RedeemCode.code_string,
        models.RedeemCode.points_value.label("points"),
        func.now().label("date") 
    ).filter(
        models.RedeemCode.assigned_user_id == user_id,
        models.RedeemCode.is_redeemed == True
    ).all()

    total_points += sum(c.points for c in unique_codes_query)

    # Combina as listas de códigos
    all_codes = general_codes_query + unique_codes_query

    dashboard_data = {
        "user_id": user.user_id,
        "username": user.username,
        "total_points": total_points,
        "checkins": checkins_query,
        "redeemed_codes": all_codes
    }

    return dashboard_data