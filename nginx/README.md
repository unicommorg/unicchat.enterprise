# Nginx + Let's Encrypt SSL для UnicChat Enterprise

Автоматизированное решение для настройки Nginx с SSL сертификатами через Let's Encrypt для 3 доменов UnicChat.

## 📋 Требования

- **Docker** (версия 20.10+)
- **Docker Compose** (версия 2.0+ plugin или 1.29+ standalone)
- **Права root** или возможность выполнять команды через `sudo`
- **3 DNS имени** (A-записи), указывающие на IP сервера:
  - `app.domain.com` - основное приложение UnicChat
  - `edt.domain.com` - DocumentServer (OnlyOffice)
  - `minio.domain.com` - MinIO S3 хранилище
- **Открытые порты**: 80, 443 в firewall
- **Email** для уведомлений Let's Encrypt

### Проверка установки Docker

```bash
# Проверить Docker
docker --version

# Проверить Docker Compose
docker compose version
# или
docker-compose --version
```

## 📁 Структура проекта

```
nginx/
├── docker-compose.yml          # Nginx + Certbot контейнеры
├── generate_ssl.sh             # Скрипт управления SSL и Nginx
├── .gitignore                  # Исключение SSL сертификатов и конфигов
├── README.md                   # Эта документация
├── config/                     # Конфигурации (генерируются автоматически)
│   └── nginx.conf              # Конфигурация для 3 доменов (не в git)
├── ssl/                        # SSL сертификаты и конфигурация
│   ├── options-ssl-nginx.conf  # SSL параметры Mozilla (в git)
│   ├── ssl-dhparams.pem        # DH parameters (генерируется, не в git)
│   └── live/                   # Сертификаты Let's Encrypt (не в git)
│       └── app.domain.com/
└── www/                        # Challenge файлы Let's Encrypt (не в git)
```

## 🚀 Быстрый старт

### Шаг 1: Настройка DNS имен

DNS имена должны быть настроены **до** запуска этого скрипта через главный скрипт `unicchat.sh`:

```bash
cd /path/to/unicchat.enterprise
sudo ./unicchat.sh

# В меню выберите:
# [2] Setup DNS names for services (APP, EDT, MinIO)

# Введите ваши 3 DNS имени:
# - APP_DNS: app.domain.com
# - EDT_DNS: edt.domain.com  
# - MINIO_DNS: minio.domain.com
```

Это создаст файл `../dns_config.txt` с вашими DNS именами.

### Шаг 2: Проверка DNS записей

Убедитесь, что все 3 домена указывают на IP вашего сервера:

```bash
dig app.domain.com +short
dig edt.domain.com +short
dig minio.domain.com +short

# Все должны вернуть IP вашего сервера
```

### Шаг 3: Настройка firewall

```bash
# Для UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# Проверка
sudo ufw status
```

### Шаг 4: Автоматическая установка SSL и Nginx

```bash
cd /path/to/unicchat.enterprise/nginx
sudo ./generate_ssl.sh

# В меню выберите:
# [99] 🚀 Полная автоустановка (SSL + nginx)

# Введите email для Let's Encrypt (если не настроен ранее)
```

Скрипт автоматически выполнит:
1. ✅ Проверит наличие `options-ssl-nginx.conf` (включен в репозиторий)
2. ✅ Сгенерирует DH parameters 2048 bit (уникальные для вашего сервера)
3. ✅ Остановит nginx (если запущен)
4. ✅ Получит SSL сертификат для всех 3 доменов
5. ✅ Сгенерирует конфигурацию Nginx
6. ✅ Запустит Nginx с SSL
7. ✅ Запустит Certbot для автообновления

### Шаг 5: Проверка работы

```bash
# Проверить статус
curl -I https://app.domain.com
curl -I https://edt.domain.com
curl -I https://minio.domain.com

# Или откройте в браузере
```

## 📖 Меню скрипта

После запуска `sudo ./generate_ssl.sh` доступны следующие опции:

### Основные операции

