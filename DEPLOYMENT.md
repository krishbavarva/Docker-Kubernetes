# Deployment Guide: Docker & Kubernetes

This project is fully containerized with Docker and ready for Kubernetes deployment.

## 📁 Project Structure

```
full-stack-app-template/
├── backend/
│   ├── Dockerfile              # Backend container definition
│   └── .dockerignore           # Files to exclude from Docker build
├── frontend/
│   ├── Dockerfile              # Frontend container definition
│   ├── nginx.conf              # Nginx configuration for production
│   └── .dockerignore           # Files to exclude from Docker build
├── kubernetes/                 # Kubernetes manifests
│   ├── namespace.yaml          # Namespace definition
│   ├── mongodb-deployment.yaml # MongoDB deployment & service
│   ├── backend-deployment.yaml # Backend deployment & service
│   ├── frontend-deployment.yaml# Frontend deployment & service
│   ├── configmap.yaml          # Environment configuration
│   ├── secret.yaml             # Secrets (SECRET_KEY)
│   ├── ingress.yaml            # Ingress for external access
│   └── README.md               # Detailed K8s guide
├── scripts/
│   ├── build-docker.sh         # Build Docker images
│   └── deploy-kubernetes.sh    # Deploy to Kubernetes
├── docker-compose.yml          # Docker Compose for local dev
├── DOCKER.md                   # Docker usage guide
└── DEPLOYMENT.md               # This file
```

## 🐳 Docker Setup (Quick Start)

### Option 1: Docker Compose (Recommended for Local)

```bash
# Start all services
docker-compose up --build

# Access:
# - Frontend: http://localhost:3000
# - Backend: http://localhost:3001
# - MongoDB: localhost:27017

# Stop services
docker-compose down

# Seed database
docker-compose exec backend node seed.js
```

### Option 2: Build Script

```bash
# Build all images
./scripts/build-docker.sh

# Then run manually or use docker-compose
```

## ☸️ Kubernetes Setup

### Prerequisites

1. Kubernetes cluster (minikube, kind, or cloud provider)
2. kubectl installed and configured
3. Docker images built (use `./scripts/build-docker.sh`)

### Quick Deployment

```bash
# 1. Build Docker images
./scripts/build-docker.sh

# 2. Load images into cluster (for local development)
# If using minikube:
minikube image load fullstack-app-backend:latest
minikube image load fullstack-app-frontend:latest

# If using kind:
kind load docker-image fullstack-app-backend:latest
kind load docker-image fullstack-app-frontend:latest

# 3. Deploy to Kubernetes
./scripts/deploy-kubernetes.sh

# Or manually:
cd kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl wait --for=condition=ready pod -l app=mongodb -n fullstack-app --timeout=120s
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
```

### Access the Application

```bash
# Option 1: Port Forward (Development)
kubectl port-forward -n fullstack-app svc/frontend-service 3000:80
# Open http://localhost:3000

# Option 2: Get LoadBalancer IP (Cloud)
kubectl get svc frontend-service -n fullstack-app
# Access via external IP

# Option 3: NodePort (Local Cluster)
# Change service type to NodePort in frontend-deployment.yaml
kubectl get nodes -o wide  # Get node IP
# Access via <node-ip>:<nodePort>
```

### Seed Database in Kubernetes

```bash
# Method 1: Exec into backend pod
kubectl exec -it -n fullstack-app deployment/backend -- node seed.js

# Method 2: Create a job
kubectl run seed-job --image=fullstack-app-backend:latest \
  --restart=Never --rm -it \
  --env="MONGODB_URL=mongodb://mongodb:27017/app" \
  -- node seed.js
```

## 🔧 Configuration

### Environment Variables

**Backend:**
- `NODE_ENV`: Environment (production/development)
- `PORT`: Server port (default: 3001)
- `SECRET_KEY`: JWT secret key
- `MONGODB_URL`: MongoDB connection string
- `CORS_ORIGIN`: Allowed CORS origin

**Frontend:**
- `REACT_APP_BASE_URL`: Backend API URL

### Updating Configuration

**Docker Compose:**
- Edit `docker-compose.yml` environment section

**Kubernetes:**
- Edit `kubernetes/configmap.yaml` for non-sensitive values
- Edit `kubernetes/secret.yaml` for sensitive values (SECRET_KEY)
- Apply changes: `kubectl apply -f kubernetes/configmap.yaml`

## 📊 Monitoring & Management

### Check Status

