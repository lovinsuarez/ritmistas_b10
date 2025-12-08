import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

load_dotenv()

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD")

def send_email(to_address, subject, body):
    try:
        msg = MIMEMultipart()
        msg['From'] = EMAIL_ADDRESS
        msg['To'] = to_address
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.send_message(msg)
        print(f"Email sent to {to_address}")

    except Exception as e:
        print(f"Failed to send email to {to_address}: {e}")

def createRecoverCode(length=6):
    import random
    import string
    characters = string.ascii_uppercase + string.digits
    return ''.join(random.choice(characters) for _ in range(length))
        
def send_recovery_email(to_address):
    code = createRecoverCode()
    subject = "Código de Recuperação de Senha"
    body = f"Seu código de recuperação é: {code}"
    send_email(to_address, subject, body)
    return code
        
if __name__ == "__main__":
    recipient = "iago.mjos@gmail.com"
    subject = "Test Email"
    body = "This is a test email sent from the Python email module."
    send_email(recipient, subject, body)