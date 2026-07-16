# ---------- Build stage ----------
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

# ---------- Runtime stage ----------
FROM node:20-alpine
WORKDIR /app

# Run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json

USER appuser

EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "dist/server.js"]