```bash
# Pods
kubectl get pods -n fullstack-app

# Services
kubectl get svc -n fullstack-app

# Deployments
kubectl get deployments -n fullstack-app

# All resources
kubectl get all -n fullstack-app
```

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n fullstack-app

# Frontend logs
kubectl logs -f deployment/frontend -n fullstack-app

# MongoDB logs
kubectl logs -f deployment/mongodb -n fullstack-app
```

### Scaling

```bash
# Scale backend to 3 replicas
kubectl scale deployment backend --replicas=3 -n fullstack-app

# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3 -n fullstack-app
```

### Update Application

```bash
# 1. Rebuild images
./scripts/build-docker.sh

# 2. Load into cluster
minikube image load fullstack-app-backend:latest
minikube image load fullstack-app-frontend:latest

# 3. Restart deployments
kubectl rollout restart deployment backend -n fullstack-app
kubectl rollout restart deployment frontend -n fullstack-app
```

## 🧹 Cleanup

### Docker Compose

```bash
docker-compose down        # Stop and remove containers
docker-compose down -v     # Also remove volumes
```

### Kubernetes

```bash
# Delete entire namespace (removes everything)
kubectl delete namespace fullstack-app

# Or delete individual resources
kubectl delete -f kubernetes/
```

## 🔒 Production Considerations

1. **Secrets Management**: Replace hardcoded SECRET_KEY in `secret.yaml`
   ```bash
   kubectl create secret generic app-secrets \
     --from-literal=SECRET_KEY=your-production-secret \
     -n fullstack-app
   ```

2. **Image Registry**: Push images to registry instead of loading locally
   ```bash
   docker tag fullstack-app-backend:latest your-registry/backend:latest
   docker push your-registry/backend:latest
   # Update image in backend-deployment.yaml
   ```

3. **SSL/TLS**: Configure cert-manager and update ingress.yaml

4. **Database**: Consider using managed MongoDB service (Atlas, DocumentDB, etc.)

5. **Monitoring**: Add Prometheus/Grafana integration

6. **Logging**: Set up centralized logging (ELK, Loki)

7. **Backup**: Implement MongoDB backup strategy

8. **Resource Limits**: Adjust CPU/memory limits based on load

## 📚 Additional Resources

- [DOCKER.md](./DOCKER.md) - Detailed Docker guide
- [kubernetes/README.md](./kubernetes/README.md) - Detailed Kubernetes guide
- [Main README.md](./README.md) - Application documentation

## 🖥️ Checking Docker & Kubernetes in Docker Desktop

Docker Desktop provides a visual dashboard to monitor your containers and Kubernetes resources.

### Enabling Kubernetes in Docker Desktop

1. **Open Docker Desktop**
2. **Go to Settings** (gear icon in top right)
3. **Click "Kubernetes"** in the left menu
4. **Check "Enable Kubernetes"**
5. **Click "Apply & Restart"** (takes 1-2 minutes)

### Checking Docker Containers

#### View Running Containers
1. Open Docker Desktop
2. Click **"Containers"** tab (left sidebar)
3. You'll see all running containers:
   - `mongodb` - Database container
   - `backend` - Backend API container  
   - `frontend` - Frontend web container

#### Container Details
- **Status**: Green = running, Red = stopped
- **Ports**: Shows port mappings (e.g., `3000:80`, `3001:3001`)
- **CPU/Memory**: Real-time resource usage
- **Logs**: Click container name → Click "Logs" tab to see live logs
- **Stats**: Click container name → Click "Stats" tab for CPU/memory graphs
- **Exec**: Click container name → Click "Exec" tab to open terminal inside container

#### View Docker Images
1. Click **"Images"** tab
2. See all built images:
   - `full-stack-app-template-backend`
   - `full-stack-app-template-frontend`
   - `mongo:7`
3. Click image to see details, size, layers
4. Click **"Run"** to start a container from an image

#### View Docker Compose Services
1. When `docker-compose up` is running, you'll see a **group** of containers
2. Click the group name to see all services together
3. Each service shows its status, logs, and resources

### Checking Kubernetes Resources

#### Prerequisites
- Kubernetes must be enabled in Docker Desktop settings
- You need to deploy your app: `kubectl apply -f kubernetes/`

#### View Kubernetes Resources
1. **Open Docker Desktop**
2. Click **"Kubernetes"** tab (left sidebar) - **OR** use the Kubernetes icon in the top menu
3. You'll see different views:

#### View Pods
- Click **"Pods"** or go to Kubernetes → Pods
- See all running pods:
  - `mongodb-xxxxx` - Database pod
  - `backend-xxxxx` - Backend pod
  - `frontend-xxxxx` - Frontend pod
- **Status indicators**:
  - Green circle = Running
  - Yellow circle = Pending
  - Red circle = Error/CrashLoopBackOff
- Click pod name to see:
  - **Logs**: Container output
  - **Describe**: Detailed pod info (events, conditions, resource limits)
  - **Exec**: Open terminal in pod
  - **YAML**: View pod configuration

#### View Services
1. Click **"Services"** or Kubernetes → Services
2. See services:
   - `mongodb-service` - Database service
   - `backend-service` - Backend API service
   - `frontend-service` - Frontend service
3. Click service to see:
   - **Endpoints**: Which pods are backing this service
   - **Ports**: Service ports and target ports
   - **Selectors**: Labels used to match pods

#### View Deployments
1. Click **"Deployments"** or Kubernetes → Deployments
2. See:
   - `mongodb-deployment`
   - `backend-deployment`
   - `frontend-deployment`
3. View replica status (desired vs ready)
4. Click deployment to:
   - **Scale**: Change number of replicas
   - **Rollout History**: See deployment history
   - **Restart**: Trigger a rolling restart

#### View Namespaces
1. Click **"Namespaces"**
2. See your namespace: `fullstack-app`
3. Filter resources by namespace

#### View ConfigMaps & Secrets
1. Click **"Config"** → **"ConfigMaps"**
2. See `app-config` with your environment variables
3. Click **"Secrets"** to view (masked) secrets like `app-secret`

#### View Ingress
1. Click **"Ingress"** or Kubernetes → Ingress
2. See your `app-ingress` configuration
3. View routing rules and host configurations

### Quick Actions in Docker Desktop

#### For Containers:
- **Start/Stop**: Toggle button or right-click → Start/Stop
- **Restart**: Right-click → Restart
- **Delete**: Right-click → Delete
- **View Logs**: Click container → Logs tab (auto-refreshes)
- **Open Terminal**: Click container → Exec tab → `/bin/sh`

#### For Kubernetes Pods:
- **View Logs**: Click pod → Logs tab
- **Describe**: Click pod → See events and status
- **Delete**: Right-click → Delete (creates new pod if part of deployment)
- **Shell Access**: Click pod → Exec tab

### Monitoring Tips

1. **CPU/Memory Graphs**: Use the "Stats" tab to spot resource hogs
2. **Log Viewer**: Filter logs by keyword, timestamps
3. **Event Timeline**: In Kubernetes, check Events tab for errors
4. **Health Checks**: Green status = healthy, check logs if yellow/red
5. **Resource Usage**: Compare actual usage vs limits set in YAML files

### Command Line Alternative

You can also check from terminal (often faster):

```bash
# Docker
docker ps                    # Running containers
docker images               # All images
docker-compose ps           # Compose services

