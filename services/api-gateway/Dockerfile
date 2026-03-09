# --- Build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests -B

# --- Runtime stage ---
FROM eclipse-temurin:21-jre-alpine
RUN apk upgrade --no-cache
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
