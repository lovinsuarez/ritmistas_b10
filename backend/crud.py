# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\crud.py
from sqlalchemy import func
from sqlalchemy.orm import Session
import models, schemas, security

def get_user_by_email(db: Session, email: str):
    """Busca um usuário pelo email."""
    return db.query(models.User).filter(models.User.email == email).first()

# ALTERADO: Esta função agora cria o Admin Master, sem vínculo a um setor.
def create_admin_master(db: Session, admin_data: schemas.UserCreate):
    """
    Cria um novo Usuário Admin Master (sem setor).
    """
    
    # 1. Criptografa a senha
    hashed_password = security.get_password_hash(admin_data.password)
        
    # 2. Cria a nova entidade Usuário Admin
    db_admin = models.User(
        email=admin_data.email,
        username=admin_data.username,
        hashed_password=hashed_password,
        role=models.UserRole.admin,
        status=models.UserStatus.ACTIVE, # ALTERADO: Admin Master já nasce ativo
        sector_id=None # Admin Master não tem setor
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

# ALTERADO: O parâmetro 'admin' agora se chama 'creator' (será um Líder)
def create_general_code(db: Session, code_data: schemas.CodeCreateGeneral, creator: models.User):
    new_code = models.RedeemCode(
        code_string=code_data.code_string,
        points_value=code_data.points_value,
        type=models.CodeType.general,
        sector_id=creator.sector_id,
        created_by=creator.user_id
    )
    db.add(new_code)
    db.commit()
    db.refresh(new_code)
    return new_code

# ALTERADO: O parâmetro 'admin' agora se chama 'creator' (será um Líder)
def create_unique_code(db: Session, code_data: schemas.CodeCreateUnique, creator: models.User):
    new_code = models.RedeemCode(
        code_string=code_data.code_string,
        points_value=code_data.points_value,
        type=models.CodeType.unique,
        sector_id=creator.sector_id,
        created_by=creator.user_id,
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
    APENAS PARA USUÁRIOS ATIVOS.
    """

    # 1. Pontos de Check-in
    checkin_points_sq = db.query(
        models.CheckIn.user_id,
        func.sum(models.Activity.points_value).label("total_checkin_points")
    ).join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
     .group_by(models.CheckIn.user_id)\
     .subquery()

    # 2. Pontos de Códigos 'Unique'
    unique_code_points_sq = db.query(
        models.RedeemCode.assigned_user_id.label("user_id"),
        func.sum(models.RedeemCode.points_value).label("total_unique_points")
    ).filter(
        models.RedeemCode.type == models.CodeType.unique,
        models.RedeemCode.is_redeemed == True
    ).group_by(models.RedeemCode.assigned_user_id)\
     .subquery()

    # 3. Pontos de Códigos 'General'
    general_code_points_sq = db.query(
        models.GeneralCodeRedemption.user_id,
        func.sum(models.RedeemCode.points_value).label("total_general_points")
    ).join(models.RedeemCode, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
     .group_by(models.GeneralCodeRedemption.user_id)\
     .subquery()

    # 4. Soma total
    total_points_col = (
        func.coalesce(checkin_points_sq.c.total_checkin_points, 0) +
        func.coalesce(unique_code_points_sq.c.total_unique_points, 0) +
        func.coalesce(general_code_points_sq.c.total_general_points, 0)
    ).label("total_points")

    # 5. Query Principal
    ranking_query = db.query(
        models.User.user_id,
        models.User.username,
        total_points_col 
    ).outerjoin(checkin_points_sq, models.User.user_id == checkin_points_sq.c.user_id)\
    .outerjoin(unique_code_points_sq, models.User.user_id == unique_code_points_sq.c.user_id)\
    .outerjoin(general_code_points_sq, models.User.user_id == general_code_points_sq.c.user_id)\
    .filter(
        models.User.sector_id == sector_id,
        models.User.status == models.UserStatus.ACTIVE # <-- FILTRO NOVO: SÓ ATIVOS
    )\
    .order_by(total_points_col.desc())
        
    return ranking_query.all()

    # 1. Pontos de Check-in (Presença)
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
        status=models.UserStatus.PENDING, # ALTERADO: Usuário nasce pendente
        sector_id=sector.sector_id
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user

def get_sector_by_id(db: Session, sector_id: int):
    """Busca um setor pelo seu ID."""
    return db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()

# ALTERADO: O parâmetro 'admin' agora se chama 'creator' (será um Líder)
def create_activity(db: Session, activity_data: schemas.ActivityCreate, creator: models.User):
    """Cria uma nova atividade associada a um líder e seu setor."""

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
        sector_id=creator.sector_id,
        created_by=creator.user_id
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

# ALTERADO: Esta função agora só retorna usuários ATIVOS
def get_users_by_sector(db: Session, sector_id: int):
    """Busca todos os usuários ATIVOS de um setor."""
    return db.query(models.User).filter(
        models.User.sector_id == sector_id,
        models.User.status == models.UserStatus.ACTIVE # NOVO FILTRO
    ).order_by(models.User.username).all()

def get_user_by_id(db: Session, user_id: int):
    """Busca um usuário pelo seu ID."""
    return db.query(models.User).filter(models.User.user_id == user_id).first()

def update_user_role(db: Session, user_to_update: models.User, new_role: models.UserRole):
    """Atualiza o 'role' de um usuário."""
    
    # Lógica de Rebaixamento: Se virou USER, remove a liderança de qualquer setor
    if new_role == models.UserRole.user:
        sector_led = db.query(models.Sector).filter(models.Sector.lider_id == user_to_update.user_id).first()
        if sector_led:
            sector_led.lider_id = None

    user_to_update.role = new_role
    
    # Lógica de Promoção: Se virou LIDER ou ADMIN, ativa a conta automaticamente
    if new_role in [models.UserRole.lider, models.UserRole.admin]:
        user_to_update.status = models.UserStatus.ACTIVE
        
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

# --- NOVAS FUNÇÕES CRUD ---

# NOVO: Função para o Admin Master criar um setor
def create_sector(db: Session, sector_name: str):
    """Cria um novo Setor."""
    db_sector = models.Sector(name=sector_name)
    db.add(db_sector)
    db.commit()
    db.refresh(db_sector)
    return db_sector

# NOVO: Função para o Admin Master ver todos os setores
def get_all_sectors(db: Session):
    """Retorna todos os setores (com autocorreção de líderes inválidos)."""
    sectors = db.query(models.Sector).all()
    
    dirty = False # Marca se precisamos salvar alterações no banco
    
    for sector in sectors:
        if sector.lider_id:
            # Verifica quem é o líder apontado
            lider = db.query(models.User).filter(models.User.user_id == sector.lider_id).first()
            
            # Se o líder não existe MAIS ou foi rebaixado para 'user'
            if not lider or lider.role != models.UserRole.lider:
                sector.lider_id = None # Remove a liderança inválida
                db.add(sector)
                dirty = True
    
    if dirty:
        db.commit() # Salva as correções
        # Busca a lista limpa novamente
        return db.query(models.Sector).all()
        
    return sectors

# NOVO: Função para o Admin Master ver todos os Líderes
def get_liders(db: Session):
    """Retorna todos os usuários com a função 'lider'."""
    return db.query(models.User).filter(models.User.role == models.UserRole.lider).all()

# NOVO: Função para o Admin Master designar um Líder a um Setor
def assign_lider_to_sector(db: Session, lider_id: int, sector_id: int):
    """Designa um usuário (Líder) como o líder de um setor."""
    
    # 1. Busca o setor
    db_sector = db.query(models.Sector).filter(models.Sector.sector_id == sector_id).first()
    if not db_sector:
        raise HTTPException(status_code=404, detail="Setor não encontrado.")
    
    # 2. Busca o usuário (que deve ser um líder)
    db_lider = db.query(models.User).filter(models.User.user_id == lider_id).first()
    if not db_lider:
        raise HTTPException(status_code=404, detail="Usuário líder não encontrado.")
    if db_lider.role != models.UserRole.lider:
        raise HTTPException(status_code=400, detail="Este usuário não é um Líder.")

    # 3. Atribui o líder ao setor
    db_sector.lider_id = db_lider.user_id
    
    # 4. (Opcional) Move o líder para o setor que ele agora lidera
    db_lider.sector_id = db_sector.sector_id 
    
    db.commit()
    db.refresh(db_sector)
    return db_sector

# NOVO: Função para o Ranking Geral (B10)
def get_geral_ranking(db: Session):
    """
    Calcula o ranking completo de TODOS os usuários ATIVOS.
    """

    # (Subqueries iguais as de cima...)
    checkin_points_sq = db.query(
        models.CheckIn.user_id,
        func.sum(models.Activity.points_value).label("total_checkin_points")
    ).join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
     .group_by(models.CheckIn.user_id)\
     .subquery()

    unique_code_points_sq = db.query(
        models.RedeemCode.assigned_user_id.label("user_id"),
        func.sum(models.RedeemCode.points_value).label("total_unique_points")
    ).filter(
        models.RedeemCode.type == models.CodeType.unique,
        models.RedeemCode.is_redeemed == True
    ).group_by(models.RedeemCode.assigned_user_id)\
     .subquery()

    general_code_points_sq = db.query(
        models.GeneralCodeRedemption.user_id,
        func.sum(models.RedeemCode.points_value).label("total_general_points")
    ).join(models.RedeemCode, models.GeneralCodeRedemption.code_id == models.RedeemCode.code_id)\
     .group_by(models.GeneralCodeRedemption.user_id)\
     .subquery()

    total_points_col = (
        func.coalesce(checkin_points_sq.c.total_checkin_points, 0) +
        func.coalesce(unique_code_points_sq.c.total_unique_points, 0) +
        func.coalesce(general_code_points_sq.c.total_general_points, 0)
    ).label("total_points")

    ranking_query = db.query(
        models.User.user_id,
        models.User.username,
        total_points_col 
    ).outerjoin(checkin_points_sq, models.User.user_id == checkin_points_sq.c.user_id)\
    .outerjoin(unique_code_points_sq, models.User.user_id == unique_code_points_sq.c.user_id)\
    .outerjoin(general_code_points_sq, models.User.user_id == general_code_points_sq.c.user_id)\
    .filter(
        models.User.role != models.UserRole.admin,
        models.User.status == models.UserStatus.ACTIVE # <-- FILTRO NOVO: SÓ ATIVOS
    )\
    .order_by(total_points_col.desc())

    return ranking_query.all()

    # 1. Pontos de Check-in (Presença)
    checkin_points_sq = db.query(
        models.CheckIn.user_id,
        func.sum(models.Activity.points_value).label("total_checkin_points")
    ).join(models.Activity, models.CheckIn.activity_id == models.Activity.activity_id)\
     .group_by(models.CheckIn.user_id)\
     .subquery()

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
    # ALTERADO: Removido o filtro de 'sector_id'
    ranking_query = (
        db.query(
            models.User.user_id,
            models.User.username,
            total_points_col
        )
        .outerjoin(checkin_points_sq, models.User.user_id == checkin_points_sq.c.user_id)
        .outerjoin(unique_code_points_sq, models.User.user_id == unique_code_points_sq.c.user_id)
        .outerjoin(general_code_points_sq, models.User.user_id == general_code_points_sq.c.user_id)
        .filter(models.User.role != models.UserRole.admin)  # Opcional: não incluir Admins no ranking
        .order_by(total_points_col.desc())
    )

    return ranking_query.all()

# NOVO: Função para o Admin Master ver TODOS os usuários
def get_all_users(db: Session):
    """Retorna todos os usuários com a função 'user'."""
    return db.query(models.User).filter(models.User.role == models.UserRole.user).all()

# --- NOVAS FUNÇÕES CRUD PARA APROVAÇÃO ---

# NOVO: Função para o Líder ver os usuários pendentes
def get_pending_users_by_sector(db: Session, sector_id: int):
    """Busca todos os usuários PENDENTES de um setor."""
    return db.query(models.User).filter(
        models.User.sector_id == sector_id,
        models.User.status == models.UserStatus.PENDING
    ).order_by(models.User.username).all()

# NOVO: Função para aprovar/rejeitar um usuário
def update_user_status(db: Session, user_to_update: models.User, new_status: models.UserStatus):
    """Atualiza o 'status' de um usuário (ex: de PENDING para ACTIVE)."""
    user_to_update.status = new_status
    db.commit()
    db.refresh(user_to_update)
    return user_to_update