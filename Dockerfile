# Etapa 1: compilar la app web de Flutter.
# API_BASE_URL queda vacío a propósito: en Docker las peticiones /api/*
# las reenvía nginx al backend (mismo origen, sin CORS).
# Se instala el SDK de Flutter pineado a la misma versión usada en
# desarrollo (ghcr.io/cirruslabs/flutter falla en Docker Desktop con
# containerd: error "read-only file system" al extraer la imagen).
FROM debian:bookworm-slim AS build
ARG FLUTTER_VERSION=3.44.8
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl ca-certificates xz-utils git \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt
ENV PATH="/opt/flutter/bin:${PATH}"
RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter precache --web
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=
RUN if [ -d dist/mobile ]; then \
      mkdir -p build/web/mobile \
      && cp -R dist/mobile/. build/web/mobile/; \
    fi

# Etapa 2: servir la build estática con nginx y actuar de reverse proxy.
# nginx aplica envsubst sobre /etc/nginx/templates/*.template al arrancar
# (inyecta API_KEY en el header X-API-Key; vacía = no se envía).
FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
EXPOSE 80
