FROM node:18-alpine

WORKDIR /app

# Install simple HTTP server
RUN npm install -g http-server

# Copy the frontend files
COPY index.html .

# Create a simple nginx-like config for CORS proxy
RUN npm install -g cors-anywhere

# Expose port
EXPOSE 8080

# Start HTTP server
CMD ["http-server", "-p", "8080", "--cors"]
