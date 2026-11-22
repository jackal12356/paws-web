FROM node:20-slim

WORKDIR /app

# Copy the whole project first so postinstall/build scripts are present.
COPY . .

# Install (postinstall fetches the service binary into ./bin under a neutral name).
RUN npm install --omit=dev || npm install

ENV NODE_ENV=production

# Platform injects PORT; server binds 0.0.0.0:$PORT.
CMD ["node", "server.js"]
