# [Yolomy](http://4.255.32.247) E-commerce Kubernetes Orchestration

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

- Completed containerization stage with images pushed to DockerHub:
  - `your-dockerhub-username/yolo-client:v1.2.x`
  - `your-dockerhub-username/yolo-server:v1.2.x`
- Local testing completed with Docker Compose

## 🏗️ Project Structure

```
yolo/
├── k8s/
│   ├── namespace.yml
│   ├── mongodb-secret.yml
│   ├── mongo-statefulset.yml
│   ├── redis-deployment.yml
│   ├── backend-deployment.yml
│   ├── frontend-deployment.yml
│   └── services.yml
├── documentation/orchestration/
│   ├── README.md
│   └── explanation-kubernetes.md
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

# Windows (via PowerShell)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Verify installation
az --version
```

#### 1.2 Login to Azure

```bash
# Login to Azure account
az login

# List available subscriptions
az account list --output table

# Set active subscription (if multiple)
az account set --subscription "your-subscription-id"

# Verify current subscription
az account show
```

### Step 2: Azure Kubernetes Service (AKS) Cluster Setup

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

#### 2.2 Register Azure Providers

```bash
# Register necessary Azure providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Insights

# Verify registration status
az provider list --query "[?namespace=='Microsoft.ContainerService'].{Provider:namespace, Status:registrationState}" --output table
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
  --node-vm-size Standard_B2s \
  --kubernetes-version 1.32.6
```

**Note**: Cluster creation takes 5-10 minutes. Monitor progress in Azure portal.

#### 2.4 Connect to AKS Cluster

```bash
# Download cluster credentials
az aks get-credentials --resource-group yolo-k8s-rg --name yolo-k8s-cluster

# Verify connection and context
kubectl config get-contexts
kubectl get nodes
```

**Expected output:**

```
NAME                                STATUS   ROLES    AGE   VERSION
aks-nodepool1-xxxxx-vmss000000     Ready    <none>   5m    v1.32.6
aks-nodepool1-xxxxx-vmss000001     Ready    <none>   5m    v1.32.6
```

### Step 3: Prepare Application Secrets and Configuration

#### 3.1 Create MongoDB Atlas Connection (Optional)

If using MongoDB Atlas instead of local MongoDB:

```bash
# Create MongoDB secret for Atlas connection
echo -n "your-mongodb-atlas-connection-string" | base64
```

Create `k8s/mongodb-secret.yml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
  namespace: yolo
type: Opaque
data:
  mongodb-uri: <base64-encoded-connection-string>
```

### Step 4: Kubernetes Manifests Deployment

#### 4.1 Create Application Namespace

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

Apply namespace:

```bash
kubectl apply -f k8s/namespace.yml
```

#### 4.2 Deploy MongoDB StatefulSet

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

Deploy StatefulSet:

```bash
kubectl apply -f k8s/mongo-statefulset.yml
```

#### 4.3 Deploy Application Services

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
  type: LoadBalancer
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

Deploy services:

```bash
kubectl apply -f k8s/services.yml
```

#### 4.4 Deploy Application Components

Deploy Redis cache:

```bash
# Create k8s/redis-deployment.yml and apply
kubectl apply -f k8s/redis-deployment.yml
```

Deploy backend API:

```bash
# Create k8s/backend-deployment.yml with your Docker images and apply
kubectl apply -f k8s/backend-deployment.yml
```

Wait for backend LoadBalancer IP:

```bash
kubectl get service backend-service -n yolo --watch
```

Once backend external IP is assigned, update frontend deployment with backend URL and deploy:

```bash
# Update k8s/frontend-deployment.yml with backend external IP
# Build new frontend image with correct backend URL:
cd client
docker build --build-arg REACT_APP_BACKEND_URL=http://BACKEND_EXTERNAL_IP:5002 -t your-dockerhub-username/yolo-client:v1.2.3 .
docker push your-dockerhub-username/yolo-client:v1.2.3

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yml
```

### Step 5: Verify Deployment and Access Application

#### 5.1 Check Deployment Status

```bash
# Verify all pods are running
kubectl get pods -n yolo

# Check services and external IPs
kubectl get services -n yolo

# Verify persistent volumes
kubectl get pv,pvc -n yolo
```

#### 5.2 Monitor LoadBalancer IP Assignment

```bash
# Watch for frontend service external IP
kubectl get service frontend-service -n yolo --watch
```

Wait until `EXTERNAL-IP` shows an actual IP address instead of `<pending>`.

#### 5.3 Access Live Application

Once external IP is assigned (e.g., `4.255.32.247`), access your application:

**🎉 Live Application URL: `http://YOUR_EXTERNAL_IP`**

### Step 6: Testing and Validation

