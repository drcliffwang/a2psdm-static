# =========================
# A2PSDM Static Site (Prod)
# =========================
FROM nginx:stable-alpine

LABEL maintainer="A2PSDM"
LABEL description="A2PSDM static landing site (nginx with SSL)"

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy SSL certificates
COPY ssl/fullchain.crt /etc/nginx/ssl/fullchain.crt
COPY ssl/private.key /etc/nginx/ssl/private.key

# Copy static assets
COPY webroot /usr/share/nginx/html

# Optional: permissions hardening
RUN chmod -R 755 /usr/share/nginx/html && \
    chmod 600 /etc/nginx/ssl/private.key

# Expose HTTP and HTTPS
EXPOSE 80 443

# Healthcheck (optional but professional)
HEALTHCHECK --interval=30s --timeout=5s \
    CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
