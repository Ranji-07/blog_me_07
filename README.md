# 🚀 Next-Gen Data-Driven Developer Portfolio

A premium, highly-interactive, and fully data-driven developer portfolio web application designed to showcase technical skills through a cinematic, modern aesthetic.

## ✨ Key Features

- **Cinematic Glassmorphism UI**: Built with Flutter Web, the frontend features striking frosted glass containers, rich gradients, layered parallax depth, and natively rendered 3D animated particle backgrounds using `CustomPainter`.
- **Fully Data-Driven**: The entire Hero section—including animated professional roles, floating tech stack badges, statistics, and availability status—is dynamically fetched from the backend API. No hardcoded frontend text!
- **FastAPI Backend**: A robust Python FastAPI architecture connected to a PostgreSQL database serving structured profile and project data.
- **Secure Email Control**: Includes an innovative `/api/admin/email-command` route that allows the administrator to toggle their availability status or hide the portfolio simply via email commands.
- **Production-Ready Dockerization**: Fully containerized using `docker-compose`. The architecture neatly orchestrates the PostgreSQL database, the Uvicorn-served FastAPI backend, and an Nginx server optimized to serve the compiled Flutter web files.

## 🛠️ Technology Stack

- **Frontend**: Flutter, Dart, Material UI components, Canvas rendering.
- **Backend**: Python, FastAPI, SQLAlchemy.
- **Database**: PostgreSQL.
- **Infrastructure**: Docker, Docker Compose, Nginx.

## 🐳 Quick Start (Local Development)

To spin up the entire architecture on your local machine:

1. **Boot all containers**:
   ```bash
   docker-compose up -d --build
   ```

2. **Seed the database** (injects the dynamic hero content, projects, and experience data):
   ```bash
   python portfolio-backend/trigger_seed.py
   ```

3. **View the live app**:
   Open a browser to `http://localhost:3000`

## 📂 Project Structure

- `/portfolio`: The Flutter front-end workspace.
- `/portfolio-backend`: The FastAPI server, models, database config, and logic.
- `docker-compose.yml`: The root container orchestration blueprint.
- `init_db.py`: The database initialization script containing the injected profile data.

---
*Designed & Engineered for maximum visual impact and engineering scalability.*
