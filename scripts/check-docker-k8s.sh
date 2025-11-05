#!/bin/bash

# Docker and Kubernetes Verification Script

echo "=========================================="
echo "🐳 Docker & ☸️ Kubernetes Verification"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking Docker Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed"
    docker --version
else
    echo -e "${RED}✗${NC} Docker is NOT installed"
    exit 1
fi

# Check Docker Compose
echo ""
echo "Checking Docker Compose..."
if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose is available"
    docker compose version 2>/dev/null || docker-compose --version
else
    echo -e "${RED}✗${NC} Docker Compose is NOT available"
fi

# Check Docker Daemon
echo ""
echo "Checking Docker Daemon..."
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker daemon is running"
else
    echo -e "${RED}✗${NC} Docker daemon is NOT running"
    echo "   Start Docker service: sudo systemctl start docker"
fi

# Check Docker Containers
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking Docker Containers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CONTAINERS=$(docker ps -a --format "{{.Names}}" 2>/dev/null)
if [ ! -z "$CONTAINERS" ]; then
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "All containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo -e "${YELLOW}⚠${NC} No containers found"
fi

# Check Docker Images
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Checking Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IMAGES=$(docker images --format "{{.Repository}}" 2>/dev/null | grep -E "fullstack|mongo")
if [ ! -z "$IMAGES" ]; then
    echo "Project images:"
    docker images | grep -E "REPOSITORY|fullstack|mongo"
    
    # Check if backend image exists
    if docker images | grep -q "fullstack-app-backend"; then
        echo -e "${GREEN}✓${NC} Backend image exists: fullstack-app-backend:latest"
    else
        echo -e "${YELLOW}⚠${NC} Backend image NOT found. Build with: docker build -t fullstack-app-backend:latest ./backend"
    fi
    
    # Check if frontend image exists
    if docker images | grep -q "fullstack-app-frontend"; then
        echo -e "${GREEN}✓${NC} Frontend image exists: fullstack-app-frontend:latest"
    else
        echo -e "${YELLOW}⚠${NC} Frontend image NOT found"
    fi
else
    echo -e "${YELLOW}⚠${NC} No project images found"
fi

# Check Docker Volumes
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Checking Docker Volumes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VOLUMES=$(docker volume ls --format "{{.Name}}" 2>/dev/null | grep -E "mongodb|fullstack")
if [ ! -z "$VOLUMES" ]; then
    echo "Project volumes:"
    docker volume ls | grep -E "DRIVER|mongodb|fullstack"
else
    echo -e "${YELLOW}⚠${NC} No project volumes found"
fi

# Check Docker Networks
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Checking Docker Networks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NETWORKS=$(docker network ls --format "{{.Name}}" 2>/dev/null | grep -E "app|fullstack")
if [ ! -z "$NETWORKS" ]; then
    echo "Project networks:"
    docker network ls | grep -E "NETWORK|app|fullstack"
else
    echo -e "${YELLOW}⚠${NC} No project networks found"
fi

# Check Kubernetes
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Checking Kubernetes Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓${NC} kubectl is installed"
    kubectl version --client --short 2>/dev/null || kubectl version --client
else
    echo -e "${RED}✗${NC} kubectl is NOT installed"
    echo "   Install: https://kubernetes.io/docs/tasks/tools/"
fi

# Check Kubernetes Cluster
echo ""
echo "Checking Kubernetes Cluster Connection..."
if kubectl cluster-info &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
    kubectl cluster-info 2>/dev/null | head -1
    
    # Check nodes
    echo ""
    echo "Cluster nodes:"
    kubectl get nodes 2>/dev/null || echo "  Unable to get nodes"
    
    # Check namespaces
    echo ""
    echo "Checking namespaces..."
    if kubectl get namespace fullstack-app &> /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Namespace 'fullstack-app' exists"
        echo ""
        echo "Resources in fullstack-app namespace:"
        kubectl get all -n fullstack-app 2>/dev/null || echo "  No resources found"
    else
        echo -e "${YELLOW}⚠${NC} Namespace 'fullstack-app' does NOT exist"
        echo "   Create with: kubectl apply -f kubernetes/namespace.yaml"
    fi
else
    echo -e "${RED}✗${NC} Kubernetes cluster is NOT accessible"
    echo ""
    echo "Options:"
    echo "  1. Install minikube: https://minikube.sigs.k8s.io/docs/start/"
    echo "  2. Install kind: https://kind.sigs.k8s.io/docs/user/quick-start/"
    echo "  3. Use cloud provider (GKE, EKS, AKS)"
fi

# Check Kubernetes Context
if command -v kubectl &> /dev/null; then
    echo ""
    echo "Current Kubernetes context:"
    kubectl config current-context 2>/dev/null || echo "  No context configured"
fi

# Check minikube (if installed)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Checking Local Kubernetes Options"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v minikube &> /dev/null; then
    echo -e "${GREEN}✓${NC} minikube is installed"
    if minikube status &> /dev/null; then
        echo "  minikube status:"
        minikube status 2>/dev/null | head -3
    else
        echo -e "  ${YELLOW}⚠${NC} minikube is not running"
        echo "  Start with: minikube start"
    fi
else
    echo -e "${YELLOW}⚠${NC} minikube is NOT installed"
fi

if command -v kind &> /dev/null; then
    echo -e "${GREEN}✓${NC} kind is installed"
    KIND_CLUSTERS=$(kind get clusters 2>/dev/null)
    if [ ! -z "$KIND_CLUSTERS" ]; then
        echo "  kind clusters: $KIND_CLUSTERS"
    else
        echo -e "  ${YELLOW}⚠${NC} No kind clusters found"
        echo "  Create with: kind create cluster"
    fi
else
    echo -e "${YELLOW}⚠${NC} kind is NOT installed"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Docker Status
if docker info &> /dev/null && command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker: Ready"
else
    echo -e "${RED}✗${NC} Docker: Not Ready"
fi

# Kubernetes Status
if kubectl cluster-info &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Kubernetes: Ready"
else
    echo -e "${YELLOW}⚠${NC} Kubernetes: Not Available (optional)"
fi

# Project Files Check
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Checking Project Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$(dirname "$0")/.." || exit

if [ -f "docker-compose.yml" ]; then
    echo -e "${GREEN}✓${NC} docker-compose.yml exists"
else
    echo -e "${RED}✗${NC} docker-compose.yml missing"
fi

if [ -f "backend/Dockerfile" ]; then
    echo -e "${GREEN}✓${NC} backend/Dockerfile exists"
else
    echo -e "${RED}✗${NC} backend/Dockerfile missing"
fi

if [ -f "frontend/Dockerfile" ]; then
    echo -e "${GREEN}✓${NC} frontend/Dockerfile exists"
else
    echo -e "${RED}✗${NC} frontend/Dockerfile missing"
fi

if [ -d "kubernetes" ]; then
    echo -e "${GREEN}✓${NC} kubernetes/ directory exists"
    K8S_FILES=$(ls kubernetes/*.yaml 2>/dev/null | wc -l)
    echo "  Found $K8S_FILES Kubernetes manifest files"
else
    echo -e "${RED}✗${NC} kubernetes/ directory missing"
fi

echo ""
echo "=========================================="
echo "✅ Verification Complete!"
echo "=========================================="


