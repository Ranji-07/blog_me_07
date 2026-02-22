import json
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from main import Base, PortfolioData
import os

# Database URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://portfolio_user:secure_password_123@db:5432/portfolio")

# Create engine and session
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_database():
    """Initialize database with sample data"""
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # Sample data
    # Sample data
    about_data = {
        "name": "Charles onion",
        "title": "UAV.I Designer & Art Director",
        "roles": [
            "AI & ML Developer",
            "DevOps Engineer",
            "Computer Engineer",
            "Entrepreneur"
        ],
        "bio": "Hello! I'm a passionate developer specializing in Flutter and AI-driven applications. I enjoy building user-friendly and efficient applications that solve real-world problems.",
        "is_available": False,
        "stats": {
            "projects": 7,
            "experience": 1,
            "technologies": 12
        },
        "tech_stack": ["Flutter", "Python", "FastAPI", "Docker", "TensorFlow"],
        "skills": {
            "Languages": [
                {"name": "Python", "icon": "python.png"},
                {"name": "Dart", "icon": "dart.jpg"},
                {"name": "C++", "icon": "c-.png"},
                {"name": "Java", "icon": "js-file.png"}
            ],
            "Frameworks": [
                {"name": "Flutter", "icon": "flutter.png"},
                {"name": "FastAPI", "icon": "api.png"},
                {"name": "TensorFlow", "icon": "Ai-ml.png"}
            ],
            "Tools & Platforms": [
                {"name": "Docker", "icon": "docker"},
                {"name": "Git", "icon": "git"},
                {"name": "IoT / ESP32", "icon": "iot.png"}
            ]
        },
        "education": [
            {
                "year": "2090",
                "title": "School",
                "subtitle": "Completed High School",
                "color": "blue"
            },
            {
                "year": "2020",
                "title": "Higher Secondary",
                "subtitle": "Participated in sports and extracurriculars",
                "color": "purple"
            },
            {
                "year": "2024",
                "title": "Graduation",
                "subtitle": "Bachelor's Degree in Computer Science",
                "color": "green"
            }
        ]
    }
    
    projects_data = {
        "projects": [
            {
                "title": "AI Surveillance System",
                "description": "Automated tracking & monitoring system utilizing edge-computing for real-time threat detection and anomaly classification.",
                "icon": "camera",
                "technologies": ["Python", "OpenCV", "TensorFlow", "FastAPI"]
            },
            {
                "title": "Smart Hydroponics Dashboard",
                "description": "Automated pH & EC control system for plants with a React frontend and hardware sensors to maximize crop yield.",
                "icon": "agriculture",
                "technologies": ["IoT", "Arduino", "React", "Node.js"]
            },
            {
                "title": "IoT Waste Management",
                "description": "Smart tracking of waste levels across smart cities. Uses LoRaWAN to communicate bin fill ranges to a central server.",
                "icon": "delete",
                "technologies": ["IoT", "ESP32", "Cloud", "LoRaWAN"]
            },
            {
                "title": "FinTech Payment Gateway",
                "description": "High-performance payment gateway built with microservices architecture handling 1000+ TPS securely.",
                "icon": "code",
                "technologies": ["Go", "gRPC", "PostgreSQL", "Redis"]
            },
            {
                "title": "Mobile Healthcare App",
                "description": "Telemedicine application connecting patients with doctors via secure WebRTC video streaming and encrypted chat.",
                "icon": "phone",
                "technologies": ["Flutter", "Firebase", "WebRTC"]
            }
        ]
    }
    
    experience_data = {
        "experiences": [
            {
                "company": "TechNova Solutions",
                "logo": "Ai-ml.png",
                "positions": [
                    {
                        "position": "Senior Full Stack Engineer",
                        "startDate": "Jan 2022",
                        "endDate": "Present"
                    },
                    {
                        "position": "Software Engineer II",
                        "startDate": "Mar 2020",
                        "endDate": "Dec 2021"
                    }
                ]
            },
            {
                "company": "CloudScape Dynamics",
                "logo": "c-.png",
                "positions": [
                    {
                        "position": "Backend Developer",
                        "startDate": "Jun 2018",
                        "endDate": "Feb 2020"
                    }
                ]
            },
            {
                "company": "InnoVentures Startup",
                "logo": "js-file.png",
                "positions": [
                    {
                        "position": "Software Engineering Intern",
                        "startDate": "May 2017",
                        "endDate": "Aug 2017"
                    }
                ]
            }
        ]
    }
    
    contact_data = {
        "email": "charles@example.com",
        "phone": "+77777777",
        "social_links": {
            "github": "https://github.com/charles",
            "linkedin": "https://linkedin.com/in/charles",
            "instagram": "https://instagram.com/charles"
        }
    }
    
    # Insert data
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
            print(f"✓ Initialized {section} section")
        else:
            existing.content = json.dumps(data)
            existing.is_active = True
            print(f"✓ Updated existing {section} section")
    
    db.commit()
    db.close()
    
    print("\n✅ Database initialized successfully!")

if __name__ == "__main__":
    init_database()