.PHONY: all help install-deps check-java install-java check-docker install-docker setup build test test-coverage run clean docker-up docker-down deploy logs

# Цвета для вывода
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Переменные
APP_NAME := service-template-atb
DOCKER_IMAGE := $(APP_NAME):latest
OS := $(shell uname -s)

## help: Показать справку по командам
help:
	@echo "$(GREEN)Доступные команды:$(NC)"
	@echo ""
	@echo "  $(YELLOW)Основные:$(NC)"
	@echo "    make all            - Полный запуск: проверка зависимостей + сборка + запуск"
	@echo "    make run            - Запустить приложение с PostgreSQL + Oracle и открыть Swagger"
	@echo "    make install-deps   - Установить все необходимые зависимости (Java, Docker)"
	@echo ""
	@echo "  $(YELLOW)Разработка:$(NC)"
	@echo "    make setup          - Запустить инфраструктуру (PostgreSQL)"
	@echo "    make setup-oracle   - Запустить инфраструктуру (PostgreSQL + Oracle)"
	@echo "    make build          - Собрать проект"
	@echo "    make test           - Запустить все тесты"
	@echo "    make test-coverage  - Запустить тесты с отчетом о покрытии"
	@echo "    make run-local      - Запустить приложение локально (только Spring Boot)"
	@echo "    make clean          - Очистить артефакты сборки"
	@echo "    make stop           - Остановить все контейнеры и приложение"
	@echo ""
	@echo "  $(YELLOW)Docker:$(NC)"
	@echo "    make docker-up      - Поднять все контейнеры (PostgreSQL + приложение)"
	@echo "    make docker-down    - Остановить все контейнеры"
	@echo "    make deploy         - Полный деплой с логом успеха"
	@echo "    make logs           - Показать логи контейнеров"
	@echo "    make swagger        - Открыть Swagger UI в браузере"

## all: Полный запуск (проверка зависимостей + установка + сборка + запуск)
all: install-deps setup build run

## install-deps: Установить все необходимые зависимости
install-deps: check-java check-docker
	@echo "$(GREEN)Все зависимости установлены!$(NC)"

## check-java: Проверить и установить Java если нужно
check-java:
	@echo "$(YELLOW)Проверка Java...$(NC)"
	@if command -v java >/dev/null 2>&1; then \
		JAVA_VERSION=$$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1); \
		if [ "$$JAVA_VERSION" -ge 17 ] 2>/dev/null; then \
			echo "$(GREEN)Java $$JAVA_VERSION найдена ✓$(NC)"; \
		else \
			echo "$(RED)Java версии $$JAVA_VERSION слишком старая. Требуется Java 17+$(NC)"; \
			$(MAKE) install-java; \
		fi \
	else \
		echo "$(RED)Java не найдена$(NC)"; \
		$(MAKE) install-java; \
	fi

## install-java: Установить Java 17
install-java:
	@echo "$(YELLOW)Установка Java 17...$(NC)"
