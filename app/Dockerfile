# ── Stage 1: builder ──────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifests first (layer cache optimisation)
# If package.json doesn't change, Docker reuses this layer
COPY package*.json ./
RUN npm ci --only=production

# Now copy source
COPY . .

# ── Stage 2: production ───────────────────────────────
FROM node:20-alpine AS production

# Security: don't run as root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only what production needs from builder
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/index.js .
COPY --from=builder --chown=appuser:appgroup /app/package.json .

USER appuser

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

# Healthcheck — Docker and ECS use this to know if container is healthy
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3   CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "index.js"]
