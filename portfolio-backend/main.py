from fastapi import FastAPI, File, Form, HTTPException, Depends, BackgroundTasks, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
import json
import os
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import secrets

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://portfolio_user:secure_password_123@db:5432/portfolio")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models
class PortfolioData(Base):
    __tablename__ = "portfolio_data"
    
    id = Column(Integer, primary_key=True, index=True)
    section = Column(String, index=True)
    content = Column(Text)
    updated_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

class EmailCommand(Base):
    __tablename__ = "email_commands"
    
    id = Column(Integer, primary_key=True, index=True)
    command_type = Column(String)
    email_from = Column(String)
    data = Column(Text)
    token = Column(String, unique=True)
    confirmed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# Pydantic models
class EmailCommandRequest(BaseModel):
    command: str
    data: Optional[dict] = None
    auth_email: EmailStr

# FastAPI app
app = FastAPI(
    title="Portfolio API",
    description="Professional Portfolio Management System with Email Control",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Email configuration - Read from environment variables
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_EMAIL = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")

# Validate email configuration on startup
if not all([SMTP_EMAIL, SMTP_PASSWORD, ADMIN_EMAIL]):
    print("⚠️  WARNING: Email configuration incomplete. Check .env file!")
    print(f"SMTP_EMAIL: {'✓' if SMTP_EMAIL else '✗'}")
    print(f"SMTP_PASSWORD: {'✓' if SMTP_PASSWORD else '✗'}")
    print(f"ADMIN_EMAIL: {'✓' if ADMIN_EMAIL else '✗'}")

def send_email(to_email: str, subject: str, body: str):
    """Send email notification"""
    if not all([SMTP_EMAIL, SMTP_PASSWORD]):
        print("❌ Email not configured. Skipping email send.")
        return False
    
    try:
        msg = MIMEMultipart()
        msg['From'] = SMTP_EMAIL
        msg['To'] = to_email
        msg['Subject'] = subject
        
        msg.attach(MIMEText(body, 'html'))
        
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SMTP_EMAIL, SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        
        print(f"✅ Email sent to {to_email}: {subject}")
        return True
    except Exception as e:
        print(f"❌ Email error: {e}")
        return False

def generate_confirmation_token():
    """Generate unique confirmation token"""
    return secrets.token_urlsafe(32)

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Portfolio API",
        "status": "running",
        "docs": "/docs",
        "admin_email_configured": ADMIN_EMAIL is not None
    }

@app.get("/api/portfolio/about")
async def get_about(db: Session = Depends(get_db)):
    """Get About Me section"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "about",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="About section not found or hidden")
    
    return json.loads(data.content)

@app.get("/api/portfolio/projects")
async def get_projects(db: Session = Depends(get_db)):
    """Get Projects section"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "projects",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="Projects not found or hidden")
    
    return json.loads(data.content)

@app.get("/api/portfolio/experience")
async def get_experience(db: Session = Depends(get_db)):
    """Get Experience section"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "experience",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="Experience not found or hidden")
    
    return json.loads(data.content)

@app.get("/api/portfolio/contact")
async def get_contact(db: Session = Depends(get_db)):
    """Get Contact information"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "contact",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="Contact info not found or hidden")
    
    return json.loads(data.content)

