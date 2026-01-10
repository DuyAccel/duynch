# Build stage.
FROM ghcr.io/gohugoio/hugo:v0.154.3 AS builder

USER 0

WORKDIR /src
# Copy source code to image (change ./devel to your folder).
COPY ./src/duynch.com/ /src 

# Clear old build. Then, rebuild website.
RUN hugo mod tidy && hugo build --minify --noBuildLock

# Production stage. 
FROM docker.io/nginx:alpine3.22-otel

# Copy necesary files from build stage
COPY --from=builder /src/public /usr/share/nginx/html

COPY ./config/nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

