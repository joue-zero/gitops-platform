# ── Stage 1: Dependencies ───────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Copy dependency manifests first for layer caching
COPY package*.json ./

# Clean install of production dependencies only
RUN npm ci --omit=dev

# ── Stage 2: Production ───────────────────────────────
FROM node:20-alpine AS production

# Install dumb-init to properly handle PID 1 signals
RUN apk add --no-cache dumb-init

# Set production environment variables
ENV NODE_ENV=production
ENV PORT=8080

WORKDIR /app

# Copy production node_modules from the 'deps' stage
# We use the built-in 'node' user that comes with the node:alpine image
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json ./

# Copy ONLY our application source code
COPY --chown=node:node src/ ./src/

# Switch to the built-in, unprivileged non-root user
USER node

EXPOSE 8080

# Healthcheck to let Docker/AWS know when the app is actually ready
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Wrap the node process with dumb-init and point directly to the server file
CMD ["dumb-init", "node", "src/server.js"]