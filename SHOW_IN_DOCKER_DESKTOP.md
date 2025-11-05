# How to Show Your Containers in Docker Desktop

## Step 1: Start Your Containers

Open terminal in your project folder and run:

```bash
cd /home/happy/Desktop/full-stack-app-template
docker-compose up --build
```

**OR** if containers are already built:

```bash
docker-compose up
```

This will start:
- `mongodb` - Database
- `backend` - API server
- `frontend` - Web app

## Step 2: Check Docker Desktop

1. **Open Docker Desktop** (if not already open)
2. **Click "Containers" tab** in the left sidebar
3. **You should now see:**
   - `mongodb` - Running (green dot)
   - `backend` - Running (green dot)
   - `frontend` - Running (green dot)

## Step 3: View Container Details

Click any container name to see:
- **Logs** → Live output
- **Stats** → CPU/Memory graphs
- **Exec** → Terminal inside container

## Step 4: Access Your App

### In Docker Desktop:
- Click the **link icon** (🌐) next to ports:
  - `frontend`: `3000:80` → Click to open http://localhost:3000
  - `backend`: `3001:3001` → API at http://localhost:3001

### Or manually:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **MongoDB**: localhost:27017

## Step 5: Stop Containers

### In Docker Desktop:
- Click container → Three dots menu → **Stop**
- Or right-click → **Stop**

### In Terminal:
```bash
docker-compose down
```

## Troubleshooting

### Containers not showing?
1. Make sure Docker Desktop is running
2. Check terminal for errors
3. Refresh Docker Desktop (click refresh icon)

### Containers showing but not running?
1. Click container name
2. Check **Logs** tab for errors
3. Click **Stats** to see resource usage

### Port already in use?
```bash
# Stop existing containers
docker-compose down

# Or find what's using the port
lsof -i :3000
lsof -i :3001
```



