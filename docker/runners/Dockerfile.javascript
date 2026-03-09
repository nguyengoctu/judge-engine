FROM node:20-alpine
RUN apk upgrade --no-cache && adduser -D runner
USER runner
WORKDIR /code
