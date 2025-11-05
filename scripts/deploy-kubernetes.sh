#!/bin/bash

# Kubernetes Deployment Script
# This script deploys the full-stack application to Kubernetes

set -e

echo "🚀 Starting Kubernetes Deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Navigate to kubernetes directory
cd "$(dirname "$0")/../kubernetes"

# Apply manifests in order
echo "📦 Creating namespace..."
kubectl apply -f namespace.yaml

echo "🔐 Creating secrets..."
kubectl apply -f secret.yaml

echo "⚙️  Creating configmap..."
kubectl apply -f configmap.yaml

echo "🍃 Deploying MongoDB..."
kubectl apply -f mongodb-deployment.yaml

echo "⏳ Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongodb -n fullstack-app --timeout=120s || true

echo "🔧 Deploying backend..."
kubectl apply -f backend-deployment.yaml

echo "🎨 Deploying frontend..."
kubectl apply -f frontend-deployment.yaml

echo "🌐 Deploying ingress (if available)..."
kubectl apply -f ingress.yaml || echo "⚠️  Ingress not applied (may need ingress controller)"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check deployment status:"
echo "   kubectl get pods -n fullstack-app"
echo "   kubectl get svc -n fullstack-app"
echo ""
echo "🔍 View logs:"
echo "   kubectl logs -f deployment/backend -n fullstack-app"
echo "   kubectl logs -f deployment/frontend -n fullstack-app"
echo ""
echo "🌍 Access application:"
echo "   kubectl port-forward -n fullstack-app svc/frontend-service 3000:80"
echo "   Then open http://localhost:3000"


