"""Script para listar e aprovar usuários pendentes (Admin Master local).

Uso:
  # Listar pendentes
  python approve_user.py --list

  # Aprovar por id
  python approve_user.py --id 3

  # Aprovar por email
  python approve_user.py --email user@example.com

Execute dentro do venv na pasta `backend`.
"""
import argparse
from database import SessionLocal
import crud, models


def list_pending(db):
    pend = crud.get_pending_global_users(db)
    if not pend:
        print("Nenhum usuário pendente.")
        return
    for u in pend:
        print(f"id={u.user_id} | email={u.email} | username={u.username} | status={u.status}")


def approve_by_id(db, user_id):
    u = crud.get_user_by_id(db, user_id)
    if not u:
        print("Usuário não encontrado.")
        return
    crud.update_user_status(db, u, models.UserStatus.ACTIVE)
    print(f"Usuário {u.email} aprovado (id={u.user_id}).")


def approve_by_email(db, email):
    u = crud.get_user_by_email(db, email)
    if not u:
        print("Usuário não encontrado.")
        return
    crud.update_user_status(db, u, models.UserStatus.ACTIVE)
    print(f"Usuário {u.email} aprovado (id={u.user_id}).")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true', help='Listar usuários pendentes')
    parser.add_argument('--id', type=int, help='Aprovar usuário por id')
    parser.add_argument('--email', type=str, help='Aprovar usuário por email')
    args = parser.parse_args()

    db = SessionLocal()
    try:
        if args.list:
            list_pending(db)
        elif args.id:
            approve_by_id(db, args.id)
        elif args.email:
            approve_by_email(db, args.email)
        else:
            parser.print_help()
    finally:
        db.close()


if __name__ == '__main__':
    main()
