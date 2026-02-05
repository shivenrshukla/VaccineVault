# Use Node.js LTS version
FROM node:20-slim

# Create app directory
WORKDIR /usr/src/app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm install

# Copy application source
COPY . .

# The app binds to port 5000 by default in index.js
EXPOSE 5000

# Start the application using the "start" script from package.json
# This runs the API, worker, and scheduler in parallel
CMD ["npm", "run", "start:docker"]