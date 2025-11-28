"""Script rápido para gerar um SystemInvite no banco local.

Execute dentro do venv (na pasta `backend`):

    .venv\Scripts\Activate.ps1
    python create_invite.py

Ele imprimirá o código gerado (ex: B10-XXXXXX).
"""
from database import SessionLocal
from crud import generate_system_invite


def main():
    db = SessionLocal()
    try:
        invite = generate_system_invite(db)
        print(invite.code)
    finally:
        db.close()


if __name__ == '__main__':
    main()