@app.post("/api/admin/email-command")
async def process_email_command(
    request: EmailCommandRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Process email commands (404, 202, update)"""
    
    # Verify admin email
    if not ADMIN_EMAIL:
        raise HTTPException(status_code=500, detail="Admin email not configured")
    
    if request.auth_email != ADMIN_EMAIL:
        print(f"⚠️  Unauthorized attempt from: {request.auth_email}")
        print(f"Expected: {ADMIN_EMAIL}")
        raise HTTPException(status_code=403, detail=f"Unauthorized email. Expected: {ADMIN_EMAIL}")
    
    if request.command == "404":
        # Set all content to inactive (empty portfolio)
        db.query(PortfolioData).update({"is_active": False})
        db.commit()
        
        background_tasks.add_task(
            send_email,
            request.auth_email,
            "Portfolio Status: 404 Mode Activated",
            "<h2>Portfolio is now in 404 mode</h2><p>All content hidden.</p>"
        )
        
        print("📴 Portfolio set to 404 mode")
        return {"status": "success", "message": "Portfolio set to 404 mode"}
    
    elif request.command == "202":
        # Restart/reset - activate all content
        db.query(PortfolioData).update({"is_active": True})
        db.commit()
        
        background_tasks.add_task(
            send_email,
            request.auth_email,
            "Portfolio Status: 202 Restarted",
            "<h2>Portfolio restarted successfully</h2><p>All content is now active.</p>"
        )
        
        print("✅ Portfolio restarted (202 mode)")
        return {"status": "success", "message": "Portfolio restarted (202)"}
        
    elif request.command == "toggle-status":
        portfolio_data = db.query(PortfolioData).filter(PortfolioData.section == "about").first()
        if not portfolio_data:
            raise HTTPException(status_code=404, detail="About section not found")
            
        data = json.loads(portfolio_data.content)
        current_status = data.get("is_available", True)
        new_status = not current_status
        data["is_available"] = new_status
        
        portfolio_data.content = json.dumps(data)
        portfolio_data.updated_at = datetime.utcnow()
        db.commit()
        
        status_text = "Available for opportunities" if new_status else "Currently unavailable"
        background_tasks.add_task(
            send_email,
            request.auth_email,
            f"Portfolio Status: {status_text}",
            f"<h2>Status Updated</h2><p>Your availability status is now: <strong>{status_text}</strong></p>"
        )
        
        print(f"✅ Portfolio status toggled to: {new_status}")
        return {"status": "success", "message": f"Status toggled to {new_status}"}
    
    elif request.command == "update":
        if not request.data:
            raise HTTPException(status_code=400, detail="Update data required")
        
        # Generate confirmation token
        token = generate_confirmation_token()
        
        # Store pending command
        email_cmd = EmailCommand(
            command_type="update",
            email_from=request.auth_email,
            data=json.dumps(request.data),
            token=token,
            confirmed=False
        )
        db.add(email_cmd)
        db.commit()
        
        # Send confirmation email
        confirmation_url = f"http://localhost:8000/api/admin/confirm/{token}"
        email_body = f"""
        <h2>Confirm Portfolio Update</h2>
        <p>You requested to update your portfolio with the following data:</p>
        <pre>{json.dumps(request.data, indent=2)}</pre>
        <p><a href="{confirmation_url}">Click here to confirm</a></p>
        <p>Or manually visit: <code>{confirmation_url}</code></p>
        <p>Token: <code>{token}</code></p>
        """
        
        background_tasks.add_task(
            send_email,
            request.auth_email,
            "Confirm Portfolio Update",
            email_body
        )
        
        print(f"📧 Update request pending. Token: {token}")
        return {
            "status": "pending",
            "message": "Confirmation email sent",
            "token": token,
            "confirmation_url": confirmation_url
        }
    
    else:
        raise HTTPException(status_code=400, detail="Invalid command. Use: 404, 202, update, or toggle-status")

@app.get("/api/admin/confirm/{token}")
async def confirm_update(token: str, db: Session = Depends(get_db)):
    """Confirm email command"""
    
    email_cmd = db.query(EmailCommand).filter(
        EmailCommand.token == token,
        EmailCommand.confirmed == False
    ).first()
    
    if not email_cmd:
        raise HTTPException(status_code=404, detail="Invalid or expired token")
    
    # Parse and apply update
    data = json.loads(email_cmd.data)
    section = data.get("section")
    content = data.get("content")
    
    if not section or not content:
        raise HTTPException(status_code=400, detail="Invalid update data")
    
    # Update or create portfolio data
    portfolio_data = db.query(PortfolioData).filter(
        PortfolioData.section == section
    ).first()
    
    if portfolio_data:
        portfolio_data.content = json.dumps(content)
        portfolio_data.updated_at = datetime.utcnow()
        portfolio_data.is_active = True
    else:
        new_data = PortfolioData(
            section=section,
            content=json.dumps(content),
            is_active=True
        )
        db.add(new_data)
    
    # Mark command as confirmed
    email_cmd.confirmed = True
    db.commit()
    
    # Send success email
    send_email(
        email_cmd.email_from,
        "Portfolio Updated Successfully",
        f"<h2>Update Confirmed!</h2><p>Section '{section}' has been updated successfully.</p>"
    )
    
    print(f"✅ Portfolio updated: {section}")
    return {
        "status": "success",
        "message": "Portfolio updated successfully",
        "section": section
    }

@app.post("/api/portfolio/contact-form")
async def submit_contact_form(
    name: str,
    email: EmailStr,
    contact: str,
    message: str,
    background_tasks: BackgroundTasks
):
    """Handle contact form submission"""
    
    if not ADMIN_EMAIL:
        raise HTTPException(status_code=500, detail="Admin email not configured")
    
    email_body = f"""
    <h2>New Contact Form Submission</h2>
    <p><strong>Name:</strong> {name}</p>
    <p><strong>Email:</strong> {email}</p>
    <p><strong>Contact:</strong> {contact}</p>
    <p><strong>Message:</strong></p>
    <p>{message}</p>
    """
    
    background_tasks.add_task(
        send_email,
        ADMIN_EMAIL,
        f"Portfolio Contact: {name}",
        email_body
    )
    
    print(f"📬 Contact form submitted by {name}")
    return {"status": "success", "message": "Message sent successfully"}

@app.post("/api/admin/upload-image")
async def upload_image(
    file: UploadFile = File(...),
    auth_email: EmailStr = Form(...),
    db: Session = Depends(get_db)
):
    """Upload image for portfolio"""
    if auth_email != ADMIN_EMAIL:
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    # Save file
    file_path = f"uploaded_images/{file.filename}"
    os.makedirs("uploaded_images", exist_ok=True)
    
    with open(file_path, "wb") as f:
        f.write(await file.read())
    
    return {
        "status": "success",
        "filename": file.filename,
        "url": f"/images/{file.filename}"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "email_configured": all([SMTP_EMAIL, SMTP_PASSWORD, ADMIN_EMAIL])
    }

@app.post("/api/admin/seed")
async def seed_database():
    """Seed the database with testing data"""
    try:
        from init_db import init_database
        init_database()
        return {"status": "success", "message": "Database seeded successfully!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error seeding database: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)