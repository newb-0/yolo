# [yolomy](http://4.255.32.247) E-commerce Microservice Containerization

A comprehensive guide to containerizing an e-commerce application using Docker and Docker Compose, implementing microservice architecture with MongoDB Atlas integration.

## 📋 Prerequisites

Before starting this project, ensure you have the following installed and configured:

### Required Software

- **Docker Desktop** (latest version) - [Download here](https://www.docker.com/products/docker-desktop/)
- **Docker Compose** (comes with Docker Desktop)
- **Node.js** (v18 or higher) - [Download here](https://nodejs.org/)
- **Git** - [Download here](https://git-scm.com/)
- **Code Editor** (VS Code recommended)

### Required Accounts

- **DockerHub Account** - [Sign up here](https://hub.docker.com/)
- **MongoDB Atlas Account** - [Sign up here](https://www.mongodb.com/cloud/atlas)

### MongoDB Atlas Configuration

1. Create a MongoDB Atlas cluster
2. **Important**: Configure network access to allow connections from anywhere (0.0.0.0/0) for development
3. Create a database user with read/write permissions
4. Obtain your MongoDB connection string

## 🏗️ Project Structure

```
yolo/
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── server.js
│   ├── models/
│   └── routes/
├── client/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── src/
├── docker-compose.yml
├── .env
├── README.md
└── explanation-microservice.md
```

## 🚀 Step-by-Step Implementation

### Step 1: Environment Configuration

Create a `.env` file in the project root:

```bash
# Docker Network Configuration
CLIENT_IP=172.18.0.2
SERVER_IP=172.18.0.3
REDIS_IP=172.18.0.5
APP_SUBNET=172.18.0.0/16
APP_IP_RANGE=172.18.0.0/24
APP_GATEWAY=172.18.0.1

# Frontend Configuration
REACT_APP_BACKEND_URL=http://localhost:5002

# MongoDB Atlas Configuration
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/yolo?retryWrites=true&w=majority
```

**Important**: Replace `username`, `password`, and `cluster` with your MongoDB Atlas credentials.

### Step 2: Backend Configuration

#### 2.1 Update server.js

Add environment variable support to `backend/server.js`:

```javascript
require("dotenv").config(); // Add this at the top

// Update MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || mongodb_url + dbName
console.log('Using Mongo URI:', MONGODB_URI);

// Update port configuration
const PORT = process.env.PORT || 5002
```

#### 2.2 Install dotenv dependency

```bash
cd backend
npm install dotenv
```

**Expected output:**

```bash
added 1 package, and audited packages
found 0 vulnerabilities
```

#### 2.3 Create Backend Dockerfile

Create `backend/Dockerfile` with multi-stage build:

```dockerfile
# Stage 1: Build dependencies
FROM node:18-alpine AS builder
WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install production-only dependencies
RUN npm ci --omit=dev --ignore-scripts && \
    npm cache clean --force

# Stage 2: Compress and optimize
FROM alpine:3.18 AS compressor
WORKDIR /app

# Copy dependencies and application code
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Install optimization tools and clean up
RUN apk add --no-cache upx binutils && \
    find node_modules -name "*.node" -exec upx --best --lzma {} \; && \
    find node_modules -name "*.node" -exec strip -s {} \; && \
    find . \( -name "*.md" -o -name "*.ts" -o -name "*.map" \) -delete && \
    find . \( -name "__tests__" -o -name "test" -o -name "tests" -o -name "example*" \) -exec rm -rf {} + && \
    find node_modules -name "*.node" -exec sh -c 'file {} | grep -v "x86-64" && rm {}' \; || true && \
    rm -rf /var/cache/apk/*

# Stage 3: Minimal runtime
FROM gcr.io/distroless/nodejs18-debian11
ENV NODE_ENV=production

# Copy optimized application
WORKDIR /app
COPY --from=compressor --chown=nonroot:nonroot /app ./

# Security and runtime configuration
USER nonroot
EXPOSE 5002
CMD ["server.js"]
```

#### 2.4 Create backend/.dockerignore

```
# Exclude everything except essential files
*
!server.js
!models
!routes
!package*.json
```

### Step 3: Frontend Configuration

#### 3.1 Update ProductControl.js

Add environment variable support to `client/src/components/ProductControl.js`:

```javascript
const API_BASE_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:5002';

// Replace all hardcoded URLs with:
axios.get(`${API_BASE_URL}/api/products`)
axios.post(`${API_BASE_URL}/api/products`, newProduct)
axios.delete(`${API_BASE_URL}/api/products/` + id)
axios.put(`${API_BASE_URL}/api/products/` + this.state.selectedProduct._id, editedProduct)
```

#### 3.2 Create Frontend Dockerfile

Create `client/Dockerfile` with optimized build:

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --production=false --ignore-scripts --legacy-peer-deps
COPY . .
RUN npm run build -- --openssl-legacy-provider

# Production stage
FROM alpine:3.18 AS final

# Configure reliable Alpine mirrors and install lighttpd
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk add --no-cache lighttpd

# Copy build output
WORKDIR /var/www/localhost/htdocs
COPY --from=builder /app/build .

# Configure lighttpd
RUN echo 'server.modules = ("mod_access", "mod_accesslog")' > /etc/lighttpd/lighttpd.conf && \
    echo 'server.document-root = "/var/www/localhost/htdocs"' >> /etc/lighttpd/lighttpd.conf && \
    echo 'index-file.names = ("index.html")' >> /etc/lighttpd/lighttpd.conf && \
    echo 'mimetype.assign = ( \
    ".html" => "text/html", \
    ".js" => "application/javascript", \
    ".css" => "text/css", \
    ".png" => "image/png", \
    ".jpg" => "image/jpeg", \
    ".jpeg" => "image/jpeg", \
    ".svg" => "image/svg+xml", \
    ".ico" => "image/x-icon" \
    )' >> /etc/lighttpd/lighttpd.conf

# Security hardening
RUN find . -type d -exec chmod 555 {} \; && \
    find . -type f -exec chmod 444 {} \; && \
    adduser -S static -u 1000 && \
    chown -R static:root .

USER static
EXPOSE 80
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
```

#### 3.3 Create client/.dockerignore

```
# Exclude everything except production essentials
*
!public
!src
!package*.json
```

### Step 4: Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
services:
  client:
    build:
      context: ./client
    container_name: yolo-client
    ports:
      - "3000:80"
    networks:
      - appnet
    depends_on:
      server:
        condition: service_started
    environment:
      - REACT_APP_BACKEND_URL=http://server:5002

  server:
    build:
      context: ./backend  
    container_name: yolo-server
    ports:
      - "5002:5002"
    networks:
      - appnet
    environment:
      - NODE_ENV=production
      - MONGODB_URI=${MONGODB_URI}
      - PORT=5002
    depends_on:
      - redis

  redis:
    image: redis:alpine
    container_name: yolo-redis
    networks:
      - appnet

networks:
  appnet:
    driver: bridge
```

### Step 5: Build and Deploy

#### 5.1 Build and Run Containers

```bash
docker compose up -d --build
```

**Expected output:**

```bash
[+] Running 9/9
 ✔ yolo-server                   Built                                                                                                                      
 ✔ yolo-client                   Built                                                                                                                      
 ✔ Network yolo_appnet           Created                                                                                                                    
 ✔ Volume "yolo_mongodb_data"    Created                                                                                                                    
 ✔ Volume "yolo_mongodb_config"  Created                                                                                                                    
 ✔ Container mongodb             Started                                                                                                                    
 ✔ Container redis               Started                                                                                                                    
 ✔ Container server              Started                                                                                                                    
 ✔ Container client              Started
```

#### 5.2 Verify Container Status

```bash
docker ps
```

**Expected output:**

```bash
CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS          PORTS                      NAMES
abc123def456   yolo-client     "lighttpd -D -f /etc…"   2 minutes ago    Up 2 minutes    0.0.0.0:3000->80/tcp      client
def456ghi789   yolo-server     "server.js"              2 minutes ago    Up 2 minutes                               server
ghi789jkl012   redis:alpine    "docker-entrypoint.s…"   2 minutes ago    Up 2 minutes    6379/tcp                   redis
jkl012mno345   mongo:7.0-jammy "docker-entrypoint.s…"   2 minutes ago    Up 2 minutes    0.0.0.0:27017->27017/tcp  mongodb
```

#### 5.3 Check Application Access

- **Frontend**: <http://localhost:3000>
- **Backend API**: <http://localhost:5002/api/products>
- **MongoDB**: localhost:27017

### Step 6: Image Tagging and DockerHub Deployment

#### 6.1 Tag Images with Version

```bash
docker tag yolo-client:latest yourusername/yolo-client:1.0.0
docker tag yolo-server:latest yourusername/yolo-server:1.0.0
```

#### 6.2 Login to DockerHub

```bash
docker login
```

**Expected output:**

```bash
Authenticating with existing credentials... [Username: yourusername]
Login Succeeded
```

#### 6.3 Push Images to DockerHub

```bash
docker push yourusername/yolo-client:1.0.0
docker push yourusername/yolo-server:1.0.0
```

**Expected output:**

```bash
The push refers to repository [docker.io/yourusername/yolo-client]
d3fd068bb74b: Pushed 
0b40d1f75b50: Pushed 
...
1.0.0: digest: sha256:cbd8aa6760677d2391ad53a414fa7880faef28dddfaa34215a140e68de543c77 size: 1574
```

### Step 7: Testing Application Functionality

#### 7.1 Test Product Addition

1. Navigate to <http://localhost:3000>
2. Click "Add a product"
3. Fill in product details:
   - Name: "Test Product"
   - Price: "99"
   - Description: "Test description"
   - Quantity: "10"
4. Click "Submit"

#### 7.2 Verify Data Persistence

Test container restart persistence:

```bash
docker compose down
docker compose up -d
```

Navigate to <http://localhost:3000> - previously added products should still be visible.

## 🔧 Troubleshooting

### Common Port Conflicts

If you encounter port 5000 conflicts:

```bash
# Check what's using port 5000
lsof -i :5000

# Kill the process if necessary
sudo kill -9 <PID>
```

### Database Connection Issues

1. Verify MongoDB Atlas IP whitelist includes 0.0.0.0/0
2. Check connection string format in `.env`
3. Test connection:

```bash
docker logs server
```

### Container Build Issues

Clear Docker cache if builds fail:

```bash
docker system prune -a
docker compose build --no-cache
```

### Image Size Verification

```bash
docker images | grep yolo
```

**Expected output:**

```bash
yourusername/yolo-client    1.0.0    f3eb95b546c5    2 days ago    15.5MB
yourusername/yolo-server    1.0.0    217c1b2369b5    2 days ago    130MB
```

## 📊 Architecture Overview

This microservice implementation includes:

- **Frontend**: React application served by lighttpd (Port 3000)
- **Backend**: Node.js API server (Port 5002)
- **Database**: MongoDB Atlas (cloud-hosted)
- **Cache**: Redis (containerized)
- **Networking**: Custom bridge network for service communication
- **Persistence**: Docker volumes for local MongoDB data

## 🔗 Technical Implementation Details

For detailed explanations of technical decisions, image selections, networking configurations, and implementation reasoning, see: [explanation-microservice.md](./explanation-microservice.md)

## 📝 Key Features

✅ **Multi-stage Docker builds** for optimized image sizes  
✅ **Container orchestration** with Docker Compose  
✅ **Data persistence** across container restarts  
✅ **Environment-based configuration**  
✅ **Security hardening** with non-root users  
✅ **Production-ready deployment** to DockerHub  

## 🎯 Success Criteria

- [ ] All containers build and run successfully
- [ ] Application accessible at <http://localhost:3000>
- [ ] Product CRUD operations work correctly
- [ ] Data persists after container restarts
- [ ] Images deployed to DockerHub with proper versioning
- [ ] Total image size under 145.5MB (well optimized)