#### 6.1 Application Functionality Testing

1. **Frontend Access**: Navigate to the external IP in your browser
2. **Product Management**: Test CRUD operations (Create, Read, Update, Delete products)
3. **Data Persistence**: Add products and verify they persist after pod restarts

#### 6.2 Persistent Storage Validation

Test StatefulSet data persistence:

```bash
# Add some products through the web interface first, then test persistence

# Delete MongoDB pod to test data persistence
kubectl delete pod mongodb-0 -n yolo

# Watch pod recreation
kubectl get pods -n yolo --watch

# Verify data persisted after pod restart
kubectl exec -it mongodb-0 -n yolo -- mongo yolo --eval "db.products.find().pretty()"
```

#### 6.3 Scaling Test

```bash
# Scale backend deployment
kubectl scale deployment backend --replicas=3 -n yolo

# Verify scaling
kubectl get pods -n yolo -l app=backend
```

## 🛠️ Context Switching and Troubleshooting

### Switching Between Kubernetes Contexts

```bash
# List available contexts
kubectl config get-contexts

# Switch to AKS context (if multiple clusters)
kubectl config use-context yolo-k8s-cluster

# Verify current context
kubectl config current-context
```

### Common Troubleshooting Commands

#### Pod Issues

```bash
# Check pod status and events
kubectl get pods -n yolo
kubectl describe pod <pod-name> -n yolo

# View pod logs
kubectl logs <pod-name> -n yolo
kubectl logs -f <pod-name> -n yolo  # Follow logs

# Access pod shell for debugging
kubectl exec -it <pod-name> -n yolo -- /bin/bash
```

#### Service and Network Issues

```bash
# Check service endpoints
kubectl get endpoints -n yolo

# Test internal connectivity
kubectl run debug --image=busybox -n yolo --rm -it --restart=Never -- nslookup backend-service

# Port forwarding for local testing
kubectl port-forward service/backend-service -n yolo 5002:5002
```

#### Storage Issues

```bash
# Check persistent volumes and claims
kubectl get pv,pvc -n yolo

# Describe storage issues
kubectl describe pvc mongo-persistent-storage-mongodb-0 -n yolo
```

### LoadBalancer IP Troubleshooting

If external IP remains `<pending>`:

```bash
# Check LoadBalancer service events
kubectl describe service frontend-service -n yolo
kubectl describe service backend-service -n yolo

# Verify Azure LoadBalancer provisioning
az network lb list --resource-group MC_yolo-k8s-rg_yolo-k8s-cluster_eastus
```

## 📊 Architecture Overview

This Kubernetes deployment implements:

- **Frontend**: React application with LoadBalancer service for external access
- **Backend**: Node.js API with LoadBalancer service and horizontal scaling (2 replicas)
- **Database**: MongoDB StatefulSet with persistent storage (2Gi Azure Managed Disk)
- **Cache**: Redis deployment for session management
- **Networking**: External LoadBalancer services for frontend and backend access
- **Storage**: Azure Managed-CSI persistent volumes for data persistence
- **Security**: Resource limits, health checks, and proper namespace isolation

## 🔗 Production Considerations

### Security Enhancements

- Implement Network Policies for traffic restriction
- Use Kubernetes Secrets for sensitive data (MongoDB credentials)
- Configure RBAC for service accounts
- Enable Pod Security Standards

### Monitoring and Logging

- Azure Monitor integration enabled during cluster creation
- Container insights for performance monitoring
- Log Analytics workspace for centralized logging

### High Availability

- Multi-replica deployments for critical services
- ReadinessProbe and LivenessProbe for health monitoring
- StatefulSet for data persistence and ordered deployment

## 📝 Key Implementation Features

✅ **StatefulSet Implementation** - MongoDB with persistent storage and ordered deployment  
✅ **LoadBalancer Services** - External access for both frontend and backend  
✅ **Persistent Volumes** - 2Gi Azure Managed Disk with CSI driver  
✅ **Health Checks** - Readiness and liveness probes for all services  
✅ **Resource Management** - CPU and memory limits for optimal performance  
✅ **Horizontal Scaling** - Multiple backend replicas for load distribution  
✅ **Production-ready** - Azure Kubernetes Service with monitoring integration  

## 🎯 Success Criteria Checklist

- [x] AKS cluster created and configured successfully
- [x] StatefulSet implemented for database with persistent storage
- [x] All Kubernetes manifests deployed without errors
- [x] LoadBalancer services provide external IP access
- [x] Application fully functional with CRUD operations
- [x] Data persistence verified across pod restarts
- [x] Live application accessible externally

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Kubernetes StatefulSets Guide](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [kubectl Command Reference](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Azure Monitor for Containers](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/)
