# Quick Start Guide - Docker Services

Since you have disk space now, follow these commands to start Docker services:

## Step-by-Step Commands

### Step 1: Check Current Status
```bash
cd /home/happy/Desktop/full-stack-app-template
docker ps -a
docker images | grep fullstack-app
```

### Step 2: Start MongoDB
```bash
# If MongoDB container exists, start it
docker start mongodb

# If it doesn't exist, create it
docker run -d --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_DATABASE=app \
  -v mongodb_data:/data/db \
  mongo:7

# Verify MongoDB is running
docker ps | grep mongodb
```

### Step 3: Start Backend Container
```bash
# Check if backend container exists
docker ps -a | grep backend

# If exists, remove old one
docker rm -f backend 2>/dev/null

# Start backend container
docker run -d --name backend \
  -p 3001:3001 \
  --link mongodb:mongodb \
  -e NODE_ENV=production \
  -e PORT=3001 \
  -e SECRET_KEY=secret-key-dev \
  -e MONGODB_URL=mongodb://mongodb:27017/app?readPreference=primary&directConnection=true&ssl=false \
  -e CORS_ORIGIN=http://localhost:3000 \
  fullstack-app-backend:latest

# Check if backend is running
docker ps | grep backend
```

### Step 4: Verify Services
```bash
# Check all containers
docker ps

# Test backend API
curl http://localhost:3001/api/homes

# View backend logs
docker logs backend

# View MongoDB logs
docker logs mongodb
```

### Step 5: Seed Database
```bash
# Seed the database
docker exec backend node seed.js

# Verify data
docker exec mongodb mongosh app --eval "db.houses.countDocuments()"
docker exec mongodb mongosh app --eval "db.users.countDocuments()"
```

## Alternative: Use Docker Compose (Recommended)

```bash
cd /home/happy/Desktop/full-stack-app-template

# Start MongoDB and Backend (skip frontend for now)
docker compose up -d mongodb backend

# Check status
docker compose ps

# View logs
docker compose logs -f backend

# Seed database
docker compose exec backend node seed.js

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v
```

## Using the Quick Start Script

```bash
cd /home/happy/Desktop/full-stack-app-template
chmod +x scripts/quick-start-docker.sh
./scripts/quick-start-docker.sh
```

## Expected Results

After running the commands, you should see:

1. **MongoDB**: Running on port 27017
2. **Backend**: Running on port 3001
3. **API Response**: `curl http://localhost:3001/api/homes` returns `[]` or data array

## Test the Application

```bash
# Test backend
curl http://localhost:3001/api/homes

# Test login (in browser or with curl)
# Frontend is still running locally at http://localhost:3000
# Login credentials:
# Email: admin@gmail.com
# Password: password
```

## Troubleshooting

### If containers don't start:
```bash
# Check Docker daemon
docker info

# Check logs
docker logs backend
docker logs mongodb
```

### If backend can't connect to MongoDB:
```bash
# Check MongoDB is running
docker ps | grep mongodb

# Test connection from backend container
docker exec backend ping -c 2 mongodb
```

### If port 3001 is already in use:
```bash
# Find what's using the port
lsof -i :3001

# Stop existing backend container
docker stop backend
docker rm backend

# Or use a different port
docker run -d --name backend -p 3002:3001 ... (change port mapping)
```

## Cleanup

```bash
# Stop containers
docker stop backend mongodb

# Remove containers
docker rm backend mongodb

# Remove images (optional)
docker rmi fullstack-app-backend:latest

# Remove volumes (clears MongoDB data)
docker volume rm mongodb_data
```

---

**Try running these commands in your terminal!** Start with Step 1 and work through each step. Let me know if you encounter any issues!


