# Stage 1: Build dependencies
FROM node:18-alpine AS builder
WORKDIR /app

# Copy dependency files
COPY package.json package-lock.json ./

# Install production-only dependencies
RUN npm ci --omit=dev --ignore-scripts && \
    npm cache clean --force

# Stage 2: Compress, prune, and clean
FROM alpine:3.18 AS compressor
WORKDIR /app

# Copy dependencies and app code
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Install compression tools
RUN apk add --no-cache upx binutils && \
    # Compress Node.js binaries
    find node_modules -name "*.node" -exec upx --best --lzma {} \; && \
    # Strip debug symbols
    find node_modules -name "*.node" -exec strip -s {} \; && \
    # Remove development files
    find . \( -name "*.md" -o -name "*.ts" -o -name "*.map" \) -delete && \
    # Remove test and example files
    find . \( -name "__tests__" -o -name "test" -o -name "tests" -o -name "example*" \) -exec rm -rf {} + && \
    # Remove non-essential JSON files (except package*.json)
    # find . -name "*.json" ! -name "package*.json" ! -path "*node_modules/statuses*" -delete && \
    # Remove unused architectures
    find node_modules -name "*.node" -exec sh -c 'file {} | grep -v "x86-64" && rm {}' \; || true && \
    # Clean up
    rm -rf /var/cache/apk/*

# Stage 3: Minimal runtime
FROM gcr.io/distroless/nodejs18-debian11
ENV NODE_ENV=production

# Copy only essential files
WORKDIR /app
COPY --from=compressor --chown=nonroot:nonroot /app ./

# Security settings
USER nonroot
EXPOSE 5002
CMD ["server.js"]