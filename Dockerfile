# syntax=docker/dockerfile:1

# Use the Node.js version specified in .nvmrc
FROM node:20.19-alpine AS base

# Set working directory
WORKDIR /app

FROM base AS dependencies

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

FROM dependencies AS prod

# Copy the rest of the application code
COPY . .

# Expose application port (change if needed)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]