# Docker & Kubernetes Files Explanation

This document explains all the files created for Docker and Kubernetes deployment, their purpose, structure, and how they work together.

## 📁 File Structure

```
full-stack-app-template/
├── backend/
│   ├── Dockerfile              # Backend container definition
│   └── .dockerignore           # Files excluded from Docker build
├── frontend/
│   ├── Dockerfile              # Frontend container definition
│   ├── nginx.conf              # Nginx web server configuration
│   └── .dockerignore           # Files excluded from Docker build
├── kubernetes/
│   ├── namespace.yaml          # Kubernetes namespace
│   ├── mongodb-deployment.yaml # MongoDB deployment & service
│   ├── backend-deployment.yaml # Backend deployment & service
│   ├── frontend-deployment.yaml# Frontend deployment & service
│   ├── configmap.yaml          # Environment configuration
│   ├── secret.yaml             # Secrets (SECRET_KEY)
│   ├── ingress.yaml            # Ingress controller for routing
│   └── README.md               # Kubernetes deployment guide
├── scripts/
│   ├── build-docker.sh         # Docker image build script
│   └── deploy-kubernetes.sh    # Kubernetes deployment script
├── docker-compose.yml           # Docker Compose orchestration
├── DOCKER.md                    # Docker usage guide
└── DEPLOYMENT.md                # Deployment overview guide
```

---

## 🐳 Docker Files

### 1. `backend/Dockerfile`

**Purpose:** Defines how to build the backend container image.

**Structure:**
```dockerfile
FROM node:18-alpine          # Base image (lightweight Node.js)
WORKDIR /app                 # Set working directory
COPY package*.json ./        # Copy package files first (for caching)
RUN npm ci --only=production # Install only production dependencies
COPY . .                     # Copy application code
EXPOSE 3001                  # Expose port 3001
CMD ["node", "server.js"]     # Start command
```

**Key Points:**
- Uses `node:18-alpine` for smaller image size
- Copies `package.json` first to leverage Docker layer caching
- Installs only production dependencies (`--only=production`)
- Exposes port 3001 for the Express server
- Runs `server.js` as the entry point

**Why this approach:**
- Alpine Linux = smaller image (~50MB vs ~900MB)
- Layer caching speeds up rebuilds
- Production-only dependencies reduce size and security surface

---

### 2. `frontend/Dockerfile`

**Purpose:** Defines a multi-stage build for the frontend (build React app, then serve with Nginx).

**Structure:**
```dockerfile
# Stage 1: Builder
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci                    # Install all dependencies (needed for build)
COPY . .
ARG REACT_APP_BASE_URL=...   # Build-time argument
ENV REACT_APP_BASE_URL=$REACT_APP_BASE_URL
RUN npm run build            # Build React app

# Stage 2: Production
FROM nginx:alpine             # Lightweight web server
COPY --from=builder /app/build /usr/share/nginx/html  # Copy built files
COPY nginx.conf /etc/nginx/conf.d/default.conf        # Copy Nginx config
EXPOSE 80                     # HTTP port
CMD ["nginx", "-g", "daemon off;"]  # Start Nginx
```

**Key Points:**
- **Multi-stage build:** Builds in one container, serves in another
- **Stage 1 (builder):** Uses Node.js to compile React app
- **Stage 2 (production):** Uses Nginx (lightweight, ~25MB) to serve static files
- **Build arguments:** `REACT_APP_BASE_URL` injected at build time
- Results in a small final image (~50MB vs ~500MB if using Node.js)

**Why multi-stage:**
- Smaller final image (no Node.js, npm, or source code)
- Faster deployments (smaller image = faster pull/deploy)
- Better security (fewer dependencies in production)

---

### 3. `frontend/nginx.conf`

**Purpose:** Nginx web server configuration for serving the React app.

