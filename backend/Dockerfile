# Stage 1: Build
FROM node:22-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

# Install all dependencies (including devDependencies needed for build)
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Build the NestJS application
RUN npm run build

# Stage 2: Production
FROM node:22-alpine AS production

# Set working directory
WORKDIR /app

# Set NODE_ENV to production
ENV NODE_ENV=production

# Copy package.json and package-lock.json
COPY package*.json ./

# Install only production dependencies for a smaller image footprint
RUN npm ci --omit=dev

# Copy the compiled output from the builder stage
COPY --from=builder /app/dist ./dist

# Create a non-root user (Security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the default port (Render typically sets the PORT env variable)
EXPOSE 3000

# Start the application using the compiled code
CMD ["node", "dist/main"]