- **[1] 🔐 Генерация SSL сертификатов (Let's Encrypt)**
  - Получить SSL сертификаты для всех 3 доменов
  - Автоматически останавливает nginx перед генерацией
  - Использует standalone режим Certbot
  
- **[2] 📝 Генерация/обновление конфигурации nginx**
  - Создает `config/nginx.conf` для 3 доменов
  - Настраивает upstream для каждого сервиса
  - Добавляет SSL конфигурацию

- **[3] 🌐 Запуск nginx**
  - Запускает контейнер nginx с SSL
  - Проверяет healthcheck
  - Показывает статус worker process

- **[4] 🛑 Остановка nginx**
  - Останавливает и удаляет контейнер nginx

- **[5] 🔄 Перезапуск nginx**
  - Останавливает и запускает nginx заново
  - Полезно после изменения конфигурации

### Мониторинг

- **[6] 📊 Статус сервисов**
  - Показывает статус nginx (с healthcheck)
  - Показывает статус certbot
  - Информация о SSL сертификатах
  - Прослушиваемые порты

- **[7] 📋 Логи nginx**
  - Показывает последние 50 строк логов nginx

- **[8] 🔍 Проверка конфигурации nginx**
  - Проверяет синтаксис конфигурации
  - Запускает `nginx -t` внутри контейнера

### Автоматизация

- **[99] 🚀 Полная автоустановка (SSL + nginx)**
  - Выполняет все шаги автоматически
  - Генерирует SSL сертификаты
  - Запускает nginx и certbot
  - Показывает финальный статус

- **[0] 🚪 Выход**

## 🏗️ Архитектура Nginx

### Upstream конфигурация

```nginx
# App Server (UnicChat)
upstream app_server {
    server unicchat-appserver:3000;
}

# Document Server (OnlyOffice)
upstream doc_server {
    server unicchat-documentserver:80;
}

# MinIO S3 API
upstream minio_server {
    server unicchat-minio:9000;
}

```

### Виртуальные хосты

| Домен | Upstream | Порт | Назначение |
|-------|----------|------|------------|
| `app.domain.com` | unicchat-appserver:3000 | 443 | Основное приложение |
| `edt.domain.com` | unicchat-documentserver:80 | 443 | OnlyOffice DocumentServer |
| `minio.domain.com` | unicchat-minio:9000 | 443 | MinIO S3 API |

### Особенности конфигурации

- ✅ **HTTP/2** включен (современный синтаксис: `http2 on;`)
- ✅ **CORS headers** для App Server
- ✅ **WebSocket** поддержка для App Server
- ✅ **Large file uploads** для MinIO (500MB)
- ✅ **SSL/TLS** с A+ рейтингом
- ✅ **HTTP → HTTPS** редирект для всех доменов

## 🔄 Автоматическое обновление SSL

Контейнер `unicchat-certbot` автоматически:
- Проверяет сертификаты **каждые 12 часов**
- Обновляет сертификаты **за 30 дней до истечения**
- Сертификаты Let's Encrypt действительны **90 дней**

Проверка работы Certbot:

```bash
# Статус контейнера
docker ps | grep certbot

# Логи
docker logs unicchat-certbot

# Список сертификатов
docker exec unicchat-certbot certbot certificates
```

## 🔧 Troubleshooting

### Проблема: Порты 80/443 заняты

```bash
# Проверить что использует порты
sudo ss -tulpn | grep -E ':(80|443)'

# Остановить nginx
cd nginx
sudo ./generate_ssl.sh
# Выберите [4] Остановка nginx
```

### Проблема: DNS не резолвится

```bash
# Проверить DNS для всех доменов
dig app.domain.com +short
dig edt.domain.com +short
dig minio.domain.com +short

# Проверить с внешнего сервера
nslookup app.domain.com 8.8.8.8
```

### Проблема: Не удается получить SSL

**Частые причины:**

1. **DNS не указывает на сервер**
   ```bash
   dig app.domain.com +short
   # Должен вернуть IP вашего сервера
   ```

2. **Порт 80 недоступен извне**
   ```bash
   # С другого компьютера
   curl http://app.domain.com
   ```

3. **Firewall блокирует порты**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

4. **Cloud provider Security Groups**
   - Проверьте настройки облачного провайдера
   - Откройте порты 80 и 443 в Security Groups

5. **Email не указан**
   ```bash
   # Скрипт запросит email автоматически
   # Или создайте файл:
   echo "EMAIL=your@email.com" >> ../unicchat_config.txt
   ```

### Проблема: Nginx не запускается

```bash
# Проверить логи
docker logs unicchat-nginx

# Проверить конфигурацию
docker exec unicchat-nginx nginx -t

# Проверить healthcheck
docker inspect unicchat-nginx | grep -A 10 Health

# Через меню
cd nginx
sudo ./generate_ssl.sh
# [7] Логи nginx
# [8] Проверка конфигурации
```

### Проблема: Healthcheck unhealthy

```bash
# Проверить worker process
docker exec unicchat-nginx ps aux | grep nginx

# Проверить порты внутри контейнера
docker exec unicchat-nginx netstat -tuln | grep -E ':(80|443)'

# Перезапустить nginx
cd nginx
sudo ./generate_ssl.sh
# [5] Перезапуск nginx
```

### Проблема: SSL сертификат не найден

```bash
# Проверить наличие сертификатов
ls -la ssl/live/*/

# Если пусто - сгенерировать заново
cd nginx
sudo ./generate_ssl.sh
# [1] Генерация SSL сертификатов
```

### Проблема: Permission denied

```bash
# Выдать права на выполнение
chmod +x generate_ssl.sh

# Запускать с sudo
sudo ./generate_ssl.sh

# Проверить владельца .git
ls -la ../.git
```

## 📝 Важные файлы

### В репозитории (включены в git)

```
nginx/
├── docker-compose.yml
├── generate_ssl.sh
├── README.md
├── .gitignore
└── ssl/
    └── options-ssl-nginx.conf  # SSL параметры (Mozilla SSL Config)
```

### Генерируемые автоматически (не в git)

```
nginx/
├── ssl/
│   ├── ssl-dhparams.pem        # DH parameters 2048 bit (генерируется)
│   ├── live/                   # SSL сертификаты Let's Encrypt
│   │   └── app.domain.com/
│   │       ├── fullchain.pem   # Полная цепочка сертификатов
│   │       ├── privkey.pem     # Приватный ключ
│   │       └── ...
│   ├── accounts/               # Let's Encrypt аккаунты
│   ├── archive/                # Архив сертификатов
│   └── renewal/                # Конфигурация обновления
├── www/                        # Let's Encrypt challenges
├── config/
│   └── nginx.conf              # Сгенерированная конфигурация
└── logs/                       # Логи nginx (Docker volume)
```

### Конфигурационные файлы

- `../dns_config.txt` - DNS имена (создается через `unicchat.sh`)
- `../unicchat_config.txt` - Email для SSL (создается автоматически)
- `docker-compose.yml` - Docker Compose конфигурация
- `.gitignore` - Исключение чувствительных данных

## 🔒 Безопасность

### Исключено из git (.gitignore)

```
ssl/*                           # SSL сертификаты и ключи (кроме options-ssl-nginx.conf)
!ssl/options-ssl-nginx.conf     # Исключение: SSL параметры включены в git
www/                            # Challenge файлы
config/nginx.conf               # Сгенерированная конфигурация
config/*.conf                   # Все конфигурации
*.log                           # Логи
```

**Почему `ssl-dhparams.pem` не в git:**
- DH parameters должны быть уникальными для каждого сервера (безопасность)
- Генерируются автоматически при первой установке (занимает 1-2 минуты)
- Размер файла небольшой (~400 байт), но содержимое должно быть случайным

### Рекомендации

1. **Не коммитить** SSL сертификаты и приватные ключи
2. **Ограничить доступ** к файлам сертификатов (600/700)
3. **Регулярно обновлять** Docker образы
4. **Использовать firewall** для ограничения доступа
5. **Мониторить** истечение сертификатов

## 🔗 Интеграция с UnicChat

### Порядок установки

1. **Сначала** установите UnicChat через `unicchat.sh`:
   ```bash
   cd /path/to/unicchat.enterprise
   sudo ./unicchat.sh
   # [99] Full automatic setup
   ```

2. **Затем** настройте Nginx и SSL:
   ```bash
   cd nginx
   sudo ./generate_ssl.sh
   # [99] Полная автоустановка
   ```

### Проверка интеграции

```bash
# Проверить Docker сеть
docker network inspect unicchat-network

# Проверить что все контейнеры в одной сети
docker ps --format "table {{.Names}}\t{{.Networks}}"

# Проверить доступность upstream
docker exec unicchat-nginx curl -I http://unicchat-appserver:3000
docker exec unicchat-nginx curl -I http://unicchat-documentserver:80
docker exec unicchat-nginx curl -I http://unicchat-minio:9000
```

## 📚 Дополнительные ресурсы

- [Документация Nginx](https://nginx.org/ru/docs/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Certbot](https://eff-certbot.readthedocs.io/)
- [Docker Compose](https://docs.docker.com/compose/)
- [HTTP/2 в Nginx](https://nginx.org/en/docs/http/ngx_http_v2_module.html)

---

**Версия**: 2.0  
**Дата обновления**: 2026-01-23  
**Автор**: UnicChat Team
