# [yolomy](http://4.255.32.247) E-commerce Kubernetes Orchestration

A comprehensive guide to deploying a full-stack e-commerce application on Azure Kubernetes Service (AKS), implementing StatefulSets for persistent storage, load balancing, and production-ready container orchestration.

## 📋 Prerequisites

Before starting this project, ensure you have the following installed and configured:

### Required Software

- **Docker Desktop** (latest version) - [Download here](https://www.docker.com/products/docker-desktop/)
- **kubectl** (latest version) - [Installation guide](https://kubernetes.io/docs/tasks/tools/)
- **Azure CLI** (latest version) - [Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Git** - [Download here](https://git-scm.com/)

### Required Accounts

- **Azure Account** with active subscription - [Sign up here](https://azure.microsoft.com/free/)
- **DockerHub Account** with pushed images from previous containerization

### Pre-requisites from Previous Stages

- Completed containerization stage with images:
  - `doc0pz/yolo-client:v1.2.1`
  - `doc0pz/yolo-server:v1.2.1`
- Local testing completed with minikube or Docker Compose

## 🏗️ Project Structure

```
yolo/
├── k8s/
│   ├── namespace.yml
│   ├── mongo-statefulset.yml
│   ├── redis-deployment.yml
│   ├── backend-deployment.yml
│   ├── frontend-deployment.yml
│   ├── services.yml
│   ├── README.md
│   └── explanation.md
├── backend/
├── client/
├── docker-compose.yml
└── README.md
```

## 🚀 Step-by-Step Implementation

### Step 1: Azure CLI Setup and Authentication

#### 1.1 Install Azure CLI

```bash
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS with Homebrew
brew install azure-cli

# Verify installation
az --version
```

#### 1.2 Login to Azure

```bash
# Login to Azure account
az login

# Select subscription if you have multiple
az account list --output table
az account set --subscription "your-subscription-id"
```

### Step 2: Azure Kubernetes Service (AKS) Cluster Creation

#### 2.1 Create Resource Group

```bash
# Create resource group in East US region
az group create --name yolo-k8s-rg --location eastus
```

**Expected output:**
```json
{
  "id": "/subscriptions/{subscription-id}/resourceGroups/yolo-k8s-rg",
  "location": "eastus",
  "name": "yolo-k8s-rg",
  "properties": {
    "provisioningState": "Succeeded"
  }
}
```

#### 2.2 Register Required Providers

```bash
# Register necessary Azure providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Insights

# Verify registration status
az provider show --namespace Microsoft.ContainerService --query "registrationState"
```

#### 2.3 Create AKS Cluster

```bash
# Create AKS cluster with monitoring enabled
az aks create \
  --resource-group yolo-k8s-rg \
  --name yolo-k8s-cluster \
  --node-count 2 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --node-vm-size Standard_B2s
```

**Note**: Cluster creation takes 5-10 minutes.

### Step 3: Connect to AKS Cluster

#### 3.1 Get Cluster Credentials

```bash
# Download cluster credentials
az aks get-credentials --resource-group yolo-k8s-rg --name yolo-k8s-cluster

# Verify connection
kubectl get nodes
```

**Expected output:**
```
NAME                                STATUS   ROLES    AGE   VERSION
aks-nodepool1-xxxxx-vmss000000     Ready    <none>   5m    v1.32.6
aks-nodepool1-xxxxx-vmss000001     Ready    <none>   5m    v1.32.6
```

### Step 4: Kubernetes Manifests Creation

#### 4.1 Create Namespace Configuration

Create `k8s/namespace.yml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: yolo
  labels:
    name: yolo
    app: yolo-ecommerce
  annotations:
    description: "YOLO E-commerce application namespace"
```

#### 4.2 Create MongoDB StatefulSet

Create `k8s/mongo-statefulset.yml`:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
  namespace: yolo
  labels:
    app: mongodb
    component: database
spec:
  serviceName: mongodb-service
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
        component: database
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - name: mongodb
        image: mongo:4.4
        ports:
        - containerPort: 27017
          name: mongo-port
        env:
        - name: MONGO_INITDB_DATABASE
          value: "yolo"
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          exec:
            command:
            - mongo
            - --eval
            - "db.adminCommand('ismaster')"
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          exec:
            command:
            - mongo
            - --eval
            - "db.adminCommand('ismaster')"
          initialDelaySeconds: 30
          periodSeconds: 30
  volumeClaimTemplates:
  - metadata:
      name: mongo-persistent-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "managed-csi"
      resources:
        requests:
          storage: 2Gi
```

#### 4.3 Create Redis Deployment

Create `k8s/redis-deployment.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
  namespace: yolo
  labels:
    app: redis
    component: cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        component: cache
      annotations:
        description: "Redis cache for YOLO application"
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
          name: redis-port
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        readinessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
```

#### 4.4 Create Backend Deployment

Create `k8s/backend-deployment.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: yolo
  labels:
    app: backend
    component: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        component: api
    spec:
      containers:
      - name: backend
        image: doc0pz/yolo-server:v1.2.1
        ports:
        - containerPort: 5002
          name: http-port
        env:
        - name: MONGODB_URI
          value: "mongodb://mongodb-service:27017/yolo"
        - name: PORT
          value: "5002"
        - name: NODE_ENV
          value: "production"
        - name: REDIS_HOST
          value: "redis-service"
        - name: REDIS_PORT
          value: "6379"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
        readinessProbe:
          httpGet:
            path: /api/products
            port: 5002
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /api/products
            port: 5002
          initialDelaySeconds: 30
          periodSeconds: 10
```

#### 4.5 Create Frontend Deployment

Create `k8s/frontend-deployment.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: yolo
  labels:
    app: frontend
    component: ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        component: ui
    spec:
      securityContext:
        runAsUser: 0
      containers:
      - name: frontend
        image: doc0pz/yolo-client:v1.2.1
        ports:
        - containerPort: 80
          name: http-port
        env:
        - name: REACT_APP_BACKEND_URL
          value: "http://backend-service:5002"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
```

#### 4.6 Create Services Configuration

Create `k8s/services.yml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: yolo
  labels:
    app: mongodb
spec:
  clusterIP: None
  ports:
  - port: 27017
    targetPort: 27017
    name: mongo-port
  selector:
    app: mongodb
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: yolo
  labels:
    app: redis
spec:
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
    name: redis-port
  selector:
    app: redis
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: yolo
  labels:
    app: backend
spec:
  type: ClusterIP
  ports:
  - port: 5002
    targetPort: 5002
    name: http-port
  selector:
    app: backend
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: yolo
  labels:
    app: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    name: http-port
  selector:
    app: frontend
```

### Step 5: Deploy Application to AKS

#### 5.1 Apply Kubernetes Manifests

Deploy in the following order to ensure dependencies:

```bash
# Create namespace
kubectl apply -f k8s/namespace.yml

# Deploy StatefulSet for database
kubectl apply -f k8s/mongo-statefulset.yml

# Deploy cache layer
kubectl apply -f k8s/redis-deployment.yml

# Deploy services
kubectl apply -f k8s/services.yml

# Deploy backend API
kubectl apply -f k8s/backend-deployment.yml

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yml
```

#### 5.2 Verify Deployment Status

```bash
# Check all pods are running
kubectl get pods -n yolo

# Verify services are created
kubectl get services -n yolo

# Check persistent volumes
kubectl get pv,pvc -n yolo
```

**Expected output:**
```
NAME                                READY   STATUS    RESTARTS   AGE
backend-54b7597654-xxxxx            1/1     Running   0          5m
backend-54b7597654-yyyyy            1/1     Running   0          5m
frontend-768b57887f-zzzzz           1/1     Running   0          4m
mongodb-0                           1/1     Running   0          6m
redis-deployment-84f8c47578-aaaaa   1/1     Running   0          5m
```

#### 5.3 Wait for External IP Assignment

```bash
# Monitor LoadBalancer service for external IP
kubectl get service frontend-service -n yolo --watch
```

**Expected progression:**
```
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
frontend-service   LoadBalancer   10.0.220.157   <pending>     80:32188/TCP   2m
frontend-service   LoadBalancer   10.0.220.157   4.255.32.247  80:32188/TCP   3m
```

### Step 6: Application Access and Testing

#### 6.1 Access Your Live Application

Once external IP is assigned, access your application at:

**🎉 Live Application URL: `http://4.255.32.247`**

#### 6.2 Test Application Functionality

1. **Frontend Access**: Navigate to the external IP in your browser
2. **Product Management**: Test adding, viewing, editing, and deleting products
3. **Data Persistence**: Verify data survives pod restarts

#### 6.3 Verify Persistent Storage

Test StatefulSet persistence:

```bash
# Delete MongoDB pod to test persistence
kubectl delete pod mongodb-0 -n yolo

# Watch pod recreation
kubectl get pods -n yolo -w

# Verify data persistence after restart
kubectl exec -it mongodb-0 -n yolo -- mongo yolo --eval "db.products.find()"
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Pod CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n yolo

# Describe pod for events
kubectl describe pod <pod-name> -n yolo
```

#### External IP Stuck in Pending

```bash
# Check LoadBalancer service events
kubectl describe service frontend-service -n yolo

# Verify AKS cluster has proper permissions
az aks show --resource-group yolo-k8s-rg --name yolo-k8s-cluster
```

#### Database Connection Issues

```bash
# Test MongoDB connectivity
kubectl exec -it mongodb-0 -n yolo -- mongo --eval "db.adminCommand('ismaster')"

# Check service endpoints
kubectl get endpoints -n yolo
```

## 📊 Architecture Overview

This Kubernetes deployment implements:

- **Frontend**: React application with LoadBalancer service for external access
- **Backend**: Node.js API with horizontal scaling (2 replicas)
- **Database**: MongoDB StatefulSet with persistent storage (2Gi)
- **Cache**: Redis deployment for session management
- **Networking**: ClusterIP services for internal communication
- **Storage**: Managed-CSI persistent volumes for data persistence
- **Security**: Resource limits, health checks, and proper service exposure

## 🔗 Production Considerations

### Security Enhancements
- Implement Network Policies for traffic restriction
- Use Kubernetes Secrets for sensitive data
- Configure RBAC for service accounts
- Enable Pod Security Standards

### Monitoring and Logging
- Azure Monitor integration enabled
- Container insights for performance monitoring
- Log Analytics workspace for centralized logging

### High Availability
- Multi-replica deployments for critical services
- Anti-affinity rules for pod distribution
- ReadinessProbe and LivenessProbe for health monitoring

## 📝 Key Features

✅ **StatefulSet Implementation** for persistent database storage  
✅ **Horizontal Pod Autoscaling** capability with resource limits  
✅ **LoadBalancer Service** for external internet access  
✅ **Persistent Volumes** using Azure Managed Disks  
✅ **Health Checks** with readiness and liveness probes  
✅ **Production-ready** Azure Kubernetes Service deployment  

## 🎯 Success Criteria

- [x] AKS cluster created and configured successfully
- [x] All Kubernetes manifests deployed without errors
- [x] StatefulSet maintains data persistence across pod restarts
- [x] LoadBalancer service provides external IP access
- [x] Application fully functional with CRUD operations
- [x] Persistent storage working with 2Gi allocation
- [x] Live application accessible at: **http://4.255.32.247**

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Kubernetes StatefulSets Guide](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [kubectl Command Reference](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Azure Monitor for Containers](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/)