# Kubernetes  
kubectl get pods -n fullstack-app           # Pods
kubectl get svc -n fullstack-app            # Services
kubectl get deployments -n fullstack-app    # Deployments
kubectl get all -n fullstack-app            # All resources
kubectl logs <pod-name> -n fullstack-app    # Pod logs
```

Docker Desktop dashboard gives you the same info visually - choose what works best for you!

## 🆘 Troubleshooting

### Docker Issues

```bash
# Rebuild from scratch
docker-compose down -v
docker system prune -a
docker-compose up --build

# Check container logs
docker-compose logs backend
docker-compose logs frontend
```

### Kubernetes Issues

```bash
# Check pod status
kubectl describe pod <pod-name> -n fullstack-app

# Check events
kubectl get events -n fullstack-app --sort-by='.lastTimestamp'

# Debug pod
kubectl exec -it <pod-name> -n fullstack-app -- sh
```

### Connection Issues

- **Backend can't connect to MongoDB**: Check MongoDB service name and port
- **Frontend can't reach backend**: Verify REACT_APP_BASE_URL matches backend service
- **CORS errors**: Update CORS_ORIGIN in configmap

## ✅ Verification Checklist

- [ ] Docker images build successfully
- [ ] docker-compose starts all services
- [ ] Application accessible at http://localhost:3000
- [ ] Backend API responds at http://localhost:3001
- [ ] Database seeded successfully
- [ ] Kubernetes cluster accessible via kubectl
- [ ] Images loaded into cluster
- [ ] All pods running: `kubectl get pods -n fullstack-app`
- [ ] Services created: `kubectl get svc -n fullstack-app`
- [ ] Application accessible via port-forward or LoadBalancer