**Structure:**
```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;  # SPA routing support
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Key Points:**
- **SPA routing:** `try_files` ensures React Router works (all routes → index.html)
- **Gzip compression:** Reduces transfer size
- **Asset caching:** Caches static files for 1 year (better performance)
- **Performance optimized:** Standard production Nginx config

**Why this config:**
- React Router needs `try_files` to handle client-side routing
- Gzip reduces bandwidth usage
- Caching improves load times

---

### 4. `backend/.dockerignore` & `frontend/.dockerignore`

**Purpose:** Tells Docker which files to exclude from the build context.

**Content:**
```
node_modules          # Dependencies (installed in container)
npm-debug.log         # Log files
.env                  # Environment variables (use Docker env vars)
.git                  # Git repository
.gitignore            # Git config
README.md             # Documentation
.vscode               # IDE settings
.idea                 # IDE settings
*.md                  # All markdown files
coverage              # Test coverage
.nyc_output           # Test output
```

**Key Points:**
- Excludes `node_modules` (rebuilt in container)
- Excludes `.env` files (use Docker environment variables)
- Reduces build context size (faster builds)
- Prevents sensitive files from being copied

**Why needed:**
- Faster builds (smaller context)
- Security (no secrets in image)
- Consistency (always installs fresh dependencies)

---

### 5. `docker-compose.yml`

**Purpose:** Orchestrates multiple containers (MongoDB, backend, frontend) with a single command.

**Structure:**
```yaml
version: '3.8'

services:
  mongodb:                    # Database service
    image: mongo:7
    ports: ["27017:27017"]
    volumes: [mongodb_data:/data/db]  # Persistent storage
    healthcheck: ...          # Health check for dependency
    
  backend:                    # Backend service
    build: ./backend         # Build from Dockerfile
    ports: ["3001:3001"]
    environment:             # Environment variables
      - MONGODB_URL=mongodb://mongodb:27017/app
    depends_on:
      mongodb:
        condition: service_healthy  # Wait for MongoDB
    
  frontend:                   # Frontend service
    build: ./frontend
    ports: ["3000:80"]
    depends_on: [backend]

volumes:
  mongodb_data:              # Named volume for data persistence

networks:
  app-network:               # Internal network for containers
```

**Key Points:**
- **3 services:** MongoDB, backend, frontend
- **Networking:** Containers communicate via service names (e.g., `mongodb:27017`)
- **Dependencies:** Backend waits for MongoDB to be healthy
- **Volumes:** MongoDB data persists across restarts
- **Health checks:** Ensures MongoDB is ready before starting backend

**Why Docker Compose:**
- One command: `docker-compose up` starts everything
- Automatic networking (containers can talk to each other)
- Dependency management (starts services in order)
- Easy local development

---

## ☸️ Kubernetes Files

### 6. `kubernetes/namespace.yaml`

**Purpose:** Creates an isolated namespace for the application.

**Structure:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fullstack-app
  labels:
    name: fullstack-app
```

**Key Points:**
- **Namespace:** Logical separation (like folders)
- **Isolation:** All resources grouped together
- **Cleanup:** Delete namespace = delete everything
- **Organization:** Keeps project resources separate

**Why namespaces:**
- Multi-tenant environments
- Easy cleanup (`kubectl delete namespace`)
- Resource organization
- Access control (RBAC)

---

### 7. `kubernetes/mongodb-deployment.yaml`

**Purpose:** Deploys MongoDB with persistent storage.

**Structure:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1                # Single instance (can scale)
  selector:
    matchLabels:
      app: mongodb
  template:
    spec:
      containers:
      - name: mongodb
        image: mongo:7
        ports: [containerPort: 27017]
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
      volumes:
      - name: mongodb-data
        persistentVolumeClaim:
          claimName: mongodb-pvc    # Persistent storage

---
kind: PersistentVolumeClaim  # Request storage
metadata:
  name: mongodb-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi            # 1GB storage

---
kind: Service                # Internal network access
metadata:
  name: mongodb
spec:
  type: ClusterIP           # Internal only
  ports: [port: 27017]
  selector:
    app: mongodb
```

**Key Points:**
- **Deployment:** Manages MongoDB pod(s)
- **PVC (PersistentVolumeClaim):** Requests storage (data survives pod restarts)
- **Service:** Exposes MongoDB internally (only accessible within cluster)
- **ClusterIP:** No external access (security)

**Why this setup:**
- Data persistence (survives pod restarts)
- Internal only (secure)
- Scalable (can increase replicas)

---

### 8. `kubernetes/backend-deployment.yaml`

**Purpose:** Deploys the backend API with health checks and scaling.

**Structure:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2                # 2 instances for high availability
  selector:
    matchLabels:
      app: backend
  template:
    spec:
      containers:
      - name: backend
        image: fullstack-app-backend:latest
        ports: [containerPort: 3001]
        env:                  # Environment variables
        - name: MONGODB_URL
          valueFrom:
            configMapKeyRef:  # From ConfigMap
              name: app-config
              key: MONGODB_URL
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:    # From Secret
              name: app-secrets
              key: SECRET_KEY
        resources:           # Resource limits
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:        # Is container alive?
          httpGet:
            path: /api/homes
            port: 3001
          initialDelaySeconds: 30
        readinessProbe:      # Is container ready?
          httpGet:
            path: /api/homes
            port: 3001
          initialDelaySeconds: 10

---
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP           # Internal access
  ports: [port: 3001]
  selector:
    app: backend
```

