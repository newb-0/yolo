# Ansible Configuration Management - Stage 1 Implementation

## 1. Playbook Architecture

### Sequential Execution Order
The playbook follows a logical deployment sequence using blocks and tags:

```yaml
1. Infrastructure Block (tags: [infrastructure])
   ├── Docker Setup
   ├── Git Repository Clone  
   └── Environment Configuration

2. Application Block (tags: [application])
   └── Container Deployment

3. Post-deployment Verification
```

**Reasoning**: Infrastructure must be established before application deployment. Each role has dependencies that require sequential execution.

## 2. Role-Based Implementation

### docker (System Setup)
**Purpose**: Installs Docker Engine and Docker Compose
**Position**: First in execution order
**Key Tasks**:
- Add Docker repository and GPG keys
- Install Docker CE and CLI tools
- Configure user permissions (add vagrant to docker group)
- Install Docker Compose binary
- Pull required base images (node:18-alpine, nginx:alpine, mongo:7.0, redis:alpine)

**Ansible Modules Used**:
- `apt`: Package management
- `apt_key`: Repository authentication
- `apt_repository`: Add Docker repository
- `user`: Group membership management
- `get_url`: Download Docker Compose
- `systemd`: Service management
- `docker_image`: Image pulling

### git_clone (Source Code Management)
**Purpose**: Clone application repository and set permissions
**Position**: Second - requires system packages
**Key Tasks**:
- Install git package
- Remove existing application directory (idempotency)
- Clone repository from GitHub
- Set proper ownership (vagrant:vagrant)

**Ansible Modules Used**:
- `apt`: Install git
- `file`: Directory management
- `git`: Repository cloning

### yolo_environment (Configuration Management)
**Purpose**: Create environment files with network and database configuration
**Position**: Third - requires application code structure
**Key Tasks**:
- Generate root .env file with Docker network variables
- Create backend .env with MongoDB connection string
- Set secure file permissions (0600 for backend secrets)

**Ansible Modules Used**:
- `copy`: File creation with templated content

### yolo_deploy (Application Orchestration)
**Purpose**: Deploy containerized application stack
**Position**: Final - requires all previous components
**Key Tasks**:
- Stop existing containers (cleanup)
- Build and start containers with docker-compose
- Wait for container initialization (30 seconds)
- Verify container status

**Ansible Modules Used**:
- `shell`: Execute docker-compose commands
- `pause`: Wait for service readiness
- `command`: Status verification
- `debug`: Output display

## 3. Variable Management

### Global Variables (variables.yml)
**Application Configuration**:
- `app_name`: yolo
- `app_port_client`: 3001 (frontend)
- `app_port_server`: 5001 (backend)
- `app_directory`: /home/vagrant/yolo

**Repository Configuration**:
- `repo_url`: GitHub repository URL
- `repo_branch`: master

**Network Configuration**:
- `docker_subnet`: 172.18.0.0/16
- Static IP assignments for each service

**Reasoning**: Centralized configuration enables easy modification without editing multiple files. Variables support different environments (dev/staging/prod).

## 4. Inventory Management

### Host Configuration (inventory.yml)
```yaml
default:
  ansible_host: 192.168.56.10
  ansible_user: vagrant
  ansible_ssh_private_key_file: .vagrant/machines/default/virtualbox/private_key
```

**Purpose**: Defines connection parameters for Vagrant-managed VM
**SSH Configuration**: Automated key management via Vagrant
**Network**: Private network for isolation from host system

## 5. Ansible Configuration (ansible.cfg)

### Key Settings
- `host_key_checking = False`: Disables SSH host key verification for VM
- `stdout_callback = yaml`: Improved output formatting
- `timeout = 30`: Connection timeout configuration
- `retry_files_enabled = False`: Disables retry file creation

**Reasoning**: Optimized for Vagrant development environment for simplicity and debugging.

## 6. Block and Tag Strategy

### Infrastructure Block
**Tags**: [infrastructure, setup, docker, git, environment]
**Purpose**: System preparation and configuration
**Dependencies**: None - can run independently

### Application Block  
**Tags**: [application, deploy]
**Purpose**: Container deployment and service startup
**Dependencies**: Requires infrastructure block completion

### Tag Benefits
- **Selective Execution**: `ansible-playbook playbook.yml --tags setup`
- **Skip Sections**: `ansible-playbook playbook.yml --skip-tags deploy`
- **Debugging**: Target specific components during troubleshooting

## 7. Error Handling & Idempotency

### Idempotent Operations
- **Git Clone**: Uses `force: yes` to handle existing repositories
- **Container Deployment**: `docker compose down` before starting
- **Package Installation**: Apt modules check current state

### Error Recovery
- **ignore_errors: true**: Used for cleanup operations
- **Retries**: URI module retries application health checks
- **Handlers**: Docker service restart on configuration changes

## 8. Security Implementation

### File Permissions
- **Root .env**: 0644 (readable by application)
- **Backend .env**: 0600 (secrets protection)
- **Directory Ownership**: vagrant:vagrant for application files

### SSH Configuration
- **Key Management**: Vagrant handles SSH key generation and distribution
- **Host Verification**: Disabled for development environment
- **User Isolation**: All operations under vagrant user context

## 9. Performance Optimizations

### Image Management
- **Pre-pulling**: Base images pulled during setup phase
- **Layer Caching**: Docker build process optimized for layer reuse
- **Alpine Images**: Minimal base images reduce download time

### Parallel Processing
- **Image Pulls**: Multiple images downloaded concurrently
- **Service Dependencies**: Docker Compose handles startup order

## 10. Debugging & Monitoring

### Built-in Verification
- **Container Status**: Automated status checking post-deployment
- **Health Checks**: URI module verifies application accessibility
- **Debug Output**: Container status displayed after deployment

### Manual Debugging Commands
```bash
# Ansible verbose mode
ansible-playbook -vvv playbook.yml

# Tag-specific execution
ansible-playbook playbook.yml --tags docker

# Check mode (dry run)
ansible-playbook playbook.yml --check
```

## 11. Integration with Vagrant

### Provisioning Integration
```ruby
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "playbook.yml"
  ansible.inventory_path = "inventory.yml"
end
```

**Benefits**:
- **Automatic Provisioning**: Runs on `vagrant up`
- **Repeatable Deployments**: `vagrant provision` for updates
- **Development Workflow**: Integrated with VM lifecycle

### File Synchronization
- **Disabled Default Sync**: Prevents host filesystem conflicts
- **Git-based Deployment**: Ensures clean application state
- **Ownership Management**: Proper permissions for containerized applications

These are some of the core principles for Infrastructure as Code consisting of separation of concerns, automated testing, and maintainable configuration management.