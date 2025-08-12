# [yolomy](http://4.255.32.247) E-commerce Platform - DevOps Implementation Journey

A comprehensive multi-stage DevOps implementation showcasing the evolution from containerized microservices to fully automated infrastructure provisioning, configuration management, and Kubernetes orchestration.

<a href="./yolomy-ui.png" target="_blank">
  <img src="./yolomy-ui.png" alt="Yolomy DockerHub Image Screenshot" style="max-width:100%; height:auto;">
</a>

## 🎯 Project Overview

This project demonstrates the complete DevOps lifecycle implementation for a modern e-commerce application, progressing through four distinct stages:

1. **Microservices Containerization** - Docker-based containerization
2. **Configuration Management** - Automated deployment with Ansible
3. **Infrastructure as Code** - Complete automation with Terraform + Ansible
4. **Container Orchestration** - Production-ready Kubernetes deployment

## 🏗️ Architecture Evolution

```
Stage 1: Containerization    →    Stage 2: Automation    →    Stage 3: IaC    →    Stage 4: Orchestration
┌─────────────────────┐         ┌─────────────────────┐       ┌─────────────────────┐       ┌─────────────────────┐
│   Docker Compose    │         │   Ansible Playbook │       │  Terraform + Ansible│       │  Kubernetes (AKS)   │
│   Manual Deployment │         │   Vagrant VM        │       │   Cloud Infrastructure│       │   Container Orchestr.│
│   Local Development │         │   Automated Config  │       │   Full Automation    │       │   Production Ready   │
└─────────────────────┘         └─────────────────────┘       └─────────────────────┘       └─────────────────────┘
```

## 📚 Implementation Stages

### Stage 1: Microservices Containerization

**Objective**: Transform a monolithic application into containerized microservices using Docker.

**Key Technologies**: Docker, Docker Compose, Multi-container orchestration

**Achievements**:

- ✅ Containerized React frontend and Node.js backend
- ✅ MongoDB and Redis service containers
- ✅ Docker Compose orchestration
- ✅ Data persistence with Docker volumes
- ✅ Network isolation and service communication

**Documentation**:

- 📖 [Microservices Implementation Guide](./documentation/containerization/README.md)
- 🔧 [Technical Architecture & Decisions](./documentation/containerization/explanation-microservice.md)

---

### Stage 2: Configuration Management (Ansible)

**Objective**: Automate the deployment and configuration of containerized services using Ansible with Vagrant-provisioned infrastructure.

**Key Technologies**: Ansible, Vagrant, Infrastructure as Code, Automated Provisioning

**Achievements**:

- ✅ Ansible playbook automation
- ✅ Role-based task organization
- ✅ Vagrant VM provisioning
- ✅ Automated Docker deployment
- ✅ Tag-based deployment control
- ✅ Idempotent infrastructure management

**Documentation**:

- 📖 [Ansible Configuration Management Guide](./documentation/automation/README.md)
- 🔧 [Automation Architecture & Technical Reasoning](./documentation/automation/explanation-ansible.md)

---

### Stage 3: Infrastructure as Code (Terraform + Ansible)

**Objective**: Complete infrastructure automation combining Terraform for resource provisioning with Ansible for configuration management.

**Key Technologies**: Terraform, Ansible Integration, Cloud Infrastructure, Complete Automation Pipeline

**Status**: ✅ **Completed**

**Achievements**:

- ✅ Terraform infrastructure provisioning
- ✅ Ansible + Terraform integration
- ✅ Cloud resource management
- ✅ State management and versioning
- ✅ Complete deployment automation
- ✅ Production-ready infrastructure

**Documentation**:

- 📖 [Infrastructure as Code Guide](./documentation/IaC/README.md)
- 🔧 [Terraform Architecture & Implementation](./documentation/IaC/explanation-terraform.md)

---

### Stage 4: Container Orchestration (Kubernetes)

**Objective**: Deploy and orchestrate containerized services on Azure Kubernetes Service (AKS) with production-ready features including StatefulSets, persistent storage, and load balancing.

**Key Technologies**: Kubernetes, Azure Kubernetes Service (AKS), StatefulSets, Persistent Volumes, LoadBalancer

**Achievements**:

- ✅ AKS cluster deployment and configuration
- ✅ StatefulSet implementation for MongoDB with persistent storage
- ✅ Horizontal pod autoscaling and load balancing
- ✅ Production-ready service exposure with LoadBalancer
- ✅ Resource management with limits and health checks
- ✅ Live production deployment with external access

