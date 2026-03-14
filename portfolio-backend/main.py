from fastapi import FastAPI, File, Form, HTTPException, Depends, BackgroundTasks, UploadFile, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
import json
import os
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Boolean, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import secrets
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://portfolio_user:secure_password_123@db:5432/portfolio")
engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=300)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# ─────────────────────────────────────────────────────────────────────────────
# Database Models
# ─────────────────────────────────────────────────────────────────────────────

class PortfolioData(Base):
    __tablename__ = "portfolio_data"
    
    id = Column(Integer, primary_key=True, index=True)
    section = Column(String(50), index=True, unique=True)
    content = Column(Text)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)


class EmailCommand(Base):
    __tablename__ = "email_commands"
    
    id = Column(Integer, primary_key=True, index=True)
    command_type = Column(String(50))
    email_from = Column(String(255))
    data = Column(Text)
    token = Column(String(64), unique=True, index=True)
    confirmed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)


class ContactSubmission(Base):
    __tablename__ = "contact_submissions"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(255))
    contact = Column(String(50))
    message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_read = Column(Boolean, default=False)


# Create tables
Base.metadata.create_all(bind=engine)


# ─────────────────────────────────────────────────────────────────────────────
# Pydantic Models
# ─────────────────────────────────────────────────────────────────────────────

class CommandType(str, Enum):
    HIDE_ALL = "404"
    SHOW_ALL = "202"
    TOGGLE_STATUS = "toggle-status"
    UPDATE = "update"


class EmailCommandRequest(BaseModel):
    command: CommandType
    data: Optional[Dict[str, Any]] = None
    auth_email: EmailStr


class ContactFormRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    contact: str = Field(..., min_length=5, max_length=50)
    message: str = Field(..., min_length=10, max_length=2000)


class PortfolioUpdateRequest(BaseModel):
    section: str
    content: Dict[str, Any]


class APIResponse(BaseModel):
    status: str
    message: str
    data: Optional[Dict[str, Any]] = None


# ─────────────────────────────────────────────────────────────────────────────
# FastAPI App
# ─────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Portfolio API",
    description="Professional Portfolio Management System with Email Control",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────────────────────────────────────────────────────
# Dependencies
# ─────────────────────────────────────────────────────────────────────────────

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ─────────────────────────────────────────────────────────────────────────────
# Email Configuration
# ─────────────────────────────────────────────────────────────────────────────

SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_EMAIL = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")

# Log email configuration status
if not all([SMTP_EMAIL, SMTP_PASSWORD, ADMIN_EMAIL]):
    logger.warning("Email configuration incomplete. Check .env file!")
    logger.warning(f"SMTP_EMAIL: {'configured' if SMTP_EMAIL else 'missing'}")
    logger.warning(f"SMTP_PASSWORD: {'configured' if SMTP_PASSWORD else 'missing'}")
    logger.warning(f"ADMIN_EMAIL: {'configured' if ADMIN_EMAIL else 'missing'}")
else:
    logger.info("Email configuration complete")


