# LilNouns ENS Development Environment Dockerfile
# This Dockerfile creates a consistent development environment with all required tools

# Use Node.js 22.x as base image (Alpine for smaller size)
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    bash \
    python3 \
    py3-pip \
    build-base \
    linux-headers \
    && rm -rf /var/cache/apk/*

# Install pnpm globally
RUN npm install -g pnpm@latest

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Install Slither for security analysis (optional)
RUN pip3 install slither-analyzer || echo "Slither installation failed, continuing without it"

# Create non-root user for development
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/contracts/package.json ./packages/contracts/
COPY packages/ui/package.json ./packages/ui/
COPY apps/web/package.json ./apps/web/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Change ownership to non-root user
RUN chown -R nextjs:nodejs /app
USER nextjs

# Set environment variables
ENV NODE_ENV=development
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH:/root/.foundry/bin"

# Expose ports for development servers
EXPOSE 3000 8545

# Default command
CMD ["pnpm", "dev"]
