# Portfolio Backend API

Professional portfolio management system with email-based control.

## Features
- RESTful API with FastAPI
- PostgreSQL database
- Email-based content updates
- Admin controls (404, 202, update)
- Swagger documentation
- Docker containerization

## Setup

### 1. Clone Repository
\`\`\`bash
git clone <your-repo-url>
cd portfolio-backend
\`\`\`

### 2. Configure Environment
\`\`\`bash
cp .env.example .env
# Edit .env with your email credentials
\`\`\`

### 3. Run with Docker
\`\`\`bash
docker-compose up --build
\`\`\`

### 4. Initialize Database
\`\`\`bash
docker-compose exec api python init_db.py
\`\`\`

### 5. Access API
- API: http://localhost:8000
- Swagger Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Email Commands

Send POST request to `/api/admin/email-command`:

### 404 Mode (Hide Portfolio)
\`\`\`json
{
  "command": "404",
  "auth_email": "admin@example.com"
}
\`\`\`

### 202 Restart (Show Portfolio)
\`\`\`json
{
  "command": "202",
  "auth_email": "admin@example.com"
}
\`\`\`

### Update Content
\`\`\`json
{
  "command": "update",
  "auth_email": "admin@example.com",
  "data": {
    "section": "about",
    "content": {
      "name": "Your Name",
      "bio": "Your bio"
    }
  }
}
\`\`\`

## Deployment

### Docker Hub
\`\`\`bash
docker build -t your-username/portfolio-api .
docker push your-username/portfolio-api
\`\`\`

### Git
\`\`\`bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
\`\`\`