# Build stage
FROM node:18-alpine AS builder
ARG REACT_APP_BACKEND_URL
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
WORKDIR /app
COPY package*.json ./
RUN npm install --production=false --ignore-scripts --legacy-peer-deps
COPY . .
RUN npm run build -- --openssl-legacy-provider

# Production stage
FROM alpine:3.18 AS final
# Use reliable Alpine mirror and install lighttpd
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk add --no-cache lighttpd

# Copy build output
WORKDIR /var/www/localhost/htdocs
COPY --from=builder /app/build .

# Minimal config
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