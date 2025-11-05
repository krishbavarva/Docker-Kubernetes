# Frontend Dockerfile - Multi-stage build
FROM node:14-alpine AS builder

WORKDIR /app

# Upgrade npm to support lockfile v2
RUN npm install -g npm@8

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --legacy-peer-deps

# Copy application code
COPY . .

# Build argument for API URL
ARG REACT_APP_BASE_URL=http://localhost:3001
ENV REACT_APP_BASE_URL=$REACT_APP_BASE_URL

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
