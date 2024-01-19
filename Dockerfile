
FROM node:18 as builder

WORKDIR /build 

COPY package*.json .
RUN npm install

COPY src/ src/
COPY tsconfig.json tsconfig.json

RUN npm run build


FROM node:alpine as runner

WORKDIR /app
COPY --from=builder build/package*.json .
COPY --from=builder build/dist dist/
RUN npm install --only=prod

CMD [ "npm","start" ]