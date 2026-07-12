import json
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from utils.time import utc_now

load_dotenv()

# Database URL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./portfolio_dev.db")

# Create engine and session
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_database():
    """Initialize database with comprehensive portfolio data"""
    
    from database import Base
    from models import PortfolioData
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # ─────────────────────────────────────────────────────────────────────────
    # About Section Data
    # ─────────────────────────────────────────────────────────────────────────
    about_data = {
        "name": "Charles Onion",
        "title": "Full Stack Developer & AI Engineer",
        "roles": [
            "Full Stack Developer",
            "AI & ML Engineer",
            "DevOps Specialist",
            "Flutter Expert"
        ],
        "bio": "Passionate software engineer with 3+ years of experience building scalable applications. I specialize in Flutter, Python, and cloud-native architectures.",
        "tagline": "Building production apps that feel thoughtful on every screen.",
        "is_available": True,
        "profile_image": {
            "url": "/images/profile/charles-onion.png",
            "image_url": "/images/profile/charles-onion.png",
            "alt": "Charles Onion portrait"
        },
        "stats": {
            "projects": 15,
            "experience": 3,
            "technologies": 20
        },
        "tech_stack": [
            "Flutter",
            "Python",
            "FastAPI",
            "Docker",
            "TensorFlow",
            "PostgreSQL",
            "AWS"
        ],
        "skills": {
            "Languages": [
                {"name": "Python", "level": 95, "icon_url": "/images/skills/python.png"},
                {"name": "Dart", "level": 90, "icon_url": "/images/skills/dart.png"},
                {"name": "JavaScript", "level": 85, "icon_url": "/images/skills/javascript.png"}
            ],
            "Frameworks": [
                {"name": "Flutter", "level": 95, "icon_url": "/images/skills/flutter.png"},
                {"name": "FastAPI", "level": 90, "icon_url": "/images/skills/fastapi.png"},
                {"name": "React", "level": 80, "icon_url": "/images/skills/react.png"}
            ]
        },
        "education": [
            {
                "year": "2021 - 2025",
                "title": "Bachelor of Technology",
                "subtitle": "Computer Science & Engineering",
                "institution": "National Institute of Technology",
                "color": "cyan",
                "description": "Focused on software systems, AI, and distributed computing."
            },
            {
                "year": "2019 - 2021",
                "title": "Higher Secondary",
                "subtitle": "Science Stream (PCM + CS)",
                "institution": "Central Board of Secondary Education",
                "color": "blue"
            }
        ],
        "certifications": [
            {
                "title": "Azure AI Engineer Associate",
                "issuer": "Microsoft",
                "date": "2026-06",
                "credential_id": "AZAI-12345",
                "credential_url": "https://example.com/certifications/azai-12345",
                "icon_url": "/images/certifications/azure-ai.png"
            }
        ],
        "status": {
            "visibility": "visible",
            "state": "published",
            "status_message": "Live",
            "updated_by": "seed-script"
        }
    }
    
    # ─────────────────────────────────────────────────────────────────────────
    # Projects Section Data
    # ─────────────────────────────────────────────────────────────────────────
    projects_data = {
        "projects": [
            {
                "id": "smart-agri",
                "title": "Smart Agriculture IoT Platform",
                "slug": "smart-agriculture-iot-platform",
                "short_description": "End-to-end IoT solution for precision farming with AI-driven crop health monitoring.",
                "full_description": "A comprehensive platform that monitors soil conditions, weather patterns, and crop health using computer vision and mobile dashboards.",
                "category": "IoT",
                "technologies": ["Flutter", "Python", "TensorFlow", "ESP32", "LoRaWAN", "FastAPI", "PostgreSQL"],
                "features": [
                    "Real-time soil monitoring",
                    "AI-powered disease detection",
                    "Automated irrigation scheduling"
                ],
                "workflow": [
                    {"step": 1, "title": "Data Collection", "description": "ESP32 sensors capture field data."},
                    {"step": 2, "title": "AI Processing", "description": "Models analyze crop health."},
                    {"step": 3, "title": "Insights", "description": "The app surfaces alerts and recommendations."}
                ],
                "thumbnail": {
                    "url": "/images/projects/smart-agri-thumb.png",
                    "image_url": "/images/projects/smart-agri-thumb.png",
                    "alt": "Smart Agriculture project thumbnail"
                },
                "links": {
                    "github": "https://github.com/charles/smart-agri",
                    "live_demo": "https://smart-agri.demo.com",
                    "documentation": "https://docs.smart-agri.com"
                },
                "status": {
                    "visibility": "visible",
                    "state": "published",
                    "status_message": "Featured project",
                    "updated_by": "seed-script"
                }
            },
            {
                "id": "ai-surveillance",
                "title": "AI Video Surveillance System",
                "slug": "ai-video-surveillance-system",
                "short_description": "Real-time threat detection using edge computing and deep learning.",
                "full_description": "An intelligent surveillance system using edge inference for low-latency detection and alerting.",
                "category": "AI/ML",
                "technologies": ["Python", "YOLOv8", "OpenCV", "TensorRT", "FastAPI", "Flutter"],
                "features": [
                    "Edge detection at low latency",
                    "License plate recognition",
                    "Incident alerting"
                ],
                "links": {
                    "github": "https://github.com/charles/ai-surveillance",
                    "video": "https://youtube.com/watch?v=demo"
                },
                "status": {
                    "visibility": "visible",
                    "state": "published",
                    "status_message": "Production ready",
                    "updated_by": "seed-script"
                }
            }
        ],
        "status": {
            "visibility": "visible",
            "state": "published",
            "status_message": "Projects published",
            "updated_by": "seed-script"
        }
    }
    
    # ─────────────────────────────────────────────────────────────────────────
    # Experience Section Data
    # ─────────────────────────────────────────────────────────────────────────
    experience_data = {
        "careers": [
            {
                "company": "TechNova Solutions",
                "logo": {
                    "url": "/images/logos/technova.png",
                    "image_url": "/images/logos/technova.png",
                    "alt": "TechNova Solutions logo"
                },
                "positions": [
                    {
                        "position": "Senior Full Stack Engineer",
                        "start_date": "2023-01",
                        "end_date": "Present",
                        "description": "Leading the development of a microservices-based SaaS platform serving 50,000+ users.",
                        "achievements": [
                            "Reduced cloud costs by 40%",
                            "Mentored a team of five engineers"
                        ]
                    },
                    {
                        "position": "Software Engineer II",
                        "start_date": "2021-06",
                        "end_date": "2022-12",
                        "description": "Developed Flutter mobile applications and real-time platform features."
                    }
                ],
                "visibility": "visible"
            }
        ],
        "internships": [
            {
                "company": "InnoVentures Startup",
                "logo": {
                    "url": "/images/logos/innoventures.png",
                    "image_url": "/images/logos/innoventures.png",
                    "alt": "InnoVentures Startup logo"
                },
                "positions": [
                    {
                        "position": "Software Engineering Intern",
                        "start_date": "2019-05",
                        "end_date": "2019-08",
                        "description": "Built internal tooling and helped automate CI/CD workflows."
                    }
                ],
                "visibility": "visible"
            }
        ],
        "education": about_data["education"],
        "certifications": [
            {
                "title": "AWS Certified Solutions Architect - Associate",
                "issuer": "Amazon Web Services",
                "date": "2023-11",
                "credential_id": "AWS-SAA-12345",
                "icon_url": "/images/certifications/aws-saa.png"
            }
        ],
        "academic": [
            {
                "title": "National Hackathon Winner",
                "institution": "TechFest 2023",
                "date": "2023-03",
                "description": "Led the team that built an AI-powered accessibility tool.",
                "icon_url": "/images/awards/hackathon.png"
            }
        ],
        "status": {
            "visibility": "visible",
            "state": "published",
            "status_message": "Experience published",
            "updated_by": "seed-script"
        }
    }
    
    # ─────────────────────────────────────────────────────────────────────────
    # Contact Section Data
    # ─────────────────────────────────────────────────────────────────────────
    contact_data = {
        "email": "charles@example.com",
        "phone": "+1 (555) 123-4567",
        "location": "San Francisco, CA",
        "timezone": "PST (UTC-8)",
        "social_links": {
            "github": "https://github.com/charlesonion",
            "linkedin": "https://linkedin.com/in/charlesonion",
            "twitter": "https://twitter.com/charlesonion",
            "instagram": "https://instagram.com/charlesonion",
            "dribbble": "https://dribbble.com/charlesonion"
        },
        "availability": {
            "freelance": True,
            "fulltime": True,
            "consultation": True,
            "response_time": "Within 24 hours"
        },
        "status": {
            "visibility": "visible",
            "state": "published",
            "status_message": "Inbox open",
            "updated_by": "seed-script"
        }
    }
    
    # ─────────────────────────────────────────────────────────────────────────
    # Insert Data
    # ─────────────────────────────────────────────────────────────────────────
    sections = [
        ("about", about_data),
        ("projects", projects_data),
        ("experience", experience_data),
        ("contact", contact_data)
    ]
    
    for section, data in sections:
        existing = db.query(PortfolioData).filter(
            PortfolioData.section == section
        ).first()
        
        if not existing:
            portfolio_item = PortfolioData(
                section=section,
                content=json.dumps(data),
                is_active=True
            )
            db.add(portfolio_item)
            print(f"[created] {section} section")
        else:
            existing.content = json.dumps(data)
            existing.is_active = True
            existing.updated_at = utc_now()
            print(f"[updated] {section} section")
    
    db.commit()
    db.close()
    
    print("\nDatabase initialized successfully!")
    print("-" * 40)
    print("Sections created/updated:")
    for section, _ in sections:
        print(f"  - {section}")
    print("-" * 40)


if __name__ == "__main__":
    init_database()
