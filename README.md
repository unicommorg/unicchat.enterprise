# Руководство по установке UnicChat Enterprise

Это руководство описывает, как настроить UnicChat Enterprise, включая приложение для чата, видеоконференции (VCS) и базу знаний (MinIO и OnlyOffice). Следуйте этим шагам, чтобы запустить все на сервере с Ubuntu 20+.

## Обзор
- **UnicChat**: Безопасная платформа для обмена сообщениями с мобильными и настольными приложениями.
- **VCS**: Видео- и аудиоконференции с использованием LiveKit.
- **База знаний**: Хранилище файлов (MinIO) и редактирование документов (OnlyOffice).
- **Архитектура**: Смотрите `assets/1vm-unicchat-install-scheme.jpg` для установки на одном сервере или `assets/2vm-unicchat-install-scheme.jpg` для установки на двух серверах.

## Предварительные требования
- Сервер с Ubuntu 20+ и доступом в интернет.
- Доступ с правами root или sudo.
- Лицензионный ключ от support@unicomm.pro.
- Базовые знания команд терминала.

## Шаг 1: Регистрация DNS-имен
Настройте DNS-имена для всех сервисов, чтобы они были доступны. Обратитесь к администратору DNS для публичной регистрации или отредактируйте `/etc/hosts` для локального тестирования:
```shell
10.0.XX.XX app.unic.chat www.app.unic.chat
10.0.XX.XX mysolid.unic.chat
10.0.XX.XX myminio.unic.chat
10.0.XX.XX myonlyoffice.unic.chat
10.0.XX.XX lk-yc.unic.chat
10.0.XX.XX turn.lk-yc.unic.chat
10.0.XX.XX whip.lk-yc.unic.chat

Замените 10.0.XX.XX на IP-адрес вашего сервера.
Шаг 2: Настройка окружения и конфигурации
2.1 Установка необходимых инструментов
Установите Docker, NGINX и Certbot:
sudo apt update
sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx
sudo systemctl start docker nginx
sudo systemctl enable docker nginx

Опционально: Используйте vcs.unic.chat.template/install_docker.sh для установки Docker:
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
LIVEKIT_HOST=wss://lk-yc.unic.chat


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

VCS_URL=lk-yc.unic.chat
VCS_TURN_URL=turn.lk-yc.unic.chat
VCS_WHIP_URL=whip.lk-yc.unic.chat


env_files/common.env:

InitConfig:Names={Mongo Minio}
Plugins:Attach=KnowledgeBase Minio UniAct Mongo Logger UniVault Tasker
UnicLicense=<YourLicenseCodeHere>

2.3 Настройка файлов сервисов
Конфигурационные файлы (YAML) уже настроены в репозитории для использования директории env_files/. Убедитесь, что они находятся в multi_server_install/ и knowledgebase/. Изменения не требуются, если вы не хотите настроить порты или пути.
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
curl -I http://app.unic.chat:8080

3.7 Настройка NGINX для UnicChat
Создайте файл /etc/nginx/sites-available/app.unic.chat:
upstream internal {
    server 127.0.0.1:8080;
}
server {
    server_name app.unic.chat www.app.unic.chat;
    client_max_body_size 200M;
    error_log /var/log/nginx/app.unicchat.error.log;
    access_log /var/log/nginx/app.unicchat.access.log;
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
    ssl_certificate /etc/letsencrypt/live/app.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.unic.chat/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
server {
    server_name app.unic.chat www.app.unic.chat;
    listen 80;
    return 301 https://$host$request_uri;
}

Активируйте его:
sudo ln -s /etc/nginx/sites-available/app.unic.chat /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

3.8 Настройка HTTPS
Получите SSL-сертификаты:
sudo certbot certonly --standalone -d app.unic.chat -d www.app.unic.chat

Настройте автоматическое обновление сертификатов:
echo "00 7 * * * certbot renew --post-hook 'systemctl reload nginx'" | sudo tee /etc/cron.daily/certbot

Обновите MongoDB для использования HTTPS:
docker exec -it unic.chat.db.mongo mongosh -u root -p "<your_root_password>"
use unicchat_db
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":"https://app.unic.chat"}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":"https://app.unic.chat"}})

Протестируйте UnicChat по адресу https://app.unic.chat.
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
    server_name lk-yc.unic.chat;
    ssl_certificate /etc/letsencrypt/live/lk-yc.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lk-yc.unic.chat/privkey.pem;
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
        proxy_redirect https://vcsserver http://lk-yc.unic.chat;
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
    server_name turn.lk-yc.unic.chat;
    ssl_certificate /etc/letsencrypt/live/turn.lk-yc.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/turn.lk-yc.unic.chat/privkey.pem;
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
        proxy_redirect https://turnserver http://turn.lk-yc.unic.chat;
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

Откройте https://app.unic.chat в браузере.
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
OnlyOffice: 8880/TCP, 8443/TCP.Разрешите исходящие соединения к:
push1.unic.chat:443
lk-yc.unic.chat:443, 7881/TCP, 7882/UDP, 50000-60000/UDP

Быстрый старт: Один сервер
Запустите все сервисы на одном сервере:
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
MinIO/OnlyOffice недоступны: Убедитесь, что DNS-имена (myminio.unic.chat, myonlyoffice.unic.chat) настроены.

Клиентские приложения

Android: https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat
iOS: https://apps.apple.com/ru/app/unicchat/id1665533885
Desktop: https://github.com/unicommorg/unic.chat.desktop.releases/releases

Дополнительные ресурсы
Смотрите docs/ для подробных руководств:

Руководство пользователя
Руководство администратора
Руководство по лицензированию
Описание архитектуры


