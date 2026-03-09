FROM eclipse-temurin:21-jdk-alpine
RUN apk upgrade --no-cache && adduser -D runner
USER runner
WORKDIR /code
