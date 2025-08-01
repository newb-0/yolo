# YOLO E-commerce Platform - DevOps Implementation

A containerized e-commerce application demonstrating microservice architecture with progressive automation using configuration management and infrastructure as code.

## Architecture Overview

The application consists of three main components:

- **Frontend**: React.js client served via Nginx
- **Backend**: Node.js REST API server
- **Infrastructure**: Redis cache with MongoDB Atlas database

## Implementation Stages

### Stage 1: Microservice Containerization ✅

- **Status**: Complete and functional
- **Approach**: Docker containerization with multi-stage builds
- **Details**: [Microservice Implementation Documentation](explanation-microservice.md)

### Stage 2: Ansible Configuration Management ✅

- **Status**: Complete and functional
- **Approach**: Automated deployment via Ansible playbooks and Vagrant
- **Details**: [Ansible Automation Documentation](explanation-ansible.md)

### Stage 3: Terraform + Ansible Integration

- **Status**: Not yet available
- **Planned**: Infrastructure as Code with Terraform provisioning

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Vagrant 2.3+ (for automated deployment)
- VirtualBox 7.0+ (for automated deployment)
- Ansible 2.9+ (for automated deployment)

### Manual Container Deployment

```bash
# Clone repository
git clone <repository-url>
cd yolo

# Start services
docker compose up -d

# Access application
# Frontend: http://localhost:3001
# Backend API: http://localhost:5001
```

### Automated Deployment (Ansible + Vagrant)

```bash
# Automated setup
vagrant up

# Manual provisioning (if needed)
vagrant provision

# Access application
# Frontend: http://192.168.56.10:3001
# Backend API: http://192.168.56.10:5001
```

### Vagrant Operations

```bash
vagrant status        # Check VM status
vagrant halt          # Stop VM
vagrant destroy       # Remove VM completely
vagrant ssh           # SSH into VM
```

## Project Structure

```
├── playbook.yml              # Main Ansible playbook
├── variables.yml              # Global configuration variables
├── inventory.yml              # Vagrant host inventory
├── ansible.cfg               # Ansible configuration
├── Vagrantfile               # VM provisioning config
├── roles/                    # Ansible roles directory
│   ├── docker/               # Docker installation & setup
│   ├── git_clone/            # Repository cloning
│   ├── yolo_environment/     # Environment file creation
│   └── yolo_deploy/          # Application deployment
├── docker-compose.yml        # Container orchestration
└── .env                      # Docker network configuration
```

## Monitoring & Debugging

### Manual Container Operations

```bash
# Check running containers
docker ps

# View container logs
docker compose logs server
docker compose logs client

# Check container resource usage
docker stats

# Restart specific service
docker compose restart server
```

### Automated Deployment Monitoring

```bash
# SSH into VM
vagrant ssh

# Check running containers
docker ps

# View container logs
docker compose logs server
docker compose logs client

# Check container resource usage
docker stats
```

### Application Health Checks

```bash
# Test frontend
curl http://192.168.56.10:3001

# Test backend API
curl http://192.168.56.10:5001/api/products

# Check specific service logs
docker compose logs redis
```

### Network Diagnostics

```bash
# View Docker networks
docker network ls

# Inspect application network
docker network inspect yolo_appnet

# Container connectivity test
docker exec server ping redis
```

## Configuration Management

### Variable Customization

Key variables in `variables.yml`:

- `app_port_client`: Frontend port (default: 3001)
- `app_port_server`: Backend port (default: 5001)
- `mongodb_uri`: Database connection string
- `docker_subnet`: Container network range

### Role-Based Architecture

- **docker**: Installs Docker Engine and Docker Compose
- **git_clone**: Clones application repository
- **yolo_environment**: Creates required .env files
- **yolo_deploy**: Builds and starts containers

## Persistence & Data Management

### Database Storage

- **Provider**: MongoDB Atlas (cloud-hosted)
- **Persistence**: Products survive container restarts
- **Connection**: Configured via environment variables

### Local Development

For local database testing, uncomment MongoDB service in docker-compose.yml:

```yaml
# Uncomment for local MongoDB
# mongo:
#   image: mongo:7.0
#   container_name: mongo
```

## Testing Product Functionality

1. Access frontend: <http://192.168.56.10:3001>
2. Navigate to "Add Product" section
3. Fill product form with:
   - Product name
   - Product price
   - Product description
   - Upload product image
4. Submit form
5. Verify product appears in product list
6. Test persistence by restarting containers:

   ```bash
   vagrant ssh
   cd /home/vagrant/yolo
   docker compose restart
   ```

## Troubleshooting

### Common Issues

**Port conflicts**:

```bash
# Check port usage
sudo lsof -i :3001
sudo lsof -i :5001
```

**Container startup failures**:

```bash
# Rebuild containers
docker compose down
docker compose up -d --build
```

**Permission issues**:

```bash
# Fix Docker permissions
sudo usermod -aG docker vagrant
```

**Ansible task failures**:

```bash
# Run with verbose output
ansible-playbook -vvv playbook.yml
```

## Network Configuration

### VM Network Setup

- **Host IP**: 192.168.56.10
- **SSH Port**: 2222 (forwarded from 22)
- **Application Ports**: 3001, 5001

### Docker Network

- **Subnet**: 172.18.0.0/16
- **IP Range**: 172.18.0.0/24
- **Gateway**: 172.18.0.1

Service IPs:

- Client: 172.18.0.2
- Server: 172.18.0.3
- MongoDB: 172.18.0.4
- Redis: 172.18.0.5

## Security Considerations

### Credentials Management

- MongoDB connection string in variables.yml (should be encrypted with Ansible Vault in production)
- SSH keys automatically managed by Vagrant
- No hardcoded passwords in configuration files

### Network Security

- Private network for inter-container communication
- Only necessary ports exposed to host
- Frontend and backend isolated in separate containers

## Performance Optimization

### Container Resources

- VM allocated 2GB RAM, 2 CPU cores
- Alpine Linux base images for minimal footprint
- Multi-stage builds for optimized image sizes

### Caching Strategy

- Redis for application-level caching
- Docker layer caching for faster rebuilds
- Nginx for static file serving

## Documentation Links

- [Ansible Stage 1 Implementation Details](explanation-ansible.md)
- [Microservice Architecture Explanation](explanation-microservice.md)

## Support & Maintenance

### Regular Maintenance

```bash
# Update base box
vagrant box update

# Prune unused Docker resources
docker system prune -f

# Update Docker images
docker compose pull
```

### Backup Procedures

- Database: MongoDB Atlas handles automated backups
- Configuration: Version controlled in Git
- VM state: Can be recreated from Vagrantfile
