# UnicChat Enterprise - Корпоративный мессенджер

Версия: 2.1.85-beta.0  
Документация: v2.0  
Дата обновления: 2026-01-23

## 📋 Содержание

- [Описание](#описание)
- [Системные требования](#системные-требования)
- [Быстрый старт](#быстрый-старт)
- [Подробная установка](#подробная-установка)
- [Архитектура](#архитектура)
- [Управление сервисами](#управление-сервисами)
- [Troubleshooting](#troubleshooting)

---

## Описание

UnicChat Enterprise - корпоративный мессенджер для безопасного общения и командной работы с поддержкой:

- 💬 Текстовые чаты и каналы
- 📞 Аудио/видео звонки
- 📄 Совместное редактирование документов (OnlyOffice)
- 📚 База знаний (Knowledge Base)
- 🔐 Хранилище секретов (Vault)
- 📦 Объектное хранилище (MinIO S3)
- 🔒 End-to-end шифрование

---

## Системные требования

### Минимальные требования (тестовая среда)
- **CPU**: 2 ядра
- **RAM**: 4 GB (минимум 2 GB + 2 GB swap)
- **Диск**: 40 GB SSD
- **ОС**: Ubuntu 20.04/22.04 LTS
- **Docker**: 20.10+
- **Docker Compose**: 2.0+ (plugin) или 1.29+ (standalone)

### Рекомендуемые требования (production)
- **CPU**: 4+ ядра
- **RAM**: 8+ GB
- **Диск**: 100+ GB SSD
- **ОС**: Ubuntu 22.04 LTS
- **Docker**: 24.0+
- **Docker Compose**: 2.20+

### Сетевые требования
- Открытые порты: 80, 443, 27017 (MongoDB), 8200 (Vault)
- 3 DNS имени (A-записи):
  - `app.domain.com` - основное приложение
  - `edt.domain.com` - DocumentServer (OnlyOffice)
  - `minio.domain.com` - MinIO S3

---

## Быстрый старт

### 1. Предварительные требования

```bash
# Проверка Docker
docker --version
docker compose version  # или docker-compose --version

# Если Docker не установлен - установите:
# curl -fsSL https://get.docker.com | sh
# sudo usermod -aG docker $USER
```

### 2. Клонирование репозитория

```bash
git clone <repository-url> unicchat.enterprise
cd unicchat.enterprise
```

### 3. Автоматическая установка

```bash
sudo ./unicchat.sh

# В меню выберите:
# [99] 🚀 Full automatic setup

# Или пошагово:
# [2] Setup DNS names
# [3] Update MongoDB configuration
# [4] Update MinIO configuration
# [5] Prepare .env files
# [6] Login to Yandex registry
# [7] Create Docker network
# [8] Start UnicChat containers
# [9] Setup MongoDB users
# [10] Setup Vault secrets
```

### 4. Настройка SSL и Nginx

```bash
cd nginx
sudo ./generate_ssl.sh

# В меню выберите:
# [99] 🚀 Полная автоустановка (SSL + nginx)
```

### 5. Проверка установки

```bash
# Проверка статуса контейнеров
docker ps

# Проверка логов
docker logs unicchat.appserver
docker logs unicchat.nginx

# Доступ к приложению
# https://app.domain.com
```

---

## Подробная установка

### Шаг 1: Настройка DNS имен

Скрипт запросит 3 DNS имени для сервисов:

```bash
sudo ./unicchat.sh
# Выберите [2] Setup DNS names

# Введите:
# - APP_DNS: app.domain.com (основное приложение)
# - EDT_DNS: edt.domain.com (DocumentServer)
# - MINIO_DNS: minio.domain.com (MinIO S3)
```

**Важно**: DNS записи должны быть настроены до установки SSL!

### Шаг 2: Настройка MongoDB

```bash
# В меню выберите [3] Update MongoDB configuration

# Будет запрошено:
# - MONGODB_ROOT_PASSWORD: пароль root пользователя
# - MONGODB_USERNAME: имя пользователя приложения
# - MONGODB_PASSWORD: пароль пользователя приложения
# - MONGODB_DATABASE: имя базы данных (по умолчанию: unicchat_db)

# Дополнительно (для сервисов):
# - LOGGER_USER/PASSWORD/DB: для сервиса логирования
# - VAULT_USER/PASSWORD/DB: для Vault
```

### Шаг 3: Настройка MinIO

```bash
# В меню выберите [4] Update MinIO configuration

# Будет запрошено:
# - MINIO_ROOT_USER: администратор MinIO (по умолчанию: minioadmin)
# - MINIO_ROOT_PASSWORD: пароль администратора
```

### Шаг 4: Генерация конфигурационных файлов

```bash
# В меню выберите [5] Prepare .env files

# Скрипт создаст:
# ✅ mongo.env - конфигурация replica set
# ✅ mongo_creds.env - пароли MongoDB
# ✅ logger_creds.env - MongoDB для Logger
# ✅ vault_creds.env - MongoDB для Vault
# ✅ appserver.env - публичная конфигурация AppServer
# ✅ appserver_creds.env - чувствительные данные AppServer
# ✅ logger.env - Logger API URL
# ✅ env/minio_env.env - MinIO credentials
# ✅ env/documentserver_env.env - DocumentServer config
```

### Шаг 5: Вход в Docker Registry

```bash
# В меню выберите [6] Login to Yandex registry
# (автоматически выполняется с встроенным токеном)
```

### Шаг 6: Создание Docker сети

```bash
# В меню выберите [7] Create Docker network
# Создается сеть: unicchat-network
```

### Шаг 7: Запуск контейнеров

```bash
# В меню выберите [8] Start UnicChat containers

# Порядок запуска:
# 1. MongoDB (с healthcheck)
# 2. Vault + Logger (параллельно)
# 3. AppServer (после Vault)
# 4. Tasker (после AppServer + Logger)
# 5. MinIO + DocumentServer (независимо)
```

**Время запуска**: ~60-90 секунд

### Шаг 8: Создание пользователей MongoDB

```bash
# В меню выберите [9] Setup MongoDB users

# Автоматически создаются пользователи:
# - logger_user (для Logger service)
# - vault_user (для Vault service)
```

### Шаг 9: Настройка Vault секретов

```bash
# В меню выберите [10] Setup Vault secrets

# Автоматически создается секрет KBTConfigs с:
# - MongoDB connection string для Logger
# - MinIO credentials (host, user, password)
```

### Шаг 10: Настройка SSL и Nginx

```bash
cd nginx
sudo ./generate_ssl.sh

# Автоматическая установка:
# [99] Полная автоустановка

# Или пошагово:
# [1] Генерация SSL сертификатов (Let's Encrypt)
# [2] Генерация конфигурации nginx
# [3] Запуск nginx
```

**Важно**: Для получения SSL сертификатов:
- DNS записи должны указывать на IP сервера
- Порты 80 и 443 должны быть открыты
- Требуется email для уведомлений Let's Encrypt

---

## Архитектура

### Компоненты системы

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Nginx (SSL/TLS)    │
              │   Ports: 80, 443     │
              └──────────┬───────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  AppServer  │  │ DocumentSrv │  │    MinIO    │
│  Port 3000  │  │  Port 8880  │  │  Port 9000  │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       │         ┌──────┴──────┐        │
       │         │             │        │
       ▼         ▼             ▼        ▼
┌─────────────────────────────────────────┐
│           MongoDB (Replica Set)         │
│              Port 27017                 │
└─────────────────┬───────────────────────┘
                  │
       ┌──────────┼──────────┐
       │          │          │
       ▼          ▼          ▼
┌──────────┐ ┌────────┐ ┌────────┐
│  Vault   │ │ Logger │ │ Tasker │
│ Port 8200│ │Prt 8082│ │Prt 8881│
└──────────┘ └────────┘ └────────┘
```

### Порядок запуска сервисов

```
1. MongoDB (первым, с healthcheck)
   ↓
2. Vault + Logger (параллельно, после MongoDB)
   ↓
3. AppServer (после Vault)
   ↓
4. Tasker (после AppServer + Logger)

Параллельно и независимо:
- MinIO → MinIO Init (создание bucket)
- DocumentServer + RabbitMQ + PostgreSQL
```

### Сервисы

| Сервис | Контейнер | Порт | Описание |
|--------|-----------|------|----------|
| **AppServer** | unicchat.appserver | 3000 | Основное приложение |
| **MongoDB** | unicchat.mongodb | 27017 | База данных (Replica Set) |
| **Vault** | unicchat.vault | 8200 | Хранилище секретов |
| **Logger** | unicchat.logger | 8082 | Сервис логирования |
| **Tasker** | unicchat.tasker | 8881 | Knowledge Base и задачи |
| **MinIO** | unicchat.minio | 9000, 9002 | S3-хранилище + Console |
| **DocumentServer** | unicchat.documentserver | 8880, 8443 | OnlyOffice |
| **Nginx** | unicchat.nginx | 80, 443 | Reverse proxy + SSL |
| **Certbot** | unicchat.certbot | - | Автообновление SSL |

---

## Управление сервисами

### Основные команды

```bash
# Проверка статуса всех контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Просмотр логов
docker logs unicchat.appserver
docker logs unicchat.mongodb
docker logs unicchat.vault
docker logs unicchat.nginx

# Перезапуск сервиса
docker restart unicchat.appserver

# Остановка всех сервисов
cd multi-server-install
docker compose down

# Запуск всех сервисов
docker compose up -d

# Проверка healthcheck
docker inspect unicchat.mongodb | grep -A 5 Health
docker inspect unicchat.minio | grep -A 5 Health
docker inspect unicchat.nginx | grep -A 5 Health
```

### Использование меню unicchat.sh

```bash
sudo ./unicchat.sh

# Доступные опции:
[1]  Check AVX support
[2]  Setup DNS names for services (APP, EDT, MinIO)
[3]  Update MongoDB configuration
[4]  Update MinIO configuration
[5]  Prepare .env files
[6]  Login to Yandex registry
[7]  Create Docker network
[8]  Start UnicChat containers
[9]  Setup MongoDB users (separate DB per service)
[10] Setup Vault secrets for KBT service
[11] Restart all services
[99] 🚀 Full automatic setup
[100] 🗑️ Cleanup (remove containers & volumes)
[0]  Exit
```

### Использование меню nginx/generate_ssl.sh

```bash
cd nginx
sudo ./generate_ssl.sh

# Доступные опции:
[1] 🔐 Генерация SSL сертификатов (Let's Encrypt)
[2] 📝 Генерация/обновление конфигурации nginx
[3] 🌐 Запуск nginx
[4] 🛑 Остановка nginx
[5] 🔄 Перезапуск nginx
[6] 📊 Статус сервисов
[7] 📋 Логи nginx
[8] 🔍 Проверка конфигурации nginx
[99] 🚀 Полная автоустановка (SSL + nginx)
[0] 🚪 Выход
```

---

## Troubleshooting

### Проблема: Контейнеры не запускаются

```bash
# Проверка логов Docker
docker logs <container_name>

# Проверка сети
docker network inspect unicchat-network

# Проверка портов
ss -tuln | grep -E ':(80|443|27017|8200)'

# Перезапуск Docker
sudo systemctl restart docker
```

### Проблема: MongoDB не готов

```bash
# Проверка healthcheck
docker inspect unicchat.mongodb | grep -A 10 Health

# Проверка логов
docker logs unicchat.mongodb

# Подключение к MongoDB
docker exec -it unicchat.mongodb mongosh -u root -p <password>
```

### Проблема: Vault не подключается к MongoDB

```bash
# Проверка vault_creds.env
cat multi-server-install/vault_creds.env

# Проверка логов Vault
docker logs unicchat.vault

# Проверка подключения
docker exec unicchat.vault bash -c "curl -s http://localhost:80/health"
```

### Проблема: SSL сертификаты не получаются

```bash
# Проверка DNS
dig app.domain.com
dig edt.domain.com
dig minio.domain.com

# Проверка портов 80/443
sudo ss -tuln | grep -E ':(80|443)'

# Проверка логов Certbot
docker logs unicchat.certbot

# Ручное получение сертификатов
cd nginx
sudo ./generate_ssl.sh
# Выберите [1] Генерация SSL сертификатов
```

### Проблема: Недостаточно памяти

```bash
# Проверка использования памяти
free -h
docker stats --no-stream

# Очистка Docker
docker system prune -a

# Добавление swap (если нужно)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Проблема: Диск заполнен

```bash
# Проверка использования диска
df -h

# Очистка Docker volumes
docker volume prune

# Очистка логов
sudo journalctl --vacuum-time=7d

# Проверка больших файлов
sudo du -sh /var/lib/docker/*
```

---

## Файлы конфигурации

### Генерируемые файлы (исключены из git)

```
multi-server-install/
├── mongo.env              # Конфигурация replica set
├── mongo_creds.env        # Пароли MongoDB (SENSITIVE)
├── logger_creds.env       # MongoDB для Logger (SENSITIVE)
├── vault_creds.env        # MongoDB для Vault (SENSITIVE)
├── appserver.env          # Публичная конфигурация AppServer
├── appserver_creds.env    # Credentials AppServer (SENSITIVE)
├── logger.env             # Logger API URL
└── env/
    ├── minio_env.env      # MinIO credentials (SENSITIVE)
    └── documentserver_env.env  # DocumentServer config

dns_config.txt             # DNS имена (SENSITIVE)
mongo_config.txt           # MongoDB config (SENSITIVE)
minio_config.txt           # MinIO config (SENSITIVE)
unicchat_config.txt        # Email для SSL (SENSITIVE)
```

### Структура проекта

```
unicchat.enterprise/
├── unicchat.sh                    # Главный скрипт установки
├── README.md                      # Эта документация
├── .gitignore                     # Исключение чувствительных данных
├── multi-server-install/
│   ├── docker-compose.yml         # Единый compose для всех сервисов
│   ├── appserver.env.example      # Пример конфигурации
│   └── services/                  # Отдельные compose файлы
│       ├── mongodb.yml
│       ├── vault.yml
│       ├── appserver.yml
│       ├── logger.yml
│       ├── tasker.yml
│       ├── minio.yml
│       ├── documentserver.yml
│       └── README.md
└── nginx/
    ├── generate_ssl.sh            # SSL и Nginx автоматизация
    ├── docker-compose.yml         # Nginx + Certbot
    ├── .gitignore
    └── README.md
```

---

## Безопасность

### Чувствительные данные

**НЕ коммитить в git:**
- `*_creds.env` - файлы с паролями
- `*.env` (кроме `*.env.example`)
- `dns_config.txt`, `mongo_config.txt`, `minio_config.txt`
- `nginx/ssl/` - SSL сертификаты
- `nginx/config/` - сгенерированные конфигурации

### Рекомендации

1. **Используйте сильные пароли** для MongoDB, MinIO, Vault
2. **Регулярно обновляйте** SSL сертификаты (автоматически через Certbot)
3. **Делайте backup** MongoDB данных
4. **Ограничьте доступ** к портам через firewall
5. **Используйте VPN** для доступа к административным портам

---

## Поддержка

- **Email**: support@unic.chat
- **Документация**: [docs.unic.chat](https://docs.unic.chat)
- **Issues**: [GitHub Issues](https://github.com/unicchat/enterprise/issues)

---

## Лицензия

UnicChat Enterprise - проприетарное ПО.  
Для получения лицензии обратитесь: license@unic.chat

---

**Версия документа**: 2.0  
**Дата обновления**: 2026-01-23  
**Автор**: UnicChat Team