**Live Application**: 🚀 **[http://4.255.32.247](http://4.255.32.247)**

**Documentation**:

- 📖 [Kubernetes Orchestration Implementation Guide](./documentation/orchestration/README.md)
- 🔧 [Orchestration Architecture & Technical Decisions](./documentation/orchestration/explanation-kubernetes.md)

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Vagrant & VirtualBox
- Ansible (2.9+)
- kubectl & Azure CLI
- Git

### Stage 1 - Containerization

```bash
git clone <repository-url>
cd yolo
docker-compose up -d
# Application available at http://localhost:3000
```

### Stage 2 - Ansible Automation

```bash
git checkout feature/ansible-stage1
vagrant up
# Application available at http://localhost:3100
```

### Stage 3 - Terraform + Ansible

```bash
git checkout Stage_two
cd Stage_two
vagrant up
# Terraform provisioning + Ansible configuration
```

### Stage 4 - Kubernetes Orchestration

```bash
git checkout feature/kubernetes
# Deploy to AKS cluster
kubectl apply -f k8s/
# Live application at http://4.255.32.247
```

## 📊 Technology Stack Comparison

| Component | Stage 1 | Stage 2 | Stage 3 | Stage 4 |
|-----------|---------|---------|---------|---------|
| **Containerization** | Docker Compose | Ansible + Docker | Terraform + Ansible + Docker | Kubernetes Orchestration |
| **Infrastructure** | Local Docker | Vagrant VM | Cloud Resources | Azure Kubernetes Service |
| **Automation Level** | Manual Commands | Ansible Playbooks | Full IaC Pipeline | Container Orchestration |
| **Configuration** | Manual | Automated | Declarative | Cloud-native |
| **Scalability** | Single Host | VM-based | Cloud-native | Auto-scaling Pods |
| **Production Ready** | Development | Staging | Production | Enterprise |
| **Storage** | Docker Volumes | VM Storage | Cloud Storage | Persistent Volumes |
| **Networking** | Docker Networks | VM Networking | Cloud Networking | Kubernetes Services |

## 🎯 Learning Outcomes

By following this implementation journey, you will gain hands-on experience with:

### DevOps Fundamentals

- Containerization strategies and best practices
- Infrastructure as Code principles
- Configuration management automation
- Service orchestration patterns
- Container orchestration with Kubernetes

### Tool Proficiency

- **Docker**: Multi-container applications, networking, volumes
- **Ansible**: Playbooks, roles, variables, tags, modules
- **Vagrant**: VM provisioning, automation integration
- **Terraform**: Resource provisioning, state management
- **Kubernetes**: StatefulSets, services, persistent volumes, deployments

### Best Practices

- Documentation-driven development
- Version control strategies for infrastructure
- Automated testing and validation
- Security considerations in DevOps pipelines
- Production deployment strategies
- Container orchestration patterns

## 📋 Project Structure

```
yolo/
├── README.md                           # This overview document
├── documentation/                      # All stage documentation
│   ├── containerization/               # Stage 1: Docker & Microservices
│   │   ├── README.md                   # Implementation guide
│   │   └── explanation-microservice.md # Technical decisions
│   ├── automation/                     # Stage 2: Ansible Configuration Management
│   │   ├── README.md                   # Automation guide
│   │   └── explanation-ansible.md      # Architecture reasoning
│   ├── IaC/                           # Stage 3: Infrastructure as Code
│   │   ├── README.md                   # Terraform + Ansible guide
│   │   └── explanation-terraform.md    # Technical implementation
│   └── orchestration/                  # Stage 4: Kubernetes Orchestration
│       ├── README.md                   # Kubernetes deployment guide
│       └── explanation-kubernetes.md   # Orchestration decisions
├── k8s/                               # Kubernetes manifests
│   ├── namespace.yml                  # Namespace configuration
│   ├── mongo-statefulset.yml          # MongoDB StatefulSet
│   ├── redis-deployment.yml           # Redis deployment
│   ├── backend-deployment.yml         # Backend API deployment
│   ├── frontend-deployment.yml        # Frontend deployment
│   └── services.yml                   # Service configurations
├── ansible.cfg                         # Ansible configuration
├── Vagrantfile                         # VM provisioning
├── playbook.yml                        # Main Ansible playbook
├── roles/                             # Ansible roles directory
│   ├── common/                        # Network & common tasks
│   ├── mongodb/                       # Database service role
│   ├── redis/                         # Cache service role
│   ├── server/                        # Backend API role
│   └── client/                        # Frontend web role
├── group_vars/                        # Ansible variables
│   └── all.yml                        # Global configuration
├── Stage_two/                         # Terraform + Ansible implementation
│   ├── terraform/                     # Terraform configurations
│   ├── playbook.yml                   # Combined automation playbook
│   └── roles/                         # Stage 2 specific roles
├── docker-compose.yml                 # Container orchestration
├── backend/                           # Node.js API service
│   ├── Dockerfile                     # Backend containerization
│   ├── server.js                      # Express server
│   ├── models/                        # Database models
│   └── routes/                        # API endpoints
├── client/                            # React frontend service  
│   ├── Dockerfile                     # Frontend containerization
│   ├── src/                          # React source code
│   └── public/                        # Static assets
└── [configuration files...]           # Environment & tooling configs
```

---

## 🔗 Stage-Specific Documentation Links

- **Stage 1**: [Containerization Documentation](./documentation/containerization/)
- **Stage 2**: [Automation Documentation](./documentation/automation/)
- **Stage 3**: [Infrastructure as Code Documentation](./documentation/IaC/)
- **Stage 4**: [Orchestration Documentation](./documentation/orchestration/)

---

*This project demonstrates the evolution from basic containerization to enterprise-grade Infrastructure as Code and Kubernetes orchestration, providing a complete learning path for modern DevOps practices.*