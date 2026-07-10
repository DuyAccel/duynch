# Stage 1: Build the Hugo static site
FROM ghcr.io/gohugoio/hugo:v0.164.0 as builder

# Switch to root user to prevent permission issues when acquiring build locks
USER root

# Set working directory
WORKDIR /src

# Copy all project files
COPY . .

# Build the site
RUN hugo --minify --gc

# Stage 2: Serve the site using unprivileged Nginx (Secure by default, non-root)
FROM ghcr.io/nginx/nginx-unprivileged:1.30.3-trixie-perl

# Copy the built output from Stage 1 to Nginx HTML directory and set ownership to nginx user (UID 101)
COPY --from=builder --chown=101:101 /src/public /usr/share/nginx/html

# Expose port 8080 (unprivileged port)
EXPOSE 8080

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
