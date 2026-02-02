# Multi-stage build для оптимизации размера образа

# Stage 1: Build
FROM eclipse-temurin:17-jdk AS builder

WORKDIR /app

# Копируем Maven Wrapper и pom.xml для кэширования зависимостей
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Делаем mvnw исполняемым и скачиваем зависимости
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Копируем исходный код и собираем
COPY src src
RUN ./mvnw package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:17-jre

WORKDIR /app

# Создаем пользователя для безопасности
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -m appuser

# Копируем JAR из builder stage
COPY --from=builder /app/target/*.jar app.jar

# Меняем владельца
RUN chown -R appuser:appgroup /app

USER appuser

# Expose порт
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Запуск приложения
ENTRYPOINT ["java", "-jar", "app.jar"]
