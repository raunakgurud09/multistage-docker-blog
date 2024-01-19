# Stage 1: Build Stage
FROM node:18 as builder

WORKDIR /build 

COPY package*.json .
RUN npm install

COPY src/ src/
COPY tsconfig.json tsconfig.json

RUN npm run build


# Stage 2: Runtime Stage
FROM node as runner

WORKDIR /app
COPY --from=builder build/package*.json .
COPY --from=builder build/dist dist/
RUN npm install --only=prod

CMD [ "npm","start" ]