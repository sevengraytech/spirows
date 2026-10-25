# ─────────────────────────────────────────────────────────────────────────────
# Evilginx 3 + Web UI — Single Container Production Dockerfile
# Runs both Evilginx proxy and Web UI dashboard in one container
# ─────────────────────────────────────────────────────────────────────────────

FROM python:3.11-slim

# ── Build arguments ──────────────────────────────────────────────────────────
ARG EVILGINX_TAG=v3.3.0

# ── Install runtime dependencies ─────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates python3 unzip supervisor && \
    rm -rf /var/lib/apt/lists/*

# ── Download and unpack Evilginx ─────────────────────────────────────────────
WORKDIR /opt/evilginx
RUN curl -fsSL "https://github.com/kgretzky/evilginx2/releases/download/${EVILGINX_TAG}/evilginx-${EVILGINX_TAG}-linux-64bit.zip" \
    -o evilginx.zip && \
    unzip -o evilginx.zip && \
    chmod +x evilginx && \
    mv evilginx /usr/local/bin/evilginx && \
    rm -rf /opt/evilginx

# ── Create non-root users ────────────────────────────────────────────────────
RUN addgroup --system evilginx && \
    adduser --system --ingroup evilginx --no-create-home --shell /usr/sbin/nologin evilginx && \
    addgroup --system ui && \
    adduser --system --ingroup ui --no-create-home --shell /usr/sbin/nologin ui

# ── Install Python dependencies for Web UI ───────────────────────────────────
COPY ui_requirements.txt /tmp/ui_requirements.txt
RUN pip install --no-cache-dir -r /tmp/ui_requirements.txt && \
    rm /tmp/ui_requirements.txt

# ── Copy Web UI application ──────────────────────────────────────────────────
COPY ui/ /app/ui/
COPY ui_config.py /app/ui_config.py
RUN chown -R ui:ui /app

# ── Copy phishlets from Evilginx release ─────────────────────────────────────
RUN mkdir -p /tmp/evilginx-phishlets && \
    curl -fsSL "https://github.com/kgretzky/evilginx2/releases/download/${EVILGINX_TAG}/evilginx-${EVILGINX_TAG}-linux-64bit.zip" \
    -o /tmp/evilginx.zip && \
    unzip -o /tmp/evilginx.zip -d /tmp/evilginx-phishlets && \
    mkdir -p /config/phishlets && \
    cp /tmp/evilginx-phishlets/phishlets/* /config/phishlets/ 2>/dev/null || true && \
    chown -R evilginx:evilginx /config/phishlets && \
    rm -rf /tmp/evilginx-phishlets /tmp/evilginx.zip

# ── Create config directories ────────────────────────────────────────────────
RUN mkdir -p /config/phishlets /config/certs /config/logs /app/ui/templates /app/ui/static/css /app/ui/static/js && \
    chown -R evilginx:evilginx /config && \
    chown -R ui:ui /app/ui

# ── Copy entrypoint and supervisor config ────────────────────────────────────
COPY evilginx-entrypoint.sh /usr/local/bin/evilginx-entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /usr/local/bin/evilginx-entrypoint.sh

# ── Expose ports ─────────────────────────────────────────────────────────────
# 80, 443 = Evilginx proxy
# 53 = DNS (optional)
# 5000 = Web UI
EXPOSE 80 443 53/udp 5000

# ── Default command ──────────────────────────────────────────────────────────
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]