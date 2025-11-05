# Docker Setup Guide

This guide explains how to use Docker and Docker Compose for the full-stack application.

## Quick Start with Docker Compose

### 1. Build and Start All Services

```bash
# From project root
docker-compose up --build
```

This will:
- Build backend Docker image
- Build frontend Docker image
- Start MongoDB container
- Start backend container
- Start frontend container

### 2. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **MongoDB**: localhost:27017

### 3. Stop Services

```bash
docker-compose down
```

### 4. Stop and Remove Volumes

```bash
docker-compose down -v
```

## Individual Container Commands

### Build Images

```bash
# Build backend
docker build -t fullstack-app-backend:latest ./backend

# Build frontend
docker build -t fullstack-app-frontend:latest ./frontend
```

### Run Containers

```bash
# Run MongoDB
docker run -d --name mongodb -p 27017:27017 \
  -v mongodb_data:/data/db \
  mongo:7

# Run backend
docker run -d --name backend -p 3001:3001 \
  --link mongodb:mongodb \
  -e MONGODB_URL=mongodb://mongodb:27017/app \
  -e SECRET_KEY=secret-key-dev \
  fullstack-app-backend:latest

# Run frontend
docker run -d --name frontend -p 3000:80 \
  -e REACT_APP_BASE_URL=http://localhost:3001 \
  fullstack-app-frontend:latest
```

## Seed Database

```bash
# Using docker-compose
docker-compose exec backend node seed.js

# Or with standalone container
docker exec backend node seed.js
```

## View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb
```

## Environment Variables

Create a `.env` file in the project root for custom configuration:

```env
SECRET_KEY=your-secret-key
MONGODB_URL=mongodb://mongodb:27017/app
REACT_APP_BASE_URL=http://localhost:3001
```

Docker Compose will automatically use these variables.

## Development vs Production

### Development
- Use docker-compose.yml (current setup)
- Mount volumes for hot reloading (add volume mounts to docker-compose.yml)

### Production
- Build optimized images
- Use production nginx config
- Set up proper secrets management
- Use external database (managed MongoDB service)

## Troubleshooting

### Rebuild after code changes
```bash
docker-compose up --build
```

### Remove all containers and volumes
```bash
docker-compose down -v
docker system prune -a
```

### Check container status
```bash
docker-compose ps
```

### Execute commands in container
```bash
docker-compose exec backend sh
docker-compose exec frontend sh
```