**Key Points:**
- **Replicas: 2:** High availability (if one fails, other continues)
- **Health checks:**
  - **Liveness:** Restarts pod if unhealthy
  - **Readiness:** Only routes traffic when ready
- **Resources:** CPU/memory limits prevent resource exhaustion
- **ConfigMap/Secret:** Environment variables from Kubernetes resources
- **Service:** Load balances across 2 backend pods

**Why this setup:**
- High availability (2 replicas)
- Auto-recovery (health checks restart failed pods)
- Resource management (prevents one pod from consuming all resources)
- Load balancing (traffic distributed across pods)

---

### 9. `kubernetes/frontend-deployment.yaml`

**Purpose:** Deploys the frontend with load balancing.

**Structure:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2               # 2 instances
  selector:
    matchLabels:
      app: frontend
  template:
    spec:
      containers:
      - name: frontend
        image: fullstack-app-frontend:latest
        ports: [containerPort: 80]
        env:
        - name: REACT_APP_BASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: REACT_APP_BASE_URL
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80

---
kind: Service
metadata:
  name: frontend-service
spec:
  type: LoadBalancer       # External access (or NodePort for local)
  ports: [port: 80]
  selector:
    app: frontend
```

**Key Points:**
- **LoadBalancer:** External access (cloud providers assign public IP)
- **NodePort:** Alternative for local clusters (exposes on node port)
- **Health checks:** Ensures Nginx is serving correctly
- **Resources:** Lower than backend (static files = less CPU)

**Why LoadBalancer:**
- Simple external access
- Cloud providers handle load balancing
- For local: use NodePort or Ingress

---

### 10. `kubernetes/configmap.yaml`

**Purpose:** Stores non-sensitive configuration data.

**Structure:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: fullstack-app
data:
  NODE_ENV: "production"
  PORT: "3001"
  MONGODB_URL: "mongodb://mongodb:27017/app?readPreference=primary&directConnection=true&ssl=false"
  REACT_APP_BASE_URL: "http://backend-service:3001"
  CORS_ORIGIN: "*"
```

**Key Points:**
- **Non-sensitive:** Environment variables, URLs, ports
- **Referenced:** Pods reference keys via `configMapKeyRef`
- **Updateable:** Change ConfigMap → restart pods → new config applied
- **Service names:** Uses Kubernetes service names (e.g., `mongodb`, `backend-service`)

**Why ConfigMap:**
- Separates config from code
- Easy to update without rebuilding images
- Version controlled (can be in Git)
- Reusable across pods

---

### 11. `kubernetes/secret.yaml`

**Purpose:** Stores sensitive data (passwords, keys, tokens).

**Structure:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: fullstack-app
type: Opaque
stringData:
  SECRET_KEY: "secret-key-dev"  # In production, use kubectl create secret
```

**Key Points:**
- **Sensitive data:** JWT secret, API keys, passwords
- **Base64 encoded:** Kubernetes stores secrets as base64
- **stringData:** Plain text (Kubernetes encodes automatically)
- **Referenced:** Pods reference via `secretKeyRef`

**Security Best Practices:**
```bash
# Production: Create secret via command line (not in Git)
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY=your-actual-secret-key \
  -n fullstack-app
```

**Why Secrets:**
- Separate from code (don't commit secrets)
- Encrypted at rest (in Kubernetes)
- Access control (RBAC can restrict access)

---

### 12. `kubernetes/ingress.yaml`

**Purpose:** Routes external traffic to services (like a reverse proxy).

**Structure:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: fullstack-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com    # Your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 3001
  # tls:                      # SSL/TLS (uncomment for HTTPS)
  # - hosts: [app.example.com]
  #   secretName: app-tls-secret
```

**Key Points:**
- **Routing:** 
  - `/` → frontend
  - `/api` → backend
- **Host-based:** Routes based on domain name
- **SSL/TLS:** Can configure HTTPS (uncomment tls section)
- **Requires:** Ingress controller (nginx-ingress) installed

