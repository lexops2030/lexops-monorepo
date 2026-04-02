# ── Stage 1: Build ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.1.0 --activate

# Copy workspace manifests first (layer caching)
COPY package.json pnpm-workspace.yaml ./
COPY apps/api-service/package.json ./apps/api-service/
COPY packages/ ./packages/

# Install dependencies
RUN pnpm install --frozen-lockfile --filter api-service...

# Copy source
COPY apps/api-service ./apps/api-service

# Build NestJS
RUN pnpm --filter api-service run build

# ── Stage 2: Runtime ───────────────────────────────────────────────────────────
FROM node:20-alpine AS runtime

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@9.1.0 --activate

# Production deps only
COPY package.json pnpm-workspace.yaml ./
COPY apps/api-service/package.json ./apps/api-service/
RUN pnpm install --frozen-lockfile --prod --filter api-service...

# Copy compiled output
COPY --from=builder /app/apps/api-service/dist ./apps/api-service/dist

# Non-root user (security)
RUN addgroup -S lexops && adduser -S lexops -G lexops
USER lexops

# Cloud Run listens on 8080
EXPOSE 8080

ENV NODE_ENV=production \
    PORT=8080

CMD ["node", "apps/api-service/dist/main"]