def send_email(to_email: str, subject: str, body: str) -> bool:
    """Send email notification"""
    if not all([SMTP_EMAIL, SMTP_PASSWORD]):
        logger.warning("Email not configured. Skipping email send.")
        return False
    
    try:
        msg = MIMEMultipart("alternative")
        msg["From"] = SMTP_EMAIL
        msg["To"] = to_email
        msg["Subject"] = subject
        
        # Create HTML email with styling
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #00C6FF 0%, #9333EA 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; }}
                .content {{ background: #1E1E2C; color: #E2E8F0; padding: 20px; border-radius: 0 0 10px 10px; }}
                .button {{ display: inline-block; background: linear-gradient(135deg, #00C6FF, #9333EA); color: white; padding: 12px 24px; text-decoration: none; border-radius: 25px; margin: 10px 0; }}
                pre {{ background: #0F172A; padding: 15px; border-radius: 8px; overflow-x: auto; }}
                code {{ color: #00C6FF; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h2 style="margin:0;">Portfolio Admin</h2>
                </div>
                <div class="content">
                    {body}
                </div>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html_body, "html"))
        
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.send_message(msg)
        
        logger.info(f"Email sent to {to_email}: {subject}")
        return True
    except Exception as e:
        logger.error(f"Email error: {e}")
        return False


def generate_confirmation_token() -> str:
    """Generate unique confirmation token"""
    return secrets.token_urlsafe(32)


# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints - Public
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/", tags=["General"])
async def root():
    """Root endpoint - API information"""
    return {
        "name": "Portfolio API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs",
        "health": "/health",
        "admin_configured": ADMIN_EMAIL is not None
    }


@app.get("/health", tags=["General"])
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint"""
    try:
        # Test database connection
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    
    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "timestamp": datetime.utcnow().isoformat(),
        "database": db_status,
        "email_configured": all([SMTP_EMAIL, SMTP_PASSWORD, ADMIN_EMAIL])
    }


# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints - Portfolio Data
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/api/portfolio/about", tags=["Portfolio"])
async def get_about(db: Session = Depends(get_db)):
    """Get About Me section"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "about",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="About section not found or hidden")
    
    return json.loads(data.content)


@app.get("/api/portfolio/projects", tags=["Portfolio"])
async def get_projects(
    db: Session = Depends(get_db),
    category: Optional[str] = Query(None, description="Filter projects by category")
):
    """Get Projects section with optional category filter"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "projects",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="Projects not found or hidden")
    
    projects = json.loads(data.content)
    
    # Apply category filter if provided
    if category and "projects" in projects:
        projects["projects"] = [
            p for p in projects["projects"]
            if p.get("category", "").lower() == category.lower()
        ]
    
    return projects


@app.get("/api/portfolio/experience", tags=["Portfolio"])
async def get_experience(db: Session = Depends(get_db)):
    """Get Experience section"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "experience",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="Experience not found or hidden")
    
    return json.loads(data.content)


@app.get("/api/portfolio/contact", tags=["Portfolio"])
async def get_contact(db: Session = Depends(get_db)):
    """Get Contact information"""
    data = db.query(PortfolioData).filter(
        PortfolioData.section == "contact",
        PortfolioData.is_active == True
    ).first()
    
    if not data:
        raise HTTPException(status_code=404, detail="Contact info not found or hidden")
    
    return json.loads(data.content)


@app.get("/api/portfolio/all", tags=["Portfolio"])
async def get_all_portfolio(db: Session = Depends(get_db)):
    """Get all portfolio sections in one request"""
    sections = ["about", "projects", "experience", "contact"]
    result = {}
    
    for section in sections:
        data = db.query(PortfolioData).filter(
            PortfolioData.section == section,
            PortfolioData.is_active == True
        ).first()
        
        if data:
            result[section] = json.loads(data.content)
        else:
            result[section] = None
    
    return result


# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints - Contact Form
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/api/portfolio/contact-form", tags=["Contact"], response_model=APIResponse)
async def submit_contact_form(
    request: ContactFormRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Handle contact form submission"""
    
    # Save to database
    submission = ContactSubmission(
        name=request.name,
        email=request.email,
        contact=request.contact,
        message=request.message
    )
    db.add(submission)
    db.commit()
    
    # Send email notification if configured
    if ADMIN_EMAIL:
        email_body = f"""
        <h2>New Contact Form Submission</h2>
        <table style="width:100%; border-collapse: collapse;">
            <tr><td style="padding:8px; border-bottom:1px solid #333;"><strong>Name:</strong></td><td style="padding:8px; border-bottom:1px solid #333;">{request.name}</td></tr>
            <tr><td style="padding:8px; border-bottom:1px solid #333;"><strong>Email:</strong></td><td style="padding:8px; border-bottom:1px solid #333;">{request.email}</td></tr>
            <tr><td style="padding:8px; border-bottom:1px solid #333;"><strong>Contact:</strong></td><td style="padding:8px; border-bottom:1px solid #333;">{request.contact}</td></tr>
        </table>
        <h3>Message:</h3>
        <p style="background:#0F172A; padding:15px; border-radius:8px;">{request.message}</p>
        <p style="color:#94A3B8; font-size:12px;">Received at: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
        """
        
        background_tasks.add_task(
            send_email,
            ADMIN_EMAIL,
            f"Portfolio Contact: {request.name}",
            email_body
        )
    
    logger.info(f"Contact form submitted by {request.name}")
    return APIResponse(
        status="success",
        message="Message sent successfully. We'll get back to you soon!"
    )


# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints - Admin Commands
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/api/admin/email-command", tags=["Admin"], response_model=APIResponse)
async def process_email_command(
    request: EmailCommandRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Process email commands (404, 202, update, toggle-status)"""
    
    # Verify admin email
    if not ADMIN_EMAIL:
        raise HTTPException(status_code=500, detail="Admin email not configured")
    
    if request.auth_email != ADMIN_EMAIL:
        logger.warning(f"Unauthorized attempt from: {request.auth_email}")
        raise HTTPException(status_code=403, detail="Unauthorized email address")
    
    if request.command == CommandType.HIDE_ALL:
        # Set all content to inactive (404 mode)
        db.query(PortfolioData).update({"is_active": False})
        db.commit()
        
        background_tasks.add_task(
            send_email,
            request.auth_email,
            "Portfolio: 404 Mode Activated",
            "<h2>Portfolio Hidden</h2><p>All content is now hidden. Send '202' command to restore.</p>"
        )
        
        logger.info("Portfolio set to 404 mode")
        return APIResponse(status="success", message="Portfolio set to 404 mode - all content hidden")
    
    elif request.command == CommandType.SHOW_ALL:
        # Activate all content (202 mode)
        db.query(PortfolioData).update({"is_active": True})
        db.commit()
        
        background_tasks.add_task(
            send_email,
            request.auth_email,
            "Portfolio: Restored (202)",
            "<h2>Portfolio Restored</h2><p>All content is now visible again.</p>"
        )
        
        logger.info("Portfolio restored (202 mode)")
        return APIResponse(status="success", message="Portfolio restored - all content visible")
    
    elif request.command == CommandType.TOGGLE_STATUS:
        # Toggle availability status
        about_data = db.query(PortfolioData).filter(PortfolioData.section == "about").first()
        if not about_data:
            raise HTTPException(status_code=404, detail="About section not found")
        
        data = json.loads(about_data.content)
        current_status = data.get("is_available", True)
        new_status = not current_status
        data["is_available"] = new_status
        
        about_data.content = json.dumps(data)
        db.commit()
        
        status_text = "Available for opportunities" if new_status else "Currently unavailable"
        background_tasks.add_task(
            send_email,
            request.auth_email,
            f"Portfolio Status: {status_text}",
            f"<h2>Status Updated</h2><p>Your availability is now: <strong>{status_text}</strong></p>"
        )
        
        logger.info(f"Availability toggled to: {new_status}")
        return APIResponse(
            status="success",
            message=f"Status updated to: {status_text}",
            data={"is_available": new_status}
        )
    
    elif request.command == CommandType.UPDATE:
        if not request.data:
            raise HTTPException(status_code=400, detail="Update data required")
        
        # Generate confirmation token
        token = generate_confirmation_token()
        expires_at = datetime.utcnow().replace(hour=datetime.utcnow().hour + 24)
        
        # Store pending command
        email_cmd = EmailCommand(
            command_type="update",
            email_from=request.auth_email,
            data=json.dumps(request.data),
            token=token,
            confirmed=False,
            expires_at=expires_at
        )
        db.add(email_cmd)
        db.commit()
        
        # Send confirmation email
        confirmation_url = f"http://localhost:8000/api/admin/confirm/{token}"
        email_body = f"""
        <h2>Confirm Portfolio Update</h2>
        <p>You requested to update your portfolio:</p>
        <pre>{json.dumps(request.data, indent=2)}</pre>
        <p><a href="{confirmation_url}" class="button">Confirm Update</a></p>
        <p style="color:#94A3B8;">Or copy this link: <code>{confirmation_url}</code></p>
        <p style="color:#94A3B8; font-size:12px;">This link expires in 24 hours.</p>
        """
        
        background_tasks.add_task(
            send_email,
            request.auth_email,
            "Confirm Portfolio Update",
            email_body
        )
        
        logger.info(f"Update request pending. Token: {token[:8]}...")
        return APIResponse(
            status="pending",
            message="Confirmation email sent. Check your inbox.",
            data={"token": token, "confirmation_url": confirmation_url}
        )
    
    raise HTTPException(status_code=400, detail="Invalid command")


@app.get("/api/admin/confirm/{token}", tags=["Admin"])
async def confirm_update(token: str, db: Session = Depends(get_db)):
    """Confirm email command via token"""
    
    email_cmd = db.query(EmailCommand).filter(
        EmailCommand.token == token,
        EmailCommand.confirmed == False
    ).first()
    
    if not email_cmd:
        raise HTTPException(status_code=404, detail="Invalid or expired token")
    
    # Check expiration
    if email_cmd.expires_at and email_cmd.expires_at < datetime.utcnow():
        raise HTTPException(status_code=410, detail="Token has expired")
    
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
        f"<h2>Update Confirmed!</h2><p>Section '<strong>{section}</strong>' has been updated successfully.</p>"
    )
    
    logger.info(f"Portfolio updated: {section}")
    return APIResponse(
        status="success",
        message=f"Portfolio section '{section}' updated successfully"
    )


@app.post("/api/admin/upload-image", tags=["Admin"])
async def upload_image(
    file: UploadFile = File(...),
    auth_email: EmailStr = Form(...)
):
    """Upload image for portfolio"""
    if auth_email != ADMIN_EMAIL:
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Invalid file type. Allowed: JPEG, PNG, GIF, WebP")
    
    # Validate file size (5MB max)
    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large. Max 5MB")
    
    # Save file
    os.makedirs("uploaded_images", exist_ok=True)
    file_path = f"uploaded_images/{file.filename}"
    
    with open(file_path, "wb") as f:
        f.write(contents)
    
    logger.info(f"Image uploaded: {file.filename}")
    return APIResponse(
        status="success",
        message="Image uploaded successfully",
        data={"filename": file.filename, "url": f"/images/{file.filename}"}
    )


@app.get("/images/{filename}", tags=["Assets"])
async def get_image(filename: str):
    """Serve uploaded images"""
    file_path = f"uploaded_images/{filename}"
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(file_path)


# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints - Database Management
# ─────────────────────────────────────────────────────────────────────────────

@app.post("/api/admin/seed", tags=["Admin"])
async def seed_database():
    """Seed the database with sample data"""
    try:
        from init_db import init_database
        init_database()
        return APIResponse(status="success", message="Database seeded successfully!")
    except Exception as e:
        logger.error(f"Error seeding database: {e}")
        raise HTTPException(status_code=500, detail=f"Error seeding database: {str(e)}")


@app.get("/api/admin/submissions", tags=["Admin"])
async def get_contact_submissions(
    auth_email: EmailStr = Query(...),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get contact form submissions (admin only)"""
    if auth_email != ADMIN_EMAIL:
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    submissions = db.query(ContactSubmission).order_by(
        ContactSubmission.created_at.desc()
    ).limit(limit).all()
    
    return {
        "submissions": [
            {
                "id": s.id,
                "name": s.name,
                "email": s.email,
                "contact": s.contact,
                "message": s.message,
                "created_at": s.created_at.isoformat(),
                "is_read": s.is_read
            }
            for s in submissions
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
