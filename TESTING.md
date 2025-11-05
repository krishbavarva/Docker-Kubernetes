# Testing Guide: Docker & Kubernetes

This guide provides step-by-step instructions to test Docker and Kubernetes deployments.

---

## 🐳 Testing Docker Setup

### Prerequisites
- Docker installed and running
- Docker Compose installed (usually comes with Docker Desktop)

### Step 1: Verify Docker Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Verify Docker daemon is running
docker ps
```

**Expected Output:**
```
Docker version 20.x.x
docker-compose version 1.x.x or 2.x.x
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

---

### Step 2: Build Docker Images

```bash
# Navigate to project root
cd /home/happy/Desktop/full-stack-app-template

# Build images using the script
./scripts/build-docker.sh

# Or manually:
docker build -t fullstack-app-backend:latest ./backend
docker build -t fullstack-app-frontend:latest --build-arg REACT_APP_BASE_URL=http://localhost:3001 ./frontend
```

**Verify Images:**
```bash
docker images | grep fullstack-app
```

**Expected Output:**
```
fullstack-app-backend    latest    abc123def456    2 minutes ago    200MB
fullstack-app-frontend   latest    def456ghi789    2 minutes ago    50MB
```

---

### Step 3: Test with Docker Compose

```bash
# Start all services
docker-compose up --build

# In another terminal, check running containers
docker-compose ps
```

**Expected Output:**
```
NAME       IMAGE                    STATUS         PORTS
mongodb    mongo:7                  Up 2 minutes   0.0.0.0:27017->27017/tcp
backend    fullstack-app-backend    Up 2 minutes   0.0.0.0:3001->3001/tcp
frontend   fullstack-app-frontend   Up 2 minutes   0.0.0.0:3000->80/tcp
```

---

### Step 4: Verify Services are Running

**Test MongoDB:**
```bash
# Check MongoDB logs
docker-compose logs mongodb

# Connect to MongoDB
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
```

**Expected Output:**
```
{ ok: 1 }
```

**Test Backend:**
```bash
# Check backend logs
docker-compose logs backend

# Test backend API
curl http://localhost:3001/api/homes
```

**Expected Output:**
```
[]  # Empty array initially
```

**Test Frontend:**
```bash
# Check frontend logs
docker-compose logs frontend

# Test frontend (in browser or curl)
curl http://localhost:3000
```

**Expected Output:**
```html
<!DOCTYPE html>
<html lang="en">
...
```

---

### Step 5: Seed Database

```bash
# Seed the database
docker-compose exec backend node seed.js

# Verify data was inserted
docker-compose exec mongodb mongosh app --eval "db.houses.countDocuments()"
docker-compose exec mongodb mongosh app --eval "db.users.countDocuments()"
```

**Expected Output:**
```
100+ houses inserted
1 user inserted
```

---

### Step 6: Test Full Application

1. **Open Browser:** http://localhost:3000
2. **Login:**
   - Email: `admin@gmail.com`
   - Password: `password`
3. **Verify:**
   - Can see dashboard
   - Can view homes list
   - Can navigate pages

---

### Step 7: Test Container Communication

```bash
# Test backend can reach MongoDB
docker-compose exec backend ping -c 2 mongodb

# Test frontend can reach backend (from inside container)
docker-compose exec frontend wget -O- http://backend:3001/api/homes
```

---

### Step 8: Cleanup Test

```bash
# Stop containers
docker-compose down

# Remove volumes (clears data)
docker-compose down -v

# Verify cleanup
docker ps -a | grep fullstack-app  # Should be empty
```

---

## ☸️ Testing Kubernetes Setup

### Prerequisites
- Kubernetes cluster running (minikube, kind, or cloud)
- kubectl installed and configured
- Docker images built

---

### Step 1: Verify Kubernetes Cluster

```bash
# Check kubectl version
kubectl version --client

# Check cluster connection
kubectl cluster-info

# Check nodes
kubectl get nodes
```

