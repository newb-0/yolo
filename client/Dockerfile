# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false && npm cache clean --force
COPY . .
ENV NODE_OPTIONS="--openssl-legacy-provider"
RUN npm run build

# Production stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Remove default files and copy the build
RUN rm -rf ./* && rm /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build .
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]