**Why Ingress:**
- Single entry point (one IP/domain)
- Path-based routing
- SSL termination
- Better than exposing multiple LoadBalancers

---

## 🔧 Scripts

### 13. `scripts/build-docker.sh`

**Purpose:** Automated script to build Docker images.

**What it does:**
1. Builds backend image: `fullstack-app-backend:latest`
2. Builds frontend image: `fullstack-app-frontend:latest`
3. Shows available images
4. Provides instructions for loading into cluster

**Usage:**
```bash
./scripts/build-docker.sh
```

**Why a script:**
- Consistency (same build process every time)
- Saves time (no manual commands)
- Documentation (shows build process)

---

### 14. `scripts/deploy-kubernetes.sh`

**Purpose:** Automated script to deploy everything to Kubernetes.

**What it does:**
1. Checks if kubectl is installed
2. Applies manifests in correct order:
   - Namespace
   - Secrets
   - ConfigMap
   - MongoDB
   - Backend
   - Frontend
   - Ingress
3. Waits for MongoDB to be ready
4. Shows status and access instructions

**Usage:**
```bash
./scripts/deploy-kubernetes.sh
```

**Why a script:**
- Correct order (dependencies first)
- Error handling (checks prerequisites)
- User-friendly (shows next steps)

---

## 📊 How Files Work Together

### Docker Flow:
```
1. Build Images:
   Dockerfile → docker build → Image
   
2. Run Containers:
   docker-compose.yml → docker-compose up → Running Containers
   
3. Networking:
   Containers communicate via service names (mongodb, backend, frontend)
```

### Kubernetes Flow:
```
1. Create Resources:
   YAML files → kubectl apply → Kubernetes Resources
   
2. Resource Hierarchy:
   Namespace → ConfigMap/Secret → Deployment → Pod → Container
   
3. Networking:
   Service → Routes traffic → Pods (via labels)
   
4. External Access:
   Ingress → Routes external traffic → Services → Pods
```

### Complete Flow:
```
┌─────────────────────────────────────────────────┐
│  Docker Build                                    │
│  Dockerfile → Image                              │
└─────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────┐
│  Kubernetes Deployment                          │
│  YAML → kubectl apply → Resources               │
└─────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────┐
│  Runtime                                         │
│  Pods → Services → Ingress → External Access    │
└─────────────────────────────────────────────────┘
```

---

## 🔑 Key Concepts

### Docker:
- **Image:** Template (like a blueprint)
- **Container:** Running instance (like an object)
- **Dockerfile:** Instructions to build image
- **docker-compose:** Orchestrates multiple containers

### Kubernetes:
- **Pod:** Smallest deployable unit (1+ containers)
- **Deployment:** Manages pods (scaling, updates)
- **Service:** Network abstraction (load balancing)
- **ConfigMap:** Non-sensitive config
- **Secret:** Sensitive config
- **Ingress:** External routing
- **Namespace:** Logical separation

---

## 📝 Summary

| File | Purpose | Key Feature |
|------|---------|-------------|
| `backend/Dockerfile` | Build backend image | Production-only deps |
| `frontend/Dockerfile` | Build frontend image | Multi-stage build |
| `nginx.conf` | Web server config | SPA routing support |
| `.dockerignore` | Exclude files | Faster builds |
| `docker-compose.yml` | Local orchestration | One-command start |
| `namespace.yaml` | Isolation | Resource grouping |
| `mongodb-deployment.yaml` | Database | Persistent storage |
| `backend-deployment.yaml` | API server | Health checks + scaling |
| `frontend-deployment.yaml` | Web app | Load balancing |
| `configmap.yaml` | Config | Environment variables |
| `secret.yaml` | Secrets | Secure storage |
| `ingress.yaml` | Routing | External access |
| `build-docker.sh` | Build script | Automation |
| `deploy-kubernetes.sh` | Deploy script | One-command deploy |

---

## 🚀 Quick Reference

**Docker:**
```bash
docker-compose up --build        # Build and start
docker-compose down              # Stop
docker-compose logs -f           # View logs
```

**Kubernetes:**
```bash
kubectl apply -f kubernetes/     # Deploy all
kubectl get pods -n fullstack-app # Check status
kubectl logs -f deployment/backend -n fullstack-app  # View logs
kubectl delete namespace fullstack-app  # Cleanup
```

This setup provides a production-ready, scalable, and maintainable deployment infrastructure! 🎉