**Expected Output:**
```
Client Version: version.Info{...}
Server Version: version.Info{...}
Kubernetes control plane is running at https://...
NAME       STATUS   ROLES    AGE   VERSION
node1      Ready    master   5m    v1.28.0
```

---

### Step 2: Build and Load Images

**For minikube:**
```bash
# Build images
./scripts/build-docker.sh

# Load into minikube
minikube image load fullstack-app-backend:latest
minikube image load fullstack-app-frontend:latest

# Verify images
minikube image ls | grep fullstack-app
```

**For kind:**
```bash
# Build images
./scripts/build-docker.sh

# Load into kind
kind load docker-image fullstack-app-backend:latest
kind load docker-image fullstack-app-frontend:latest
```

**For cloud (GKE, EKS, AKS):**
```bash
# Tag and push to registry
docker tag fullstack-app-backend:latest your-registry/backend:latest
docker tag fullstack-app-frontend:latest your-registry/frontend:latest
docker push your-registry/backend:latest
docker push your-registry/frontend:latest

# Update image names in deployment YAMLs
```

---

### Step 3: Deploy to Kubernetes

```bash
# Use deployment script
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

---

### Step 4: Verify Deployments

**Check Namespace:**
```bash
kubectl get namespace fullstack-app
```

**Check Pods:**
```bash
kubectl get pods -n fullstack-app
```

**Expected Output:**
```
NAME                       READY   STATUS    RESTARTS   AGE
mongodb-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
backend-xxxxxxxxxx-xxxxx   2/2     Running   0          1m
backend-xxxxxxxxxx-xxxxx   2/2     Running   0          1m
frontend-xxxxxxxxxx-xxxxx  1/1     Running   0          1m
frontend-xxxxxxxxxx-xxxxx  1/1     Running   0          1m
```

**Check Services:**
```bash
kubectl get svc -n fullstack-app
```

**Expected Output:**
```
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
mongodb           ClusterIP      10.96.x.x      <none>        27017/TCP
backend-service   ClusterIP      10.96.x.x      <none>        3001/TCP
frontend-service  LoadBalancer   10.96.x.x      <pending>     80/TCP
```

**Check Deployments:**
```bash
kubectl get deployments -n fullstack-app
```

**Expected Output:**
```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
mongodb   1/1     1            1           2m
backend   2/2     2            2           1m
frontend  2/2     2            2           1m
```

---

### Step 5: Check Pod Logs

```bash
# MongoDB logs
kubectl logs -f deployment/mongodb -n fullstack-app

# Backend logs
kubectl logs -f deployment/backend -n fullstack-app

# Frontend logs
kubectl logs -f deployment/frontend -n fullstack-app
```

**Expected Output:**
- MongoDB: Connection logs
- Backend: "Backend server started on http://localhost:3001"
- Frontend: Nginx access logs

---

### Step 6: Test Service Connectivity

**Test MongoDB Service:**
```bash
# Port forward MongoDB
kubectl port-forward -n fullstack-app svc/mongodb 27017:27017

# In another terminal, test connection
mongosh mongodb://localhost:27017/app --eval "db.adminCommand('ping')"
```

**Test Backend Service:**
```bash
# Port forward backend
kubectl port-forward -n fullstack-app svc/backend-service 3001:3001

# Test API
curl http://localhost:3001/api/homes
```

**Test Frontend Service:**
```bash
# Port forward frontend
kubectl port-forward -n fullstack-app svc/frontend-service 3000:80

# Test in browser
curl http://localhost:3000
```

---

### Step 7: Test Health Checks

```bash
# Check pod status
kubectl describe pod <pod-name> -n fullstack-app

# Look for:
# - Liveness:  http-get http://:3001/api/homes delay=30s timeout=1s period=10s
# - Readiness: http-get http://:3001/api/homes delay=10s timeout=1s period=5s

