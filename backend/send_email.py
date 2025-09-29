import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import textwrap

# Use environment variables
GMAIL_USER = os.getenv("GMAIL_USER")
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD")

if not GMAIL_USER or not GMAIL_APP_PASSWORD:
    raise ValueError("Missing Gmail credentials in .env file")

# send email
def send_email(recipient, subject, body, attachment=None):
    """
    Send an email with an optional attachment.

    Args:
        recipient (str): Recipient's email address.
        subject (str): Email subject.
        body (str): Email body.
        attachment (str, optional): Path to the attachment file. Defaults to None.
    """
    try:
        # Set up the email
        msg = MIMEMultipart()
        msg['From'] = GMAIL_USER
        msg['To'] = recipient
        msg['Subject'] = subject

        # Attach the body text
        msg.attach(MIMEText(body, 'plain'))

        # Attach a file, if provided
        if attachment:
            with open(attachment, 'rb') as file:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(file.read())
                encoders.encode_base64(part)
                part.add_header(
                    'Content-Disposition',
                    f'attachment; filename={os.path.basename(attachment)}'
                )
                msg.attach(part)

        # Connect to Gmail's SMTP server and send the email
        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()
            server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
            server.sendmail(GMAIL_USER, recipient, msg.as_string())

        print("Email sent successfully!")

    except Exception as e:
        print(f"Failed to send email: {e}")


def send_invoice(invoicemail_data, invoice_file):
    recipient = "mekis.peter@gmail.com"
    subject = f"{invoicemail_data['name']} invoice {invoicemail_data['number']}"
    body = textwrap.dedent(
        f"""Dear Admin,
        Please find attached invoice no. {invoicemail_data["number"]} 
        for {invoicemail_data["name"]}, covering {invoicemail_data["period"]}.
        Best regards,
        AG Server"""
        )
    attachment = invoice_file
    send_email(recipient, subject, body, attachment)
