# Stage 1: Build & Dependencies
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production

# Stage 2: Production Image (Tối ưu kích thước)
FROM node:18-alpine
WORKDIR /app
COPY . .
COPY --from=builder /app/node_modules ./node_modules

# Expose port
EXPOSE 3001

# Run the application
CMD ["npm", "start"]
