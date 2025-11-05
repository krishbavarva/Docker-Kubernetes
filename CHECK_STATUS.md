# Docker & Kubernetes Status Check

Run this script to check your Docker and Kubernetes setup:

```bash
cd /home/happy/Desktop/full-stack-app-template
./scripts/check-docker-k8s.sh
```

## What the Script Checks:

### Docker Checks:
1. ✅ Docker installation and version
2. ✅ Docker Compose availability
3. ✅ Docker daemon status
4. ✅ Running containers
5. ✅ Docker images (especially fullstack-app images)
6. ✅ Docker volumes
7. ✅ Docker networks

### Kubernetes Checks:
1. ✅ kubectl installation
2. ✅ Cluster connection
3. ✅ Cluster nodes
4. ✅ Namespaces (especially fullstack-app)
5. ✅ Resources in namespace
6. ✅ minikube status (if installed)
7. ✅ kind clusters (if installed)

### Project Files Checks:
1. ✅ docker-compose.yml
2. ✅ Dockerfiles (backend/frontend)
3. ✅ Kubernetes manifests directory

## Manual Quick Checks:

### Docker:
```bash
# Check Docker
docker --version
docker ps -a
docker images | grep fullstack
docker volume ls
docker network ls

# Test Docker Compose
docker compose version
docker compose ps
```

### Kubernetes:
```bash
# Check kubectl
kubectl version --client

# Check cluster
kubectl cluster-info
kubectl get nodes

# Check namespace
kubectl get namespace fullstack-app
kubectl get all -n fullstack-app

# Check if minikube is running
minikube status

# Check if kind is available
kind get clusters
```

## Expected Results:

### Docker (Required):
- ✅ Docker installed and running
- ✅ Docker Compose available
- ✅ Backend image: `fullstack-app-backend:latest`
- ✅ MongoDB container running (optional)

### Kubernetes (Optional):
- ✅ kubectl installed
- ✅ Cluster accessible OR minikube/kind available
- ✅ Namespace `fullstack-app` created (after deployment)

## Troubleshooting:

**If Docker is not running:**
```bash
sudo systemctl start docker
# Or on some systems:
sudo service docker start
```

**If Docker Compose not found:**
- Docker Desktop includes it: `docker compose`
- Or install separately: `sudo apt install docker-compose`

**If Kubernetes not available:**
- Install minikube: https://minikube.sigs.k8s.io/
- Install kind: https://kind.sigs.k8s.io/
- Use cloud provider (GKE, EKS, AKS)

Run the check script and share the output for help!


