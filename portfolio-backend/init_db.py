import json
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os

# Database URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://portfolio_user:secure_password_123@db:5432/portfolio")

# Create engine and session
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_database():
    """Initialize database with comprehensive portfolio data"""
    
    # Import models after engine is created
    from main import Base, PortfolioData
    
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
        "bio": "Passionate software engineer with 3+ years of experience building scalable applications. I specialize in Flutter, Python, and cloud-native architectures. I love turning complex problems into elegant, user-friendly solutions.",
        "is_available": True,
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
                {"name": "Python", "level": 95, "icon": "python.png"},
                {"name": "Dart", "level": 90, "icon": "dart.png"},
                {"name": "JavaScript", "level": 85, "icon": "javascript.png"},
                {"name": "TypeScript", "level": 80, "icon": "typescript.png"},
                {"name": "C++", "level": 75, "icon": "cpp.png"},
                {"name": "Go", "level": 70, "icon": "go.png"}
            ],
            "Frameworks": [
                {"name": "Flutter", "level": 95, "icon": "flutter.png"},
                {"name": "FastAPI", "level": 90, "icon": "fastapi.png"},
                {"name": "React", "level": 80, "icon": "react.png"},
                {"name": "TensorFlow", "level": 85, "icon": "tensorflow.png"},
                {"name": "PyTorch", "level": 75, "icon": "pytorch.png"}
            ],
            "Tools & Platforms": [
                {"name": "Docker", "level": 90, "icon": "docker.png"},
                {"name": "Kubernetes", "level": 75, "icon": "kubernetes.png"},
                {"name": "AWS", "level": 85, "icon": "aws.png"},
                {"name": "GCP", "level": 80, "icon": "gcp.png"},
                {"name": "Git", "level": 95, "icon": "git.png"},
                {"name": "PostgreSQL", "level": 85, "icon": "postgresql.png"},
                {"name": "Redis", "level": 80, "icon": "redis.png"}
            ],
            "IoT & Embedded": [
                {"name": "ESP32", "level": 85, "icon": "esp32.png"},
                {"name": "Arduino", "level": 90, "icon": "arduino.png"},
                {"name": "Raspberry Pi", "level": 85, "icon": "raspberrypi.png"},
                {"name": "LoRaWAN", "level": 75, "icon": "lorawan.png"}
            ]
        },
        "education": [
            {
                "year": "2021 - 2025",
                "title": "Bachelor of Technology",
                "subtitle": "Computer Science & Engineering",
                "institution": "National Institute of Technology",
                "color": "cyan"
            },
            {
                "year": "2019 - 2021",
                "title": "Higher Secondary",
                "subtitle": "Science Stream (PCM + CS)",
                "institution": "Central Board of Secondary Education",
                "color": "purple"
            },
            {
                "year": "2019",
                "title": "Secondary Education",
                "subtitle": "CGPA: 9.8/10",
                "institution": "Central Board of Secondary Education",
                "color": "blue"
            }
        ]
    }
    
    # ─────────────────────────────────────────────────────────────────────────
    # Projects Section Data
    # ─────────────────────────────────────────────────────────────────────────
    projects_data = {
        "projects": [
            {
                "id": 1,
                "title": "Smart Agriculture IoT Platform",
                "shortDescription": "End-to-end IoT solution for precision farming with AI-driven crop health monitoring.",
                "fullDescription": "A comprehensive IoT platform that monitors soil conditions, weather patterns, and crop health using computer vision. The system uses ESP32 sensors for data collection, LoRaWAN for long-range communication, and a Flutter app for real-time monitoring. Machine learning models predict irrigation needs and detect plant diseases early.",
                "icon": "agriculture",
                "category": "IoT",
                "technologies": ["Flutter", "Python", "TensorFlow", "ESP32", "LoRaWAN", "FastAPI", "PostgreSQL"],
                "features": [
                    "Real-time soil moisture, pH, and temperature monitoring",
                    "AI-powered plant disease detection with 94% accuracy",
                    "Automated irrigation scheduling based on weather forecasts",
                    "Mobile app with offline support for rural areas",
                    "Dashboard for multi-farm management"
                ],
                "workflow": [
                    {
                        "step": 1,
                        "title": "Data Collection",
                        "description": "ESP32 sensors collect soil and environmental data every 15 minutes",
                        "icon": "sensors"
                    },
                    {
                        "step": 2,
                        "title": "Data Transmission",
                        "description": "LoRaWAN gateways transmit data to cloud with low power consumption",
                        "icon": "cell_tower"
                    },
                    {
                        "step": 3,
                        "title": "AI Processing",
                        "description": "TensorFlow models analyze images and predict crop health",
                        "icon": "psychology"
                    },
                    {
                        "step": 4,
                        "title": "Actionable Insights",
                        "description": "Flutter app displays recommendations and alerts",
                        "icon": "dashboard"
                    }
                ],
                "links": {
                    "github": "https://github.com/charles/smart-agri",
                    "liveDemo": "https://smart-agri.demo.com",
                    "documentation": "https://docs.smart-agri.com"
                }
            },
            {
                "id": 2,
                "title": "AI Video Surveillance System",
                "shortDescription": "Real-time threat detection using edge computing and deep learning.",
                "fullDescription": "An intelligent surveillance system that uses YOLOv8 for object detection and custom models for anomaly detection. The system runs on edge devices (Nvidia Jetson) for low-latency processing and integrates with existing CCTV infrastructure. Features include license plate recognition, intrusion detection, and crowd analysis.",
                "icon": "camera",
                "category": "AI/ML",
                "technologies": ["Python", "YOLOv8", "OpenCV", "TensorRT", "FastAPI", "WebSocket", "Flutter"],
                "features": [
                    "Real-time object detection at 30+ FPS on edge devices",
                    "License plate recognition with 98% accuracy",
                    "Anomaly detection for unusual behavior patterns",
                    "Multi-camera synchronization and tracking",
                    "Mobile alerts with incident video clips"
                ],
                "workflow": [
                    {
                        "step": 1,
                        "title": "Video Ingestion",
                        "description": "RTSP streams from IP cameras are processed in real-time",
                        "icon": "video_call"
                    },
                    {
                        "step": 2,
                        "title": "Edge Processing",
                        "description": "Nvidia Jetson runs optimized TensorRT models locally",
                        "icon": "psychology"
                    },
                    {
                        "step": 3,
                        "title": "Event Detection",
                        "description": "Custom algorithms identify threats and anomalies",
                        "icon": "analytics"
                    },
                    {
                        "step": 4,
                        "title": "Alert & Archive",
                        "description": "Instant notifications and cloud backup of incidents",
                        "icon": "cloud"
                    }
                ],
                "links": {
                    "github": "https://github.com/charles/ai-surveillance",
                    "video": "https://youtube.com/watch?v=demo"
                }
            },
            {
                "id": 3,
                "title": "Smart Waste Management System",
                "shortDescription": "IoT-based waste bin monitoring for optimized collection routes.",
                "fullDescription": "A city-scale IoT solution that monitors waste bin fill levels using ultrasonic sensors. The system optimizes garbage collection routes using genetic algorithms, reducing fuel costs by 35%. Features include a web dashboard for municipal authorities and a mobile app for citizens to report issues.",
                "icon": "delete",
                "category": "IoT",
                "technologies": ["ESP32", "LoRaWAN", "Python", "FastAPI", "React", "PostgreSQL", "Docker"],
                "features": [
                    "Real-time fill level monitoring with ultrasonic sensors",
                    "Route optimization using genetic algorithms",
                    "Predictive maintenance alerts for bins",
                    "Citizen reporting app for overflow issues",
                    "Analytics dashboard for waste patterns"
                ],
                "workflow": [
                    {
                        "step": 1,
                        "title": "Sensor Deployment",
                        "description": "Solar-powered sensors installed in waste bins",
                        "icon": "sensors"
                    },
                    {
                        "step": 2,
                        "title": "Data Aggregation",
                        "description": "LoRaWAN network collects data from 1000+ bins",
                        "icon": "cell_tower"
                    },
                    {
                        "step": 3,
                        "title": "Route Optimization",
                        "description": "AI calculates optimal collection routes daily",
                        "icon": "route"
                    },
                    {
                        "step": 4,
                        "title": "Fleet Dispatch",
                        "description": "Drivers receive optimized routes on mobile app",
                        "icon": "local_shipping"
                    }
                ],
                "links": {
                    "github": "https://github.com/charles/smart-waste",
                    "liveDemo": "https://waste-demo.herokuapp.com"
                }
            },
            {
                "id": 4,
                "title": "Real-time Collaboration Platform",
                "shortDescription": "WebSocket-based team collaboration tool with video conferencing.",
                "fullDescription": "A Slack-like collaboration platform built with Flutter Web and FastAPI. Features include real-time messaging, file sharing, video calls using WebRTC, and integrations with popular tools like GitHub and Jira. The system supports 10,000+ concurrent users with Redis-based pub/sub architecture.",
                "icon": "groups",
                "category": "Web",
                "technologies": ["Flutter", "FastAPI", "WebSocket", "WebRTC", "Redis", "PostgreSQL", "Docker"],
                "features": [
                    "Real-time messaging with typing indicators",
                    "HD video conferencing for up to 50 participants",
                    "File sharing with preview and version history",
                    "GitHub and Jira integrations",
                    "Role-based access control"
                ],
                "workflow": [
                    {
                        "step": 1,
                        "title": "User Connection",
                        "description": "WebSocket connection established with load balancing",
                        "icon": "link"
                    },
                    {
                        "step": 2,
                        "title": "Message Routing",
                        "description": "Redis pub/sub ensures real-time delivery across servers",
                        "icon": "route"
                    },
                    {
                        "step": 3,
                        "title": "Media Handling",
                        "description": "WebRTC for peer-to-peer video with TURN fallback",
                        "icon": "video_call"
                    },
                    {
                        "step": 4,
                        "title": "Data Persistence",
                        "description": "PostgreSQL stores messages with full-text search",
                        "icon": "cloud"
                    }
                ],
                "links": {
                    "github": "https://github.com/charles/collab-platform",
                    "liveDemo": "https://collab.demo.app"
                }
            },
            {
                "id": 5,
                "title": "AI Content Generation Suite",
                "shortDescription": "GPT-powered content creation tool for marketing teams.",
                "fullDescription": "A SaaS platform that helps marketing teams generate blog posts, social media content, and ad copy using fine-tuned GPT models. Features include brand voice customization, SEO optimization, and A/B testing integration. The platform processes 100,000+ content requests monthly.",
                "icon": "auto_awesome",
                "category": "AI/ML",
                "technologies": ["Python", "FastAPI", "OpenAI", "LangChain", "React", "PostgreSQL", "Stripe"],
                "features": [
                    "Custom brand voice fine-tuning",
                    "SEO-optimized content generation",
                    "Multi-platform content adaptation",
                    "A/B testing integration",
                    "Usage analytics and ROI tracking"
                ],
                "workflow": [
                    {
                        "step": 1,
                        "title": "Input Processing",
                        "description": "User provides topic, keywords, and brand guidelines",
                        "icon": "input"
                    },
                    {
                        "step": 2,
                        "title": "AI Generation",
                        "description": "Fine-tuned GPT model generates initial draft",
                        "icon": "psychology"
                    },
                    {
                        "step": 3,
                        "title": "Optimization",
                        "description": "SEO analysis and readability improvements",
                        "icon": "edit"
                    },
                    {
                        "step": 4,
                        "title": "Publishing",
                        "description": "Direct integration with CMS and social platforms",
                        "icon": "rocket_launch"
                    }
                ],
                "links": {
                    "liveDemo": "https://ai-content.app"
                }
            },
            {
                "id": 6,
                "title": "Healthcare Telemedicine App",
                "shortDescription": "HIPAA-compliant telemedicine platform connecting patients with doctors.",
                "fullDescription": "A mobile-first telemedicine application built with Flutter that connects patients with healthcare providers. Features include secure video consultations, e-prescriptions, appointment scheduling, and health record management. The platform is HIPAA-compliant with end-to-end encryption.",
                "icon": "phone",
                "category": "Mobile",
                "technologies": ["Flutter", "Firebase", "WebRTC", "FastAPI", "PostgreSQL", "AWS"],
                "features": [
                    "Secure video consultations with E2E encryption",
                    "E-prescription generation and pharmacy integration",
                    "Appointment scheduling with calendar sync",
                    "Health record management (FHIR compliant)",
                    "Payment processing with insurance verification"
                ],
                "workflow": [
                    {
                        "step": 1,
                        "title": "Appointment Booking",
                        "description": "Patient selects doctor and available time slot",
                        "icon": "dashboard"
                    },
                    {
                        "step": 2,
                        "title": "Video Consultation",
                        "description": "Secure WebRTC call with screen sharing",
                        "icon": "video_call"
                    },
                    {
                        "step": 3,
                        "title": "Prescription",
                        "description": "Doctor generates digital prescription",
                        "icon": "edit"
                    },
                    {
                        "step": 4,
                        "title": "Follow-up",
                        "description": "Automated reminders and health tracking",
                        "icon": "task_alt"
                    }
                ],
                "links": {
                    "github": "https://github.com/charles/telehealth"
                }
            }
        ]
    }
    
    # ─────────────────────────────────────────────────────────────────────────
    # Experience Section Data
    # ─────────────────────────────────────────────────────────────────────────
    experience_data = {
        "careers": [
            {
                "company": "TechNova Solutions",
                "logo": "technova.png",
                "positions": [
                    {
                        "position": "Senior Full Stack Engineer",
                        "startDate": "Jan 2023",
                        "endDate": "Present",
                        "description": "Leading the development of a microservices-based SaaS platform serving 50,000+ users. Architected the migration from monolith to microservices, resulting in 40% reduction in cloud costs. Mentoring a team of 5 junior developers."
                    },
                    {
                        "position": "Software Engineer II",
                        "startDate": "Jun 2021",
                        "endDate": "Dec 2022",
                        "description": "Developed Flutter mobile applications and React dashboards. Implemented CI/CD pipelines reducing deployment time by 60%. Built real-time features using WebSocket and Redis."
                    }
                ]
            },
            {
                "company": "CloudScape Dynamics",
                "logo": "cloudscape.png",
                "positions": [
                    {
                        "position": "Backend Developer",
                        "startDate": "Jan 2020",
                        "endDate": "May 2021",
                        "description": "Built scalable REST APIs using FastAPI and Django. Integrated third-party payment gateways processing $2M+ monthly. Implemented database optimization reducing query times by 70%."
                    }
                ]
            }
        ],
        "internships": [
            {
                "company": "InnoVentures Startup",
                "logo": "innoventures.png",
                "positions": [
                    {
                        "position": "Software Engineering Intern",
                        "startDate": "May 2019",
                        "endDate": "Aug 2019",
                        "description": "Developed a scalable authentication microservice using Node.js. Automated internal CI/CD pipelines with GitHub Actions. Participated in agile sprints and code reviews."
                    }
                ]
            }
        ],
        "certifications": [
            {
                "title": "AWS Certified Solutions Architect - Associate",
                "issuer": "Amazon Web Services",
                "date": "Nov 2023",
                "credentialId": "AWS-SAA-12345",
                "icon": "certificate"
            },
            {
                "title": "Google Professional Cloud Developer",
                "issuer": "Google Cloud",
                "date": "Jul 2022",
                "credentialId": "GCP-PCD-67890",
                "icon": "workspace_premium"
            },
            {
                "title": "TensorFlow Developer Certificate",
                "issuer": "Google",
                "date": "Mar 2022",
                "credentialId": "TF-DEV-11111",
                "icon": "certificate"
            },
            {
                "title": "Docker Certified Associate",
                "issuer": "Docker Inc.",
                "date": "Jan 2022",
                "credentialId": "DCA-22222",
                "icon": "certificate"
            }
        ],
        "academic": [
            {
                "title": "National Hackathon Winner",
                "institution": "TechFest 2023",
                "date": "March 2023",
                "description": "Led team of 4 to build an AI-powered accessibility tool for visually impaired users. Won first place among 500+ teams.",
                "icon": "emoji_events"
            },
            {
                "title": "Google Summer of Code",
                "institution": "TensorFlow",
                "date": "Summer 2022",
                "description": "Contributed to TensorFlow Lite optimization for edge devices. Merged 12 PRs improving inference speed by 15%.",
                "icon": "code"
            },
            {
                "title": "Research Publication",
                "institution": "IEEE Conference",
                "date": "2021",
                "description": "Co-authored paper on 'Edge Computing for Real-time Anomaly Detection in IoT Networks'. Cited 45+ times.",
                "icon": "workspace_premium"
            },
            {
                "title": "NCC 'C' Certificate",
                "institution": "National Cadet Corps",
                "date": "2020",
                "description": "Achieved 'A' grade demonstrating leadership, discipline, and teamwork in national-level camps.",
                "icon": "military_tech"
            }
        ]
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
            print(f"✓ Created {section} section")
        else:
            existing.content = json.dumps(data)
            existing.is_active = True
            existing.updated_at = datetime.utcnow()
            print(f"✓ Updated {section} section")
    
    db.commit()
    db.close()
    
    print("\n✅ Database initialized successfully!")
    print("━" * 40)
    print("Sections created/updated:")
    for section, _ in sections:
        print(f"  • {section}")
    print("━" * 40)


if __name__ == "__main__":
    init_database()
