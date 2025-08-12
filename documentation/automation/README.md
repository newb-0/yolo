# [yolomy](http://4.255.32.247) E-commerce Ansible Configuration Management

A comprehensive guide to automating the deployment of a containerized e-commerce application using Ansible configuration management with Vagrant-provisioned infrastructure.

## 📋 Prerequisites

Before starting this project, ensure you have the following installed and configured:

### Required Software

- **Vagrant** (latest version) - [Download here](https://www.vagrantup.com/downloads)
- **VirtualBox** (latest version) - [Download here](https://www.virtualbox.org/wiki/Downloads)
- **Ansible** (2.9 or higher) - [Install guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- **Git** - [Download here](https://git-scm.com/)
- **Code Editor** (VS Code recommended)

### System Requirements

- **RAM**: Minimum 4GB available (VM requires 2GB)
- **Disk Space**: At least 10GB free space
- **CPU**: 2+ cores recommended
- **OS**: macOS, Linux, or Windows with WSL2

## 🏗️ Project Structure

```
yolo/
├── ansible.cfg                 # Ansible configuration
├── playbook.yml               # Main Ansible playbook
├── Vagrantfile                # Vagrant VM configuration
├── hosts                      # Ansible inventory (unused with Vagrant)
├── group_vars/
│   └── all.yml               # Global variables
├── roles/
│   ├── common/               # Common setup tasks
│   │   ├── tasks/main.yml    
│   │   └── handlers/main.yml
│   ├── mongodb/              # MongoDB container role
│   │   └── tasks/main.yml
│   ├── redis/                # Redis container role
│   │   └── tasks/main.yml
│   ├── server/               # Backend API role
│   │   └── tasks/main.yml
│   └── client/               # Frontend web role
│       └── tasks/main.yml
├── backend/                  # Node.js API source
├── client/                   # React frontend source
├── docker-compose.yml        # Docker Compose reference
├── .env                      # Environment variables
├── README.md                 # This documentation
└── explanation-ansible.md    # Technical reasoning
```

## 🚀 Step-by-Step Implementation

### Step 1: Environment Setup

#### 1.1 Clone the Repository

```bash
git clone <your-repository-url>
cd yolo
git checkout feature/ansible-stage1
```

#### 1.2 Verify Prerequisites

```bash
# Check Vagrant installation
vagrant --version
# Expected: Vagrant 2.x.x

# Check VirtualBox installation
vboxmanage --version  
# Expected: 7.x.x or 6.x.x

# Check Ansible installation
ansible --version
# Expected: ansible [core 2.x.x]
```

### Step 2: Ansible Configuration

#### 2.1 Configure Ansible Settings

Create `ansible.cfg`:

```ini
[defaults]
inventory = hosts
host_key_checking = False
gathering = smart
retry_files_enabled = False
stdout_callback = yaml

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

#### 2.2 Define Global Variables

Create `group_vars/all.yml`:

```yaml
# Application configuration
app_dir: /vagrant

# Network configuration
network_name: yolo_network

# Image names
mongodb_image: mongo:5.0
redis_image: redis:7-alpine
server_image: yolo_server:latest
client_image: yolo_client:latest

# Ports
server_port: 5002
client_port: 3000
mongodb_uri: mongodb://mongodb:27017/yolo

# Backend URL for client
backend_url: http://localhost:5100
```

### Step 3: Vagrant Infrastructure Setup

#### 3.1 Configure Vagrant VM

Create `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "geerlingguy/ubuntu2004"
  config.vm.network "forwarded_port", guest: 3000, host: 3100
  config.vm.network "forwarded_port", guest: 5002, host: 5100
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
  
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.verbose = "v"
    ansible.raw_arguments = ["--tags=full_deploy"]
  end
end
```

### Step 4: Ansible Playbook Development

#### 4.1 Main Playbook Structure

Create `playbook.yml`:

```yaml
---
- name: Deploy yolomy E-commerce Application
  hosts: all
  become: true
  gather_facts: true
  vars_files:
    - group_vars/all.yml

  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      tags: [system, update, full_deploy]

    - name: Install required packages
      apt:
        name:
          - git
          - docker.io
          - docker-compose
          - python3-pip
          - python3-docker
        state: present
      tags: [system, packages, full_deploy]

    - name: Start and enable Docker service
      systemd:
        name: docker
        state: started
        enabled: yes
      tags: [system, docker, full_deploy]

    - name: Add vagrant user to docker group
      user:
        name: vagrant
        groups: docker
        append: yes
      tags: [system, docker, full_deploy]

  roles:
    - { role: common, tags: [common, network, full_deploy] }
    - { role: mongodb, tags: [mongodb, database, full_deploy] }
    - { role: redis, tags: [redis, cache, full_deploy] }
    - { role: server, tags: [server, backend, full_deploy] }
    - { role: client, tags: [client, frontend, full_deploy] }

  post_tasks:
    - name: Wait for containers to be ready
      pause:
        seconds: 10
      tags: [verification, full_deploy]

    - name: Verify container status
      command: docker ps --format "table {{ '{{.Names}}' }}\t{{ '{{.Status}}' }}"
      register: container_status
      changed_when: false
      tags: [verification, full_deploy]

    - name: Display container status
      debug:
        msg: "{{ container_status.stdout_lines }}"
      tags: [verification, full_deploy]

    - name: Display success message
      debug:
        msg: |
          Application deployed successfully!
          Access at: http://localhost:3100 (client)
          API at: http://localhost:5100 (server)
      tags: [notification, full_deploy]
```

### Step 5: Ansible Roles Implementation

#### 5.1 Common Infrastructure Role

Create `roles/common/tasks/main.yml`:

```yaml
---
- name: Create Docker network
  docker_network:
    name: "{{ network_name }}"
    state: present
  tags: [network, full_deploy]

- name: Ensure application directory exists
  file:
    path: "{{ app_dir }}"
    state: directory
    mode: "0755"
    owner: vagrant
    group: vagrant
  tags: [setup, full_deploy]
```

#### 5.2 MongoDB Database Role

Create `roles/mongodb/tasks/main.yml`:

```yaml
---
- name: Create MongoDB volumes
  docker_volume:
    name: "{{ item }}"
    state: present
  loop:
    - mongodb_data
    - mongodb_config
  tags: [storage, full_deploy]

- name: Start MongoDB container
  docker_container:
    name: mongodb
    image: "{{ mongodb_image }}"
    networks:
      - name: "{{ network_name }}"
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
      - mongodb_config:/data/configdb
    env:
      MONGO_INITDB_DATABASE: yolo
    state: started
    restart_policy: always
  tags: [mongodb, full_deploy]
```

#### 5.3 Redis Cache Role

Create `roles/redis/tasks/main.yml`:

```yaml
---
- name: Start Redis container
  docker_container:
    name: redis
    image: "{{ redis_image }}"
    networks:
      - name: "{{ network_name }}"
    state: started
    restart_policy: always
  tags: [redis, full_deploy]
```

#### 5.4 Backend Server Role

Create `roles/server/tasks/main.yml`:

```yaml
---
- name: Build server image
  docker_image:
    name: "{{ server_image }}"
    build:
      path: "{{ app_dir }}/backend"
      dockerfile: Dockerfile
      args:
        NODE_ENV: production
    source: build
    state: present
    force_source: yes
  tags: [build, full_deploy]

- name: Start server container
  docker_container:
    name: server
    image: "{{ server_image }}"
    networks:
      - name: "{{ network_name }}"
    ports:
      - "{{ server_port }}:{{ server_port }}"
    env:
      NODE_ENV: production
      MONGODB_URI: "{{ mongodb_uri }}"
      PORT: "{{ server_port | string }}"
    state: started
    restart_policy: always
  tags: [server, full_deploy]
```

#### 5.5 Frontend Client Role

Create `roles/client/tasks/main.yml`:

```yaml
---
- name: Build client image
  docker_image:
    name: "{{ client_image }}"
    build:
      path: "{{ app_dir }}/client"
      dockerfile: Dockerfile
      args:
        REACT_APP_BACKEND_URL: "{{ backend_url }}"
    source: build
    state: present
    force_source: yes
  tags: [build, full_deploy]

- name: Start client container
  docker_container:
    name: client
    image: "{{ client_image }}"
    networks:
      - name: "{{ network_name }}"
    ports:
      - "{{ client_port }}:80"
    state: started
    restart_policy: always
  tags: [client, full_deploy]
```

### Step 6: Docker Configuration Updates

#### 6.1 Update Client Dockerfile

Add build argument support to `client/Dockerfile`:

```dockerfile
# Build stage
FROM node:18-alpine AS builder
ARG REACT_APP_BACKEND_URL
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
WORKDIR /app
# ... rest of Dockerfile remains the same
```

### Step 7: Deployment Execution

#### 7.1 Initial Deployment

```bash
# Start fresh deployment
vagrant up
```

**Expected output:**

```bash
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'geerlingguy/ubuntu2004'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'geerlingguy/ubuntu2004' version '1.0.4' is up to date...
==> default: Setting the name of the VM: yolo_default_1754581904153_23241
==> default: Fixed port collision for 22 => 2222. Now on port 2200.
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 3000 (guest) => 3100 (host) (adapter 1)
    default: 5002 (guest) => 5100 (host) (adapter 1)
    default: 22 (guest) => 2200 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2200
    default: SSH username: vagrant
    default: SSH auth method: private key
```

#### 7.2 Ansible Provisioning Output

```bash
==> default: Running provisioner: ansible...
    default: Running ansible-playbook...

PLAY [Deploy yolomy E-commerce Application] ************************************

TASK [Gathering Facts] *********************************************************
ok: [default]

TASK [Update apt cache] ********************************************************
ok: [default]

TASK [Install required packages] **********************************************
changed: [default]

TASK [Start and enable Docker service] ****************************************
ok: [default]

TASK [Add vagrant user to docker group] ***************************************
changed: [default]

TASK [common : Create Docker network] *****************************************
changed: [default]

TASK [common : Ensure application directory exists] ***************************
ok: [default]

TASK [mongodb : Create MongoDB volumes] ***************************************
changed: [default] => (item=mongodb_data)
changed: [default] => (item=mongodb_config)

TASK [mongodb : Start MongoDB container] **************************************
changed: [default]

TASK [redis : Start Redis container] ******************************************
changed: [default]

TASK [server : Build server image] ********************************************
changed: [default]

TASK [server : Start server container] ****************************************
changed: [default]

TASK [client : Build client image] ********************************************
changed: [default]

TASK [client : Start client container] ****************************************
changed: [default]

TASK [Wait for containers to be ready] ****************************************
Pausing for 10 seconds
ok: [default]

TASK [Verify container status] ************************************************
ok: [default]

TASK [Display container status] ***********************************************
ok: [default] => 
  msg:
  - NAMES     STATUS
  - client    Up 10 seconds
  - server    Up 47 minutes
  - redis     Up 4 hours
  - mongodb   Up 4 hours

TASK [Display success message] ************************************************
ok: [default] => 
  msg: |-
    Application deployed successfully!
    Access at: http://localhost:3100 (client)
    API at: http://localhost:5100 (server)

PLAY RECAP *********************************************************************
default                    : ok=18   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

#### 7.3 Re-provisioning (Updates)

```bash
# Apply configuration changes
vagrant provision
```

#### 7.4 Clean Deployment

```bash
# Complete rebuild
vagrant destroy -f
vagrant up
```

### Step 8: Verification and Testing

#### 8.1 Container Status Verification

```bash
# SSH into the VM
vagrant ssh

# Check container status
docker ps
```

**Expected output:**

```bash
CONTAINER ID   IMAGE                COMMAND                  STATUS          PORTS                      NAMES
abc123def456   yolo_client:latest   "lighttpd -D -f /etc…"   Up 10 minutes   0.0.0.0:3000->80/tcp      client
def456ghi789   yolo_server:latest   "server.js"              Up 47 minutes   0.0.0.0:5002->5002/tcp    server
ghi789jkl012   redis:7-alpine       "docker-entrypoint.s…"   Up 4 hours      6379/tcp                   redis
jkl012mno345   mongo:5.0           "docker-entrypoint.s…"   Up 4 hours      0.0.0.0:27017->27017/tcp   mongodb
```

#### 8.2 Application Access Testing

- **Frontend**: <http://localhost:3100>
- **Backend API**: <http://localhost:5100/api/products>
- **Health Check**: All services should be accessible

#### 8.3 Functionality Testing

1. **Navigate to Frontend**

   ```bash
   # Open browser to http://localhost:3100
   ```

2. **Test Product Addition**
   - Click "Add a product"
   - Fill in product details:
     - Name: "Test Product"
     - Price: "99.99"
     - Description: "Ansible deployed product"
     - Quantity: "5"
   - Click "Submit"

3. **Verify Data Persistence**

   ```bash
   # Restart containers
   vagrant reload
   # Check if products persist after restart
   ```

### Step 9: Troubleshooting

#### 9.1 Common Issues and Solutions

**Port Conflicts:**

```bash
# Check port usage
sudo lsof -i :3100
sudo lsof -i :5100

# Kill conflicting processes if necessary
sudo kill -9 <PID>
```

**Container Build Failures:**

```bash
# SSH into VM
vagrant ssh

# Check Docker logs
docker logs server
docker logs client

# Rebuild specific container
docker build -t yolo_server:latest /vagrant/backend
```

**Network Issues:**

```bash
# Check Docker networks
docker network ls
docker network inspect yolo_network

# Verify container connectivity
docker exec -it server ping mongodb
docker exec -it client ping server
```

**Ansible Task Failures:**

```bash
# Run specific tags
vagrant provision --provision-with ansible --ansible-tags="server,client"

# Debug mode
ANSIBLE_DEBUG=1 vagrant provision
```

#### 9.2 VM Management Commands

```bash
# Check VM status
vagrant status

# Suspend/resume VM
vagrant suspend
vagrant resume

# SSH into VM
vagrant ssh

# View VM logs
vagrant up --debug

# Destroy and recreate
vagrant destroy -f
vagrant up
```

### Step 10: Deployment Architecture

#### 10.1 Infrastructure Components

- **Host System**: Development machine running Vagrant
- **Virtual Machine**: Ubuntu 20.04 LTS (geerlingguy/ubuntu2004)
- **Container Runtime**: Docker Engine with Docker Compose
- **Network**: Custom bridge network for service communication
- **Storage**: Docker volumes for data persistence

#### 10.2 Service Architecture

```
┌─────────────────────────────────────────────────┐
│                 Host System                     │
│  ┌─────────────────────────────────────────────┐│
│  │              Vagrant VM                     ││
│  │  ┌─────────────────────────────────────────┐││
│  │  │           Docker Network                │││
│  │  │                                         │││
│  │  │  ┌─────────┐ ┌─────────┐ ┌───────────┐  │││
│  │  │  │  Client │ │ Server  │ │  MongoDB  │  │││
│  │  │  │  :3000  │ │  :5002  │ │   :27017  │  │││
│  │  │  └─────────┘ └─────────┘ └───────────┘  │││
│  │  │                                         │││
│  │  │      ┌─────────┐                       │││
│  │  │      │  Redis  │                       │││
│  │  │      │  :6379  │                       │││
│  │  │      └─────────┘                       │││
│  │  └─────────────────────────────────────────┘││
│  └─────────────────────────────────────────────┘│
│           Port Forwards: 3100→3000, 5100→5002   │
└─────────────────────────────────────────────────┘
```

## 🔧 Advanced Configuration

### Custom Variable Configuration

Modify `group_vars/all.yml` for environment-specific settings:

```yaml
# Development environment
mongodb_image: mongo:5.0
redis_image: redis:7-alpine

# Production environment  
mongodb_image: mongo:7.0-jammy
redis_image: redis:7.0

# Custom ports
server_port: 8080
client_port: 8000
```

### Role Customization

Add custom handlers in `roles/common/handlers/main.yml`:

```yaml
---
- name: restart docker
  service:
    name: docker
    state: restarted
    enabled: yes

- name: rebuild images
  command: docker compose build --no-cache
  args:
    chdir: "{{ app_dir }}"
```

## 📊 Success Metrics

### Deployment Criteria

- ✅ VM provisions successfully with Ubuntu 20.04
- ✅ All 4 containers build and run (mongodb, redis, server, client)
- ✅ Application accessible at <http://localhost:3100>
- ✅ API endpoints respond at <http://localhost:5100>
- ✅ Product CRUD operations function correctly
- ✅ Data persists across container restarts
- ✅ Ansible playbook runs without errors
- ✅ All roles execute successfully with proper tagging

### Performance Expectations

- **VM Boot Time**: < 3 minutes
- **Ansible Playbook Runtime**: < 10 minutes
- **Container Build Time**: < 5 minutes total
- **Application Startup**: < 30 seconds
- **Memory Usage**: < 2GB total VM memory

## 📝 Key Features

✅ **Infrastructure as Code** with Vagrant and Ansible  
✅ **Automated provisioning** of Ubuntu VM  
✅ **Role-based task organization** for maintainability  
✅ **Containerized microservices** deployment  
✅ **Network isolation** with custom Docker networks  
✅ **Data persistence** with Docker volumes  
✅ **Port forwarding** for external access  
✅ **Environment variable** configuration management  
✅ **Tag-based deployment** control  
✅ **Idempotent operations** for reliable automation  

For detailed technical explanations and architectural decisions, see [explanation-ansible.md](./explanation-ansible.md)
