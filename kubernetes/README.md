# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the full-stack application.

## Prerequisites

1. Kubernetes cluster running (minikube, kind, or cloud provider)
2. kubectl configured to access your cluster
3. Docker images built and available (either in registry or locally)

## Quick Start

### 1. Build Docker Images

```bash
# From project root
docker build -t fullstack-app-backend:latest ./backend
docker build -t fullstack-app-frontend:latest ./frontend
```

### 2. Load Images into Cluster (for local development)

If using minikube or kind:

```bash
# For minikube
minikube image load fullstack-app-backend:latest
minikube image load fullstack-app-frontend:latest

# For kind
kind load docker-image fullstack-app-backend:latest
kind load docker-image fullstack-app-frontend:latest
```

### 3. Deploy to Kubernetes

Deploy in order:

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create secrets (update SECRET_KEY before applying)
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY=your-production-secret-key \
  -n fullstack-app

# Or apply the example secret file
kubectl apply -f secret.yaml

# Deploy ConfigMap
kubectl apply -f configmap.yaml

# Deploy MongoDB
kubectl apply -f mongodb-deployment.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongodb -n fullstack-app --timeout=120s

# Deploy Backend
kubectl apply -f backend-deployment.yaml

# Deploy Frontend
kubectl apply -f frontend-deployment.yaml

# (Optional) Deploy Ingress
kubectl apply -f ingress.yaml
```

### 4. Check Deployment Status

```bash
# Check pods
kubectl get pods -n fullstack-app

# Check services
kubectl get svc -n fullstack-app

# Check deployments
kubectl get deployments -n fullstack-app
```

### 5. Access the Application

**Option 1: Port Forward (Development)**
```bash
# Frontend
kubectl port-forward -n fullstack-app svc/frontend-service 3000:80

# Backend
kubectl port-forward -n fullstack-app svc/backend-service 3001:3001

# Access at http://localhost:3000
```

**Option 2: NodePort Service**
- Change frontend-service type to NodePort
- Get node IP: `kubectl get nodes -o wide`
- Access at `http://<node-ip>:30000`

**Option 3: LoadBalancer (Cloud)**
- Frontend service is already configured as LoadBalancer
- Get external IP: `kubectl get svc frontend-service -n fullstack-app`

**Option 4: Ingress**
- Set up ingress controller (nginx-ingress recommended)
- Update ingress.yaml with your domain
- Access via your domain

### 6. Seed the Database

```bash
# Create a temporary pod to run seed script
kubectl run seed-job --image=fullstack-app-backend:latest \
  --restart=Never \
  --rm -it \
  --env="MONGODB_URL=mongodb://mongodb:27017/app" \
  -- node seed.js

# Or exec into backend pod
kubectl exec -it -n fullstack-app deployment/backend -- node seed.js
```

## Scaling

```bash
# Scale backend
kubectl scale deployment backend --replicas=3 -n fullstack-app

# Scale frontend
kubectl scale deployment frontend --replicas=3 -n fullstack-app
```

## Updating Application

```bash
# Rebuild images
docker build -t fullstack-app-backend:latest ./backend
docker build -t fullstack-app-frontend:latest ./frontend

# Load into cluster (for local)
minikube image load fullstack-app-backend:latest
minikube image load fullstack-app-frontend:latest

# Restart deployments
kubectl rollout restart deployment backend -n fullstack-app
kubectl rollout restart deployment frontend -n fullstack-app
```

## Monitoring

```bash
# View logs
kubectl logs -f deployment/backend -n fullstack-app
kubectl logs -f deployment/frontend -n fullstack-app

# Describe resources
kubectl describe deployment backend -n fullstack-app
kubectl describe pod <pod-name> -n fullstack-app
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace fullstack-app

# Or delete individually
kubectl delete -f .
```

## Production Considerations

1. **Secrets Management**: Use proper secret management (AWS Secrets Manager, HashiCorp Vault, etc.)
2. **Image Registry**: Push images to container registry (Docker Hub, ECR, GCR, etc.)
3. **SSL/TLS**: Set up cert-manager for automatic certificate management
4. **Resource Limits**: Adjust based on your requirements
5. **Health Checks**: Already configured, but adjust timing as needed
6. **Backup**: Set up regular MongoDB backups
7. **Monitoring**: Integrate with monitoring solutions (Prometheus, Grafana)
8. **Logging**: Set up centralized logging (ELK, Loki, etc.)


