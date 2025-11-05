#!/bin/bash

# Docker Build Script
# This script builds Docker images for backend and frontend

set -e

echo "🐳 Building Docker Images..."

# Build backend
echo "📦 Building backend image..."
docker build -t fullstack-app-backend:latest ./backend

# Build frontend
echo "📦 Building frontend image..."
docker build -t fullstack-app-frontend:latest \
  --build-arg REACT_APP_BASE_URL=http://localhost:3001 \
  ./frontend

echo ""
echo "✅ Build complete!"
echo ""
echo "📋 Available images:"
docker images | grep fullstack-app

echo ""
echo "🚀 To start with docker-compose:"
echo "   docker-compose up"
echo ""
echo "📤 To load images into minikube:"
echo "   minikube image load fullstack-app-backend:latest"
echo "   minikube image load fullstack-app-frontend:latest"
echo ""
echo "📤 To load images into kind:"
echo "   kind load docker-image fullstack-app-backend:latest"
echo "   kind load docker-image fullstack-app-frontend:latest"


