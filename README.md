# Руководство по установке UnicChat Enterprise

Это руководство описывает процесс установки UnicChat Enterprise, включая приложение для чата, видеоконференции (VCS) и базу знаний (MinIO и OnlyOffice) на сервере с Ubuntu 20+.

## Содержание
1. [Обзор](#обзор)
2. [Предварительные требования](#предварительные-требования)
3. [Структура директорий](#структура-директорий)
4. [Шаг 1: Регистрация DNS-имен](#шаг-1-регистрация-dns-имен)
5. [Шаг 2: Настройка окружения и конфигурации](#шаг-2-настройка-окружения-и-конфигурации)
   - [2.1 Установка необходимых инструментов](#21-установка-необходимых-инструментов)
   - [2.2 Создание файлов окружения](#22-создание-файлов-окружения)
   - [2.3 Настройка файлов сервисов](#23-настройка-файлов-сервисов)
6. [Шаг 3: Установка и запуск сервисов](#шаг-3-установка-и-запуск-сервисов)
   - [3.1 Клонирование репозитория](#31-клонирование-репозитория)
   - [3.2 Создание Docker-сетей](#32-создание-docker-сетей)
   - [3.3 Запуск MongoDB](#33-запуск-mongodb)
   - [3.4 Настройка базы данных MongoDB](#34-настройка-базы-данных-mongodb)
   - [3.5 Запуск unic.chat.solid](#35-запуск-unicchatsolid)
   - [3.6 Запуск сервера UnicChat](#36-запуск-сервера-unicchat)
   - [3.7 Настройка NGINX для UnicChat](#37-настройка-nginx-для-unicchat)
   - [3.8 Настройка HTTPS](#38-настройка-https)
   - [3.9 Настройка видеоконференций (VCS)](#39-настройка-видеоконференций-vcs)
   - [3.10 Настройка базы знаний](#310-настройка-базы-знаний)
7. [Шаг 4: Создание администратора](#шаг-4-создание-администратора)
8. [Шаг 5: Открытие сетевых портов](#шаг-5-открытие-сетевых-портов)
9. [Быстрый старт: Один сервер](#быстрый-старт-один-сервер)
10. [Быстрый старт: Два сервера](#быстрый-старт-два-сервера)
11. [Устранение неполадок](#устранение-неполадок)
12. [Клиентские приложения](#клиентские-приложения)
13. [Дополнительные ресурсы](#дополнительные-ресурсы)

## Обзор
- **UnicChat**: Безопасная платформа для обмена сообщениями с мобильными и настольными приложениями.
- **VCS**: Видео- и аудиоконференции с использованием LiveKit.
- **База знаний**: Хранилище файлов (MinIO) и редактирование документов (OnlyOffice).
- **Архитектура**:
  - Для установки на одном сервере см. схему: `assets/1vm-unicchat-install-scheme.jpg`
  - Для установки на двух серверах см. схему: `assets/2vm-unicchat-install-scheme.jpg`

## Предварительные требования
- Сервер с Ubuntu 20+ и доступом в интернет.
- Доступ с правами root или sudo.
- Лицензионный ключ от support@unicomm.pro.
- Базовые знания команд терминала.

## Структура директорий
Ниже представлена структура директорий проекта `unicchat.enterprise/`:

unicchat.enterprise/ ├── README.md ├── env_files/ │ ├── appserver.env │ ├── common.env │ ├── minio.env │ ├── mongodb.env │ ├── onlyoffice.env │ ├── solid.env │ ├── vcs.env ├── knowledgebase/ │ ├── Docker-DocumentServer/ │ │ ├── docker-compose.yml │ ├── minio/ │ │ ├── docker-compose.yml ├── multi_server_install/ │ ├── mongodb.yml │ ├── unic.chat.appserver.yml │ ├── unic.chat.solid.yml ├── vcs.unic.chat.template/ │ ├── .env │ ├── example.sites.nginx.md │ ├── install_docker.sh │ ├── install_server.sh │ ├── readme.first.md │ ├── update_ip.sh │ ├── unicomm-vcs/ │ │ ├── caddy.yaml │ │ ├── docker-compose.yaml │ │ ├── egress.yaml │ │ ├── redis.conf │ │ ├── update_ip.sh │ │ ├── vcs.yaml

## Шаг 1: Регистрация DNS-имен
Настройте DNS-имена для всех сервисов, чтобы они были доступны. Обратитесь к администратору DNS для публичной регистрации или отредактируйте `/etc/hosts` для локального тестирования:
```shell
10.0.XX.XX myapp.unic.chat
10.0.XX.XX mysolid.unic.chat
10.0.XX.XX myminio.unic.chat
10.0.XX.XX myonlyoffice.unic.chat
10.0.XX.XX mylk-yc.unic.chat
10.0.XX.XX turn.mylk-yc.unic.chat
10.0.XX.XX whip.mylk-yc.unic.chat

Замените 10.0.XX.XX на IP-адрес вашего сервера.
Шаг 2: Настройка окружения и конфигурации
2.1 Установка необходимых инструментов
Установите Docker, NGINX и Certbot:
sudo apt update
sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx
sudo systemctl start docker nginx
sudo systemctl enable docker nginx

Опционально: Используйте скрипт vcs.unic.chat.template/install_docker.sh для установки Docker:
chmod +x vcs.unic.chat.template/install_docker.sh
sudo ./vcs.unic.chat.template/install_docker.sh

Войдите в Yandex Container Registry:
sudo docker login --username oauth --password y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ cr.yandex

2.2 Создание файлов окружения
Создайте директорию env_files/ в корне проекта и добавьте следующие файлы с указанным содержимым. Замените заполнители (<your_server_ip>, <your_root_password>, <YourLicenseCodeHere>) на ваши значения.

env_files/mongodb.env:

MONGODB_VERSION=4.4
MONGODB_REPLICA_SET_MODE=primary
MONGODB_REPLICA_SET_NAME=rs0
MONGODB_REPLICA_SET_KEY=rs0key
MONGODB_PORT_NUMBER=27017
MONGODB_INITIAL_PRIMARY_HOST=<your_server_ip>
MONGODB_INITIAL_PRIMARY_PORT_NUMBER=27017
MONGODB_ADVERTISED_HOSTNAME=<your_server_ip>
MONGODB_ENABLE_JOURNAL=true
MONGODB_ROOT_PASSWORD=<your_root_password>
MONGODB_USERNAME=unicchat_admin
MONGODB_PASSWORD=secure_password_123
MONGODB_DATABASE=unicchat_db


env_files/appserver.env:

APPSERVER_IMAGE_VERSION=prod.6-2.1.69
MONGO_URL=mongodb://unicchat_admin:secure_password_123@<your_server_ip>:27017/unicchat_db?replicaSet=rs0
MONGO_OPLOG_URL=mongodb://unicchat_admin:secure_password_123@<your_server_ip>:27017/local
ROOT_URL=http://localhost:3000
UNIC_SOLID_HOST=http://mysolid.unic.chat:8881
PORT=3000
DEPLOY_METHOD=docker
ONLYOFFICE_HOST=https://myonlyoffice.unic.chat
LIVEKIT_HOST=wss://mylk-yc.unic.chat


env_files/solid.env:

SOLID_IMAGE_VERSION=prod250421
UnInit.0="'Mongo': { 'Type': 'DbConStringEntry', 'ConnectionString': 'mongodb://unicchat_admin:secure_password_123@<your_server_ip>:27017/unicchat_db?replicaSet=rs0', 'DataBase': 'unicchat_db' }"
UnInit.1="'Minio': { 'Type': 'NamedServiceAuth', 'IpOrHost': 'myminio.unic.chat', 'UserName': 'minioadmin', 'Password': 'rootpassword' }"


env_files/minio.env:

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=rootpassword
MINIO_IP_OR_HOST=myminio.unic.chat


env_files/onlyoffice.env:

DB_TYPE=postgres
DB_HOST=onlyoffice-postgresql
DB_PORT=5432
DB_NAME=dbname
DB_USER=dbuser
WOPI_ENABLED=true
AMQP_URI=amqp://guest:guest@onlyoffice-rabbitmq
JWT_ENABLED=false
ALLOW_PRIVATE_IP_ADDRESS=true
ALLOW_META_IP_ADDRESS=true
USE_UNAUTHORIZED_STORAGE=true
POSTGRES_DB=dbname
POSTGRES_USER=dbuser
POSTGRES_HOST_AUTH_METHOD=trust


env_files/vcs.env:

VCS_URL=mylk-yc.unic.chat
VCS_TURN_URL=turn.mylk-yc.unic.chat
VCS_WHIP_URL=whip.mylk-yc.unic.chat


env_files/common.env:

InitConfig:Names={Mongo Minio}
Plugins:Attach=KnowledgeBase Minio UniAct Mongo Logger UniVault Tasker
UnicLicense=<YourLicenseCodeHere>

2.3 Настройка файлов сервисов
Конфигурационные файлы (YAML) уже настроены в директориях multi_server_install/ и knowledgebase/ для использования файлов из env_files/. Изменения не требуются, если вы не хотите настроить порты или пути вручную.
Шаг 3: Установка и запуск сервисов
3.1 Клонирование репозитория
Скачайте код UnicChat Enterprise:
git clone https://github.com/unicommorg/unicchat.enterprise.git
cd unicchat.enterprise

3.2 Создание Docker-сетей
Настройте сети для взаимодействия между сервисами:
docker network create unicchat-backend
docker network create unicchat-frontend

3.3 Запуск MongoDB
Проверьте поддержку AVX на вашем сервере для MongoDB:
grep avx /proc/cpuinfo

Если вывода нет, оставьте MONGODB_VERSION=4.4 в mongodb.env. Запустите MongoDB:
docker-compose -f multi_server_install/mongodb.yml up -d

3.4 Настройка базы данных MongoDB
Подключитесь к MongoDB:
docker exec -it unic.chat.db.mongo /bin/bash
mongosh -u root -p "<your_root_password>"

Выполните следующие команды для настройки базы данных:
use unicchat_db
db.updateUser("unicchat_admin", {
  roles: [
    {role: "readWrite", db: "local"},
    {role: "readWrite", db: "unicchat_db"},
    {role: "dbAdmin", db: "unicchat_db"},
    {role: "clusterMonitor", db: "admin"}
  ]
})
show users

3.5 Запуск unic.chat.solid
Запустите сервис solid:
docker-compose -f multi_server_install/unic.chat.solid.yml up -d

3.6 Запуск сервера UnicChat
Запустите основной сервер UnicChat:
docker-compose -f multi_server_install/unic.chat.appserver.yml up -d

Проверьте, работает ли он:
curl -I http://myapp.unic.chat:8080

3.7 Настройка NGINX для UnicChat
Создайте файл /etc/nginx/sites-available/myapp.unic.chat:
upstream internal {
    server 127.0.0.1:8080;
}
server {
    server_name myapp.unic.chat;
    client_max_body_size 200M;
    error_log /var/log/nginx/myapp.unicchat.error.log;
    access_log /var/log/nginx/myapp.unicchat.access.log;
    add_header Access-Control-Allow-Origin $cors_origin_header always;
    add_header Access-Control-Allow-Credentials $cors_cred;
    add_header "Access-Control-Allow-Methods" "GET, POST, OPTIONS, HEAD";
    add_header "Access-Control-Allow-Headers" "Authorization, Origin, X-Requested-With, Content-Type, Accept";
    if ($request_method = 'OPTIONS') {
      return 204 no-content;
    }
    location / {
        proxy_pass http://internal;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Nginx-Proxy true;
        proxy_redirect off;
    }
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/myapp.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.unic.chat/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
server {
    server_name myapp.unic.chat;
    listen 80;
    return 301 https://$host$request_uri;
}

Активируйте его:
sudo ln -s /etc/nginx/sites-available/myapp.unic.chat /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

3.8 Настройка HTTPS
Получите SSL-сертификаты:
sudo certbot certonly --standalone -d myapp.unic.chat

Настройте автоматическое обновление сертификатов:
echo "00 7 * * * certbot renew --post-hook 'systemctl reload nginx'" | sudo tee /etc/cron.daily/certbot

Обновите MongoDB для использования HTTPS:
docker exec -it unic.chat.db.mongo mongosh -u root -p "<your_root_password>"
use unicchat_db
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":"https://myapp.unic.chat"}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":"https://myapp.unic.chat"}})

Протестируйте UnicChat по адресу https://myapp.unic.chat.
3.9 Настройка видеоконференций (VCS)
Перейдите в директорию VCS:
cd vcs.unic.chat.template

Запустите скрипт настройки:
chmod +x install_server.sh
sudo ./install_server.sh

Запустите VCS:
cd unicomm-vcs
docker-compose -f docker-compose.yaml up -d

Настройте NGINX (вместо Caddy):
upstream vcsserver {
    server 127.0.0.1:7880;
}
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name mylk-yc.unic.chat;
    ssl_certificate /etc/letsencrypt/live/mylk-yc.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mylk-yc.unic.chat/privkey.pem;
    ssl_session_timeout 1440m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    access_log /var/log/nginx/vcsserver.access.log;
    error_log /var/log/nginx/vcsserver.error.log;
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://vcsserver;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_read_timeout 90;
        proxy_redirect https://vcsserver http://mylk-yc.unic.chat;
    }
}
upstream turnserver {
    server 127.0.0.1:5349;
}
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name turn.mylk-yc.unic.chat;
    ssl_certificate /etc/letsencrypt/live/turn.mylk-yc.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/turn.mylk-yc.unic.chat/privkey.pem;
    ssl_session_timeout 1440m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    access_log /var/log/nginx/vcs-turnserver.access.log;
    error_log /var/log/nginx/vcs-turnserver.error.log;
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://turnserver;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_read_timeout 90;
        proxy_redirect https://turnserver http://turn.mylk-yc.unic.chat;
    }
}

Активируйте:
sudo ln -s /etc/nginx/sites-available/vcs.unic.chat /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

Проверьте порты VCS:
sudo lsof -i:7880 -i:7881 -i:5349 -i:3478

Протестируйте VCS по адресу: https://livekit.io/connection-test с токеном:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzUzNzgxOTEsImlzcyI6IkFQSUZCNnFMeEtKRFc3VCIsIm5hbWUiOiJUZXN0IFVzZXIiLCJuYmYiOjE3MzkzNzgxOTEsInN1YiI6InRlc3QtdXNlciIsInZpZGVvIjp7InJvb20iOiJteS1maXJzdC1yb29tIiwicm9vbUpvaW4iOnRydWV9fQ.20rviVegoNerAE_WiFxshYDpL2DVAHvnJzkjsV3L_0Y

3.10 Настройка базы знаний

MinIO (Хранилище файлов):
Запустите MinIO:



docker-compose -f knowledgebase/minio/docker-compose.yml up -d


Доступ по адресу http://myminio.unic.chat:9002 с учетными данными minioadmin и rootpassword.
Создайте бакет с именем uc.onlyoffice.docs и установите для него статус public.


OnlyOffice (Редактирование документов):
Запустите OnlyOffice:



docker-compose -f knowledgebase/Docker-DocumentServer/docker-compose.yml up -d


Доступ по адресу https://myonlyoffice.unic.chat.


Обновление сервисов:
Перезапустите unic.chat.solid:



docker-compose -f multi_server_install/unic.chat.solid.yml down
docker-compose -f multi_server_install/unic.chat.solid.yml up -d


Перезапустите сервер UnicChat:

docker-compose -f multi_server_install/unic.chat.appserver.yml down
docker-compose -f multi_server_install/unic.chat.appserver.yml up -d

Шаг 4: Создание администратора

Откройте https://myapp.unic.chat в браузере.
Зарегистрируйте администратора:
Имя: Ваше отображаемое имя.
Имя пользователя: Имя для входа.
Электронная почта: Для восстановления пароля.
Название организации: Название вашей компании (латинские буквы, без пробелов).
ID организации: Получите от support@unicomm.pro.
Пароль: Установите надежный пароль.


Перейдите в Администрирование → Push и включите https://push1.unic.chat.
Проверьте настройки в Администрирование → Организация.

Шаг 5: Открытие сетевых портов
Убедитесь, что следующие порты открыты:

UnicChat: 8080/TCP, 443/TCP, 8881/TCP, 4443/TCP.
VCS: 7880/TCP, 7881/TCP, 5349/TCP, 3478/UDP, 50000-60000/UDP.
MinIO: 9000/TCP, 9002/TCP.
OnlyOffice: 8880/TCP, 8443/TCP. წ

System: Разрешите исходящие соединения к:

push1.unic.chat:443
mylk-yc.unic.chat:443, 7881/TCP, 7882/UDP, 50000-60000/UDP

Быстрый старт: Один сервер
Запустите все сервисы на одном сервере:
cd unicchat.enterprise
docker network create unicchat-backend
docker network create unicchat-frontend
docker-compose -f multi_server_install/mongodb.yml up -d
docker-compose -f multi_server_install/unic.chat.solid.yml up -d
docker-compose -f multi_server_install/unic.chat.appserver.yml up -d
docker-compose -f knowledgebase/minio/docker-compose.yml up -d
docker-compose -f knowledgebase/Docker-DocumentServer/docker-compose.yml up -d
cd vcs.unic.chat.template
sudo ./install_server.sh
cd unicomm-vcs
docker-compose -f docker-compose.yaml up -d

Быстрый старт: Два сервера

Сервер базы данных:

docker network create unicchat-backend
docker network create unicchat-frontend
docker-compose -f multi_server_install/mongodb.yml up -d


Сервер приложений:

docker network create unicchat-backend
docker network create unicchat-frontend
docker-compose -f multi_server_install/unic.chat.solid.yml up -d
docker-compose -f multi_server_install/unic.chat.appserver.yml up -d
docker-compose -f knowledgebase/minio/docker-compose.yml up -d
docker-compose -f knowledgebase/Docker-DocumentServer/docker-compose.yml up -d
cd vcs.unic.chat.template
sudo ./install_server.sh
cd unicomm-vcs
docker-compose -f docker-compose.yaml up -d

Устранение неполадок

MongoDB не запускается: Проверьте поддержку AVX (grep avx /proc/cpuinfo). Используйте MONGODB_VERSION=4.4, если не поддерживается.
Ошибки NGINX: Проверьте конфигурацию (sudo nginx -t) и логи (/var/log/nginx/).
VCS не работает: Проверьте порты (sudo lsof -i:7880 -i:7881 -i:5349 -i:3478) и сертификаты.
MinIO/OnlyOffice недоступны: Убедитесь, что DNS-имена (myminio.unic.chat, myonlyoffice.unic.chat) настроены в /etc/hosts или DNS.

Клиентские приложения

Android: https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat
iOS: https://apps.apple.com/ru/app/unicchat/id1665533885
Desktop: https://github.com/unicommorg/unic.chat.desktop.releases/releases

Дополнительные ресурсы
Инструкции для UnicChat находятся в репозитории docs:

Инструкция пользователя UnicChat.pdf
Инструкция по администрированию UnicChat.pdf
Инструкция по лицензированию UnicChat.pdf
Описание архитектуры UnicChat.pdf


