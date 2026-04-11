# ────────────────────────────────────────────────────────────────────────────
# Stage 1 – Build Flutter web
# ────────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS builder

ARG FLUTTER_VERSION=3.19.6
ARG FLUTTER_CHANNEL=stable

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git /flutter

# Pre-warm Flutter (downloads Dart SDK, engine, etc.)
RUN flutter config --no-analytics \
  && flutter precache --web \
  && flutter doctor --android-licenses || true

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy source
COPY . .

# Build Flutter web (release)
RUN flutter build web --release --web-renderer canvaskit

# ────────────────────────────────────────────────────────────────────────────
# Stage 2 – Serve with nginx
# ────────────────────────────────────────────────────────────────────────────
FROM nginx:1.25-alpine AS runner

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app from Stage 1
COPY --from=builder /app/build/web /usr/share/nginx/html

# Remove default config and write our own inline (Flutter SPA needs fallback routing)
RUN rm /etc/nginx/conf.d/default.conf && \
    printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / { try_files $uri $uri/ /index.html; }\n\
    location ~* \.(js|css|wasm|png|jpg|svg|ico|woff2?)$ {\n\
        expires 1y; add_header Cache-Control "public, immutable";\n\
    }\n\
    gzip on;\n\
    gzip_types text/plain text/css application/javascript application/wasm image/svg+xml;\n\
    add_header X-Frame-Options "SAMEORIGIN";\n\
    add_header X-Content-Type-Options "nosniff";\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