# Manually test health endpoint
kubectl exec -it deployment/backend -n fullstack-app -- curl http://localhost:3001/api/homes
```

---

### Step 8: Test Scaling

```bash
# Scale backend to 3 replicas
kubectl scale deployment backend --replicas=3 -n fullstack-app

# Verify scaling
kubectl get pods -l app=backend -n fullstack-app

# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3 -n fullstack-app

# Verify scaling
kubectl get pods -l app=frontend -n fullstack-app
```

**Expected Output:**
```
NAME                       READY   STATUS    RESTARTS   AGE
backend-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
backend-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
backend-xxxxxxxxxx-xxxxx   1/1     Running   0          30s  # New pod
```

---

### Step 9: Test Persistent Storage

```bash
# Check PVC (PersistentVolumeClaim)
kubectl get pvc -n fullstack-app

# Expected output:
# NAME          STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS
# mongodb-pvc   Bound    pv-xxx   1Gi        RWO            standard

# Create test data
kubectl exec -it deployment/mongodb -n fullstack-app -- mongosh app --eval "db.test.insertOne({test: 'data'})"

# Delete MongoDB pod (simulates restart)
kubectl delete pod -l app=mongodb -n fullstack-app

# Wait for pod to restart
kubectl wait --for=condition=ready pod -l app=mongodb -n fullstack-app --timeout=60s

# Verify data persisted
kubectl exec -it deployment/mongodb -n fullstack-app -- mongosh app --eval "db.test.findOne()"
```

---

### Step 10: Seed Database

```bash
# Seed database
kubectl exec -it deployment/backend -n fullstack-app -- node seed.js

# Verify data
kubectl exec -it deployment/mongodb -n fullstack-app -- mongosh app --eval "db.houses.countDocuments()"
kubectl exec -it deployment/mongodb -n fullstack-app -- mongosh app --eval "db.users.countDocuments()"
```

---

### Step 11: Test Load Balancing

```bash
# Port forward backend service
kubectl port-forward -n fullstack-app svc/backend-service 3001:3001

# Make multiple requests (should hit different pods)
for i in {1..10}; do
  curl http://localhost:3001/api/homes
  echo ""
done

# Check which pods handled requests
kubectl logs deployment/backend -n fullstack-app --tail=10
```

---

### Step 12: Test Ingress (if configured)

```bash
# Check ingress
kubectl get ingress -n fullstack-app

# Get ingress IP/hostname
kubectl describe ingress app-ingress -n fullstack-app

# Test routes
curl http://<ingress-ip>/          # Should serve frontend
curl http://<ingress-ip>/api/homes # Should proxy to backend
```

---

### Step 13: Test Resource Limits

```bash
# Check resource usage
kubectl top pods -n fullstack-app

# Expected output:
# NAME                       CPU(cores)   MEMORY(bytes)
# backend-xxx                 50m          100Mi
# frontend-xxx                10m          50Mi
# mongodb-xxx                 20m          200Mi

# Describe pod to see limits
kubectl describe pod <pod-name> -n fullstack-app | grep -A 5 "Limits:"
```

---

### Step 14: Test Self-Healing

```bash
# Delete a backend pod
kubectl delete pod -l app=backend -n fullstack-app --field-selector=status.phase=Running --limit=1

# Watch it recreate
kubectl get pods -l app=backend -n fullstack-app -w

# Should see:
# - Pod terminating
# - New pod creating
# - New pod running
```

---

### Step 15: Test Rollout Updates

```bash
# Trigger a rollout restart
kubectl rollout restart deployment/backend -n fullstack-app

# Watch rollout status
kubectl rollout status deployment/backend -n fullstack-app

# Check rollout history
kubectl rollout history deployment/backend -n fullstack-app
```

---

## 🔍 Troubleshooting Common Issues

### Docker Issues

**Problem: Port already in use**
```bash
# Find process using port
lsof -i :3000
lsof -i :3001
lsof -i :27017