ifeq ($(OS),Darwin)
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(YELLOW)Установка через Homebrew...$(NC)"; \
		brew install openjdk@17; \
		sudo ln -sfn $$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk; \
		echo "$(GREEN)Java 17 установлена!$(NC)"; \
	else \
		echo "$(RED)Homebrew не найден. Установите Homebrew (https://brew.sh) или установите Java вручную$(NC)"; \
		exit 1; \
	fi
else ifeq ($(OS),Linux)
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "$(YELLOW)Установка через apt...$(NC)"; \
		sudo apt-get update && sudo apt-get install -y openjdk-17-jdk; \
		echo "$(GREEN)Java 17 установлена!$(NC)"; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "$(YELLOW)Установка через yum...$(NC)"; \
		sudo yum install -y java-17-openjdk-devel; \
		echo "$(GREEN)Java 17 установлена!$(NC)"; \
	else \
		echo "$(RED)Пакетный менеджер не найден. Установите Java вручную$(NC)"; \
		exit 1; \
	fi
else
	@echo "$(RED)Неподдерживаемая ОС. Установите Java 17 вручную с https://adoptium.net/$(NC)"
	@exit 1
endif

## check-docker: Проверить и установить Docker если нужно
check-docker:
	@echo "$(YELLOW)Проверка Docker...$(NC)"
	@if command -v docker >/dev/null 2>&1; then \
		if docker info >/dev/null 2>&1; then \
			echo "$(GREEN)Docker найден и запущен ✓$(NC)"; \
		else \
			echo "$(YELLOW)Docker установлен, но не запущен.$(NC)"; \
			echo "$(YELLOW)Попытка запуска Docker Desktop...$(NC)"; \
			$(MAKE) start-docker || (echo "$(YELLOW)Не удалось запустить Docker автоматически.$(NC)" && echo "$(YELLOW)Пожалуйста, запустите Docker Desktop вручную и повторите команду.$(NC)" && exit 1); \
		fi \
	else \
		echo "$(RED)Docker не найден$(NC)"; \
		$(MAKE) install-docker; \
	fi

## install-docker: Установить Docker
install-docker:
	@echo "$(YELLOW)Установка Docker...$(NC)"
ifeq ($(OS),Darwin)
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(YELLOW)Установка Docker Desktop через Homebrew...$(NC)"; \
		brew install --cask docker; \
		echo "$(GREEN)Docker Desktop установлен!$(NC)"; \
		echo "$(YELLOW)Запускаю Docker Desktop... Пожалуйста, подождите...$(NC)"; \
		open -a Docker; \
		echo "$(YELLOW)Ожидание запуска Docker (это может занять минуту)...$(NC)"; \
		until docker info >/dev/null 2>&1; do sleep 2; done; \
		echo "$(GREEN)Docker запущен!$(NC)"; \
	else \
		echo "$(RED)Homebrew не найден. Установите Homebrew (https://brew.sh) или скачайте Docker Desktop с https://www.docker.com/products/docker-desktop$(NC)"; \
		exit 1; \
	fi
else ifeq ($(OS),Linux)
	@echo "$(YELLOW)Установка Docker для Linux...$(NC)"
	@curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
	@sudo sh /tmp/get-docker.sh
	@sudo usermod -aG docker $$USER
	@sudo systemctl start docker
	@sudo systemctl enable docker
	@echo "$(GREEN)Docker установлен! Возможно потребуется перелогиниться.$(NC)"
else
	@echo "$(RED)Неподдерживаемая ОС. Установите Docker вручную с https://www.docker.com/$(NC)"
	@exit 1
endif

## start-docker: Запустить Docker
start-docker:
ifeq ($(OS),Darwin)
	@if pgrep -x "Docker" > /dev/null; then \
		echo "$(YELLOW)Docker Desktop уже запущен, ожидание готовности...$(NC)"; \
	else \
		echo "$(YELLOW)Запуск Docker Desktop...$(NC)"; \
		open -a Docker 2>/dev/null || open -a "Docker Desktop" 2>/dev/null || (echo "$(RED)Не удалось запустить Docker Desktop$(NC)" && exit 1); \
	fi
	@echo "$(YELLOW)Ожидание готовности Docker (может занять до 60 секунд)...$(NC)"
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if docker info >/dev/null 2>&1; then \
			echo "$(GREEN)Docker готов!$(NC)"; \
			exit 0; \
		fi; \
		sleep 2; \
		timeout=$$((timeout - 2)); \
	done; \
	echo "$(RED)Таймаут ожидания запуска Docker. Запустите Docker Desktop вручную.$(NC)"; \
	exit 1
else ifeq ($(OS),Linux)
	@sudo systemctl start docker
	@echo "$(GREEN)Docker запущен!$(NC)"
endif

## setup: Запустить инфраструктуру (PostgreSQL)
setup:
	@echo "$(GREEN)Запуск инфраструктуры...$(NC)"
	@COMPOSE_PROFILES=dev docker compose up -d postgres
	@echo "$(YELLOW)Ожидание готовности PostgreSQL...$(NC)"
	@until docker compose exec -T postgres pg_isready > /dev/null 2>&1; do \
		echo "Ждем PostgreSQL..."; \
		sleep 2; \
	done
	@echo "$(GREEN)PostgreSQL готов!$(NC)"

## setup-oracle: Запустить инфраструктуру (PostgreSQL + Oracle)
setup-oracle:
	@echo "$(GREEN)Запуск инфраструктуры (PostgreSQL + Oracle)...$(NC)"
	@COMPOSE_PROFILES=dev-oracle docker compose up -d postgres oracle
	@echo "$(YELLOW)Ожидание готовности PostgreSQL...$(NC)"
	@until docker compose exec -T postgres pg_isready > /dev/null 2>&1; do \
		sleep 2; \
	done
	@echo "$(GREEN)PostgreSQL готов!$(NC)"
	@echo "$(YELLOW)Ожидание готовности Oracle (это может занять до 2-3 минут)...$(NC)"
	@timeout=180; \
	while [ $$timeout -gt 0 ]; do \
		if docker compose exec -T oracle bash -c 'healthcheck.sh' >/dev/null 2>&1; then \
			echo "$(GREEN)Oracle готов!$(NC)"; \
			break; \
		fi; \
		printf "."; \
		sleep 5; \
		timeout=$$((timeout - 5)); \
	done
	@echo ""
	@echo "$(YELLOW)Инициализация данных Oracle...$(NC)"
	@sleep 5
	@echo "$(GREEN)Инфраструктура готова!$(NC)"

## build: Собрать проект (без тестов)
build:
	@echo "$(GREEN)Сборка проекта...$(NC)"
	@./mvnw clean package -DskipTests
	@echo "$(GREEN)Сборка завершена!$(NC)"

## test: Запустить все тесты
test:
	@echo "$(GREEN)Запуск тестов...$(NC)"
	@./mvnw test
	@echo "$(GREEN)✓ Тесты успешно выполнены!$(NC)"

## test-coverage: Запустить тесты с отчетом о покрытии
test-coverage:
	@echo "$(GREEN)Запуск тестов с анализом покрытия...$(NC)"
	@./mvnw clean test
	@echo "$(GREEN)✓ Тесты выполнены! Отчет о покрытии создан.$(NC)"
	@echo "$(YELLOW)Откройте отчет: target/site/jacoco/index.html$(NC)"
ifeq ($(OS),Darwin)
	@open target/site/jacoco/index.html 2>/dev/null || true
else ifeq ($(OS),Linux)
	@xdg-open target/site/jacoco/index.html 2>/dev/null || true
endif

## run: Запустить приложение с PostgreSQL + Oracle и открыть Swagger
run: check-docker setup-oracle build
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Запуск приложения...$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Swagger UI откроется автоматически через несколько секунд...$(NC)"
	@echo ""
	@(sleep 8 && $(MAKE) swagger) &
	@ORACLE_DATASOURCE_URL=jdbc:oracle:thin:@localhost:1521/FREEPDB1 \
	ORACLE_DATASOURCE_USERNAME=oracleuser \
	ORACLE_DATASOURCE_PASSWORD=oraclepass \
	./mvnw spring-boot:run

## run-local: Запустить приложение локально (только Spring Boot, БД должна быть запущена)
run-local:
	@echo "$(GREEN)Запуск приложения...$(NC)"
	@echo "$(GREEN)Swagger UI будет доступен: http://localhost:8080/swagger-ui/index.html$(NC)"
	@ORACLE_DATASOURCE_URL=jdbc:oracle:thin:@localhost:1521/FREEPDB1 \
	ORACLE_DATASOURCE_USERNAME=oracleuser \
	ORACLE_DATASOURCE_PASSWORD=oraclepass \
	./mvnw spring-boot:run

## clean: Очистить артефакты сборки
clean:
	@echo "$(GREEN)Очистка...$(NC)"
	@./mvnw clean

## stop: Остановить все контейнеры
stop:
	@echo "$(GREEN)Остановка всех контейнеров...$(NC)"
	@COMPOSE_PROFILES=dev docker compose down 2>/dev/null || true
	@COMPOSE_PROFILES=dev-oracle docker compose down 2>/dev/null || true
	@docker compose down 2>/dev/null || true
	@echo "$(GREEN)Все контейнеры остановлены!$(NC)"

## docker-up: Поднять все контейнеры (PostgreSQL + приложение)
docker-up:
	@echo "$(GREEN)Сборка Docker образа...$(NC)"
	@docker build -t $(DOCKER_IMAGE) .
	@echo "$(GREEN)Запуск всех контейнеров...$(NC)"
	@COMPOSE_PROFILES=dev docker compose up -d

## docker-down: Остановить все контейнеры
docker-down:
	@echo "$(GREEN)Остановка контейнеров...$(NC)"
	@COMPOSE_PROFILES=dev docker compose down

## deploy: Полный деплой с логом успеха
deploy: docker-up
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ ДЕПЛОЙ УСПЕШНО ЗАВЕРШЕН!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Приложение доступно:$(NC)"
	@echo "  - Swagger UI: http://localhost:8080/swagger-ui/index.html"
	@echo "  - API Docs:   http://localhost:8080/v3/api-docs"
	@echo ""
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker compose ps

## logs: Показать логи контейнеров
logs:
	@docker compose logs -f

## swagger: Открыть Swagger UI в браузере
swagger:
	@echo "$(YELLOW)Проверка готовности приложения...$(NC)"
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if curl -s http://localhost:8080/actuator/health >/dev/null 2>&1; then \
			echo "$(GREEN)Приложение готово!$(NC)"; \
			echo "$(GREEN)Открываю Swagger UI...$(NC)"; \
			open http://localhost:8080/swagger-ui/index.html 2>/dev/null || xdg-open http://localhost:8080/swagger-ui/index.html 2>/dev/null || echo "$(YELLOW)Откройте http://localhost:8080/swagger-ui/index.html в браузере$(NC)"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 2; \
		timeout=$$((timeout - 2)); \
	done; \
	echo "$(RED)Таймаут ожидания запуска приложения$(NC)"
