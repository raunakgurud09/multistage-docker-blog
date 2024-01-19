# Base image
FROM node:18

# Setup workdir
WORKDIR /usr/app

COPY package*.json .

# Install Dependencies
RUN npm install

# Copy Application Code
COPY . .

# Build Application
RUN npm run build

# Run Command
EXPOSE 8090
CMD node dist/index.js