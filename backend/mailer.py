import os
import time
import ssl
import smtplib
import logging
from dataclasses import dataclass
from typing import Optional

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.orm import Session

# If you still want engine fallback:
from database import engine

load_dotenv()
logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Small TTL cache for DB envs (performance)
# -----------------------------------------------------------------------------
_ENV_CACHE: dict[str, tuple[float, Optional[str]]] = {}
_ENV_CACHE_TTL_SECONDS = 60  # adjust as you like


def _get_env_from_db(db: Session, name: str) -> Optional[str]:
    row = db.execute(
        text("""
            SELECT value
            FROM envs
            WHERE active = true AND name = :name
            LIMIT 1
        """),
        {"name": name},
    ).fetchone()
    return row[0] if row else None


def _get_env_from_db_cached(db: Session, name: str) -> Optional[str]:
    now = time.time()
    cached = _ENV_CACHE.get(name)

    if cached:
        ts, value = cached
        if now - ts < _ENV_CACHE_TTL_SECONDS:
            return value

    try:
        value = _get_env_from_db(db, name)
    except Exception as e:
        # Don't fail if DB is unreachable; fallback to environment variables
        logger.debug("DB env lookup failed for %s: %s", name, e)
        value = None

    _ENV_CACHE[name] = (now, value)
    return value


def get_env(
    name: str,
    default: Optional[str] = None,
    db: Optional[Session] = None,
) -> Optional[str]:
    """
    DB-first env lookup with safe fallback.

    If db is provided, uses it (preferred).
    If not, tries a short engine connection (keeps your original behavior).
    """
    if db is not None:
        v = _get_env_from_db_cached(db, name)
        if v is not None:
            return v
        return os.getenv(name, default)

    # Engine fallback (kept for compatibility)
    try:
        with engine.connect() as conn:
            row = conn.execute(
                text("""
                    SELECT value
                    FROM envs
                    WHERE active = true AND name = :name
                    LIMIT 1
                """),
                {"name": name},
            ).fetchone()
            if row:
                return row[0]
    except Exception as e:
        logger.debug("Engine env lookup failed for %s: %s", name, e)

    return os.getenv(name, default)


# -----------------------------------------------------------------------------
# Settings (avoid module-import-time config freezing)
# -----------------------------------------------------------------------------
@dataclass(frozen=True)
class EmailSettings:
    smtp_server: str
    smtp_port: int
    email_address: str
    email_password: str
    use_starttls: bool = True

    @staticmethod
    def load(db: Optional[Session] = None) -> "EmailSettings":
        smtp_server = get_env("SMTP_SERVER", "smtp.gmail.com", db=db) or "smtp.gmail.com"
        smtp_port_str = get_env("SMTP_PORT", "587", db=db) or "587"
        email_address = get_env("EMAIL_ADDRESS", "", db=db) or ""
        email_password = get_env("EMAIL_PASSWORD", "", db=db) or ""

        # You can add a flag in envs if you want:
        use_starttls_str = get_env("SMTP_USE_STARTTLS", "true", db=db) or "true"
        use_starttls = use_starttls_str.lower() in ("1", "true", "yes", "y", "on")

        try:
            smtp_port = int(smtp_port_str)
        except ValueError:
            smtp_port = 587

        return EmailSettings(
            smtp_server=smtp_server,
            smtp_port=smtp_port,
            email_address=email_address,
            email_password=email_password,
            use_starttls=use_starttls,
        )


# -----------------------------------------------------------------------------
# Email sending
# -----------------------------------------------------------------------------
class EmailSendError(RuntimeError):
    pass


def send_email(
    to_address: str,
    subject: str,
    body_text: str,
    *,
    body_html: Optional[str] = None,
    timeout: int = 10,
    db: Optional[Session] = None,
) -> bool:
    settings = EmailSettings.load(db=db)

    if not settings.email_address or not settings.email_password:
        # If you want to allow unauthenticated SMTP internally, remove this.
        raise EmailSendError("Missing EMAIL_ADDRESS or EMAIL_PASSWORD configuration.")

    msg = MIMEMultipart("alternative")
    msg["From"] = settings.email_address
    msg["To"] = to_address
    msg["Subject"] = subject

    # Always include plain text
    msg.attach(MIMEText(body_text, "plain", "utf-8"))

    # Optional HTML
    if body_html:
        msg.attach(MIMEText(body_html, "html", "utf-8"))

    context = ssl.create_default_context()

    try:
        with smtplib.SMTP(settings.smtp_server, settings.smtp_port, timeout=timeout) as server:
            server.ehlo()

            if settings.use_starttls:
                server.starttls(context=context)
                server.ehlo()

            server.login(settings.email_address, settings.email_password)
            server.send_message(msg)

        logger.info("Email sent to %s", to_address)
        return True

    except Exception as e:
        logger.exception("Failed to send email to %s", to_address)
        raise EmailSendError(str(e)) from e


# -----------------------------------------------------------------------------
# Recovery code (secure)
# -----------------------------------------------------------------------------
def create_recover_code(length: int = 6) -> str:
    import string
    import secrets

    alphabet = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def send_recovery_email_to_address(
    db: Session,
    to_address: str,
    *,
    length: int = 6,
) -> str:
    """
    Fetch user by email, send code, persist code.
    This keeps the flow simple for your endpoint.
    """
    # Import here to avoid circular imports
    import crud

    user = crud.get_user_by_email(db, to_address)
    if not user:
        raise ValueError("USER_NOT_FOUND")

    code = create_recover_code(length=length)

    subject = "Código de Recuperação de Senha"
    body = f"Seu código de recuperação é: {code}"

    #send_email(to_address, subject, body, db=db)
    print(f"Sending email to {to_address} with code {code}")

    # Persist using your existing CRUD
    crud.add_last_recovery_code(db, user, code)

    return code


def verify_and_consume_recovery_code(
    db: Session,
    user,
    code: str,
) -> bool:
    """
    Optional helper to avoid code reuse.
    """
    if not user.last_recovery_code:
        return False

    ok = secrets_compare(user.last_recovery_code, code)
    if ok:
        user.last_recovery_code = None
        db.commit()
        db.refresh(user)
    return ok


def secrets_compare(a: str, b: str) -> bool:
    """
    Constant-time-ish compare to reduce trivial timing leaks.
    """
    import secrets
    return secrets.compare_digest(a or "", b or "")


# -----------------------------------------------------------------------------
# Manual test
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    # This test uses env/.env variables by default.
    send_email(
        "iago.mjos@gmail.com",
        "Test Email",
        "This is a test email sent from the improved Python module."
    )
