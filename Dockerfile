FROM node:20-alpine

WORKDIR /app

# Install docker CLI to allow running jobspy container
RUN apk add --no-cache docker-cli

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies (production only)
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Environment variables with defaults
ENV JOBSPY_HOST=0.0.0.0
ENV JOBSPY_PORT=9423
ENV ENABLE_SSE=1
ENV JOBSPY_DOCKER_IMAGE=jobspy

# Expose port
EXPOSE 9423

# Start the server
CMD ["node", "src/index.js"]