# Kill process or change ports in docker-compose.yml
```

**Problem: Images not building**
```bash
# Build with verbose output
docker build --no-cache -t fullstack-app-backend:latest ./backend

# Check Dockerfile syntax
docker build --dry-run ./backend  # Not valid, but check manually
```

**Problem: Containers not connecting**
```bash
# Check network
docker network ls
docker network inspect fullstack-app-template_app-network

# Check container logs
docker-compose logs backend
docker-compose logs mongodb
```

---

### Kubernetes Issues

**Problem: Pods not starting**
```bash
# Check pod status
kubectl describe pod <pod-name> -n fullstack-app

# Common issues:
# - ImagePullBackOff: Image not found
# - CrashLoopBackOff: Container crashing
# - Pending: Not enough resources

# Check events
kubectl get events -n fullstack-app --sort-by='.lastTimestamp'
```

**Problem: ImagePullBackOff**
```bash
# For local clusters, ensure images are loaded:
minikube image load fullstack-app-backend:latest
# OR
kind load docker-image fullstack-app-backend:latest

# Check image pull policy in deployment YAML (should be IfNotPresent)
```

**Problem: Services not accessible**
```bash
# Check service endpoints
kubectl get endpoints -n fullstack-app

# Check service selectors match pod labels
kubectl get pods -n fullstack-app --show-labels
kubectl describe svc backend-service -n fullstack-app
```

**Problem: ConfigMap/Secret not working**
```bash
# Verify ConfigMap exists
kubectl get configmap app-config -n fullstack-app -o yaml

# Verify Secret exists
kubectl get secret app-secrets -n fullstack-app

# Check pod environment variables
kubectl exec deployment/backend -n fullstack-app -- env | grep MONGODB_URL
```

---

## ✅ Complete Test Checklist

### Docker Tests
- [ ] Docker and Docker Compose installed
- [ ] Images build successfully
- [ ] All containers start with `docker-compose up`
- [ ] MongoDB accepts connections
- [ ] Backend API responds at http://localhost:3001
- [ ] Frontend serves at http://localhost:3000
- [ ] Containers can communicate
- [ ] Database seed works
- [ ] Application login works
- [ ] Cleanup works (`docker-compose down -v`)

### Kubernetes Tests
- [ ] Kubernetes cluster accessible
- [ ] Images loaded into cluster
- [ ] All pods running (mongodb, backend x2, frontend x2)
- [ ] All services created
- [ ] Pods have correct labels
- [ ] Health checks working
- [ ] Scaling works (scale up/down)
- [ ] Persistent storage works (data survives pod restart)
- [ ] Load balancing works (requests hit different pods)
- [ ] Database seed works
- [ ] Application accessible via port-forward
- [ ] Resource limits enforced
- [ ] Self-healing works (delete pod, it recreates)
- [ ] Logs accessible
- [ ] Cleanup works (`kubectl delete namespace fullstack-app`)

---

## 🚀 Quick Test Commands

**Docker:**
```bash
# Quick start and test
docker-compose up --build &
sleep 10
curl http://localhost:3001/api/homes
curl http://localhost:3000
docker-compose down
```

**Kubernetes:**
```bash
# Quick deploy and test
./scripts/deploy-kubernetes.sh
sleep 30
kubectl get pods -n fullstack-app
kubectl port-forward -n fullstack-app svc/frontend-service 3000:80 &
curl http://localhost:3000
```

---

## 📊 Monitoring Commands

**Docker:**
```bash
# Watch container stats
docker stats

# Monitor logs
docker-compose logs -f

# Check resource usage
docker system df
```

**Kubernetes:**
```bash
# Watch pods
kubectl get pods -n fullstack-app -w

# Top resources
kubectl top pods -n fullstack-app
kubectl top nodes

# Monitor events
kubectl get events -n fullstack-app --watch
```

---

This comprehensive testing guide covers all aspects of Docker and Kubernetes deployment. Follow the steps sequentially to verify everything works correctly! 🎯


