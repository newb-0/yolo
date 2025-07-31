# YOLO E-commerce Microservice Application

![Alt text](yolomy.png "DockerHub image")

[Build image consideration](./explanation-microservice.md)

A containerized e-commerce application

## Architecture

- **Client**: React frontend served by Nginx
- **Backend**: Node.js/Express API server
- **Database**: MongoDB for data persistence
- **Cache**: Redis for session management
- **Networking**: Custom bridge network with static IPs

## Quick Start

```bash
# Clone and navigate to project
git clone <your-repo-url>
cd yolo

# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

## Access Points

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000

## Features

- Product catalog viewing
- Add new products via dashboard
- Persistent data storage
- Containerized microservices
- Custom networking setup

## Development

```bash
# Rebuild and restart
docker compose up --build -d

# View individual service logs
docker compose logs server
docker compose logs client
```

## Image Sizes

- Client: ~57MB (optimized with multi-stage build)
- Server: ~155MB (Alpine Linux based)
- Total: ~212MB (excluding MongoDB/Redis)
