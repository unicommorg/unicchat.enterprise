<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Инструкция по установке корпоративного мессенджера UnicChat](#-unicchat)
   * [Оглавление](#)
   * [Скачать инструкции в PDF](#-pdf)
   * [Архитектура установки](#-)
      + [Установка на 1-м сервере](#-1-)
      + [Установка на 2-х серверах (рекомендуется для промышленного использования)](#-2-)
   * [Обязательные компоненты](#--1)
      - [Push-шлюз](#push-)
      - [ВКС-шлюз](#--2)
      - [Приложения UnicChat](#-unicchat-1)
   * [Опциональные компоненты](#--3)
      - [SMTP-сервер](#smtp-)
      - [LDAP-сервер](#ldap-)
   * [Шаг 1. Подготовка окружения](#-1--1)
      + [1.1 Требования к конфигурации](#11-)
         - [Для 20 пользователей (1 сервер)](#-20-1-)
         - [Для 20–50 пользователей (2 сервера)](#-20-50-)
      + [1.2 Запрос лицензии для UnicChat Solid Core](#12-unicchat-solid-core)
      + [1.3 Установка сторонних зависимостей](#13-)
      + [1.4 Клонирование репозитория](#14-)
   * [Шаг 2. Установка UnicChat](#-2-unicchat)
      + [2.1 Настройка MongoDB](#21-mongodb)
      + [2.2 Создание базы данных и пользователя](#22-)
      + [2.3 Настройка unic.chat.solid](#23-unicchatsolidcore)
      + [2.4 Запуск сервера UnicChat](#24-unicchat)
   * [Шаг 3. Настройка NGINX](#-3-nginx)
      + [3.1 Регистрация DNS-записей](#31-dns-)
      + [3.2 Настройка NGINX](#32-nginx)
         - [3.2.1 Установка NGINX](#321-nginx)
         - [3.2.2 Настройка сайта для UnicChat](#322-unicchat)
         - [3.2.3 Подготовка сайта NGINX](#323-nginx)
         - [3.2.4 Проверка работы](#324-)
         - [3.2.5 Установка Certbot и получение сертификатов](#325-certbot-)
         - [3.2.6 Настройка автоматического обновления сертификатов](#326-certbot)
         - [3.2.7 Настройка UnicChat для HTTPS](#327-unicchat-https)
      + [3.3 Открытие сетевых портов](#33-)
         - [Входящие соединения](#-unicchat-2)
         - [Исходящие соединения](#-unicchat-3)
   * [Шаг 4. Создание администратора](#-4-)
   * [Шаг 5. Настройка push-уведомлений](#-5-push-)
   * [Шаг 6. Настройка SMTP-сервера](#-6-smtp-)
   * [Шаг 7. Настройка LDAP-сервера](#-7-ldap-)
   * [Шаг 8. Установка локального медиа-сервера для ВКС](#-8-)
      + [8.1 Порядок установки](#--9)
      + [8.2 Проверка портов](#--10)
   * [Шаг 9. Развертывание базы знаний](#9-unicchat)
      + [9.1 Подготовка сервера](#91-)
      + [9.2 Настройка NGINX](#92-nginx)
      + [9.3 Размещение в локальной сети](#93-)
      + [9.4 Развертывание MinIO S3](#94-minio-s3)
         - [9.4.1 Настройка MinIO](#941-knowledgebaseminio)
         - [9.4.2 Запуск MinIO](#942-minio)
         - [9.4.3 Доступ к MinIO](#943-minio)
         - [9.4.4 Создание бакета](#944-bucket)
      + [9.5 Развертывание OnlyOffice](#95-onlyoffice)
         - [9.5.1 Запуск OnlyOffice](#951-onlyoffice)
         - [9.5.2 Доступ к OnlyOffice](#952-onlyoffice)
      + [9.6 Обновление unic.chat.solid](#96-unicchatsolid)
         - [9.6.1 Редактирование env-файла](#961-env-)
         - [9.6.2 Перезапуск unic.chat.solid](#962-unicchatsolid)
      + [9.7 Обновление unic.chat.appserver](#97-unicchatappserver)
         - [9.7.1 Добавление ONLYOFFICE_HOST](#971-onlyoffice_host)
         - [9.7.2 Перезапуск unic.chat.appserver](#972-unicchatappserver)
   * [Частые проблемы при установке](#--11)
   * [Клиентские приложения](#--12)

<!-- TOC end -->

<!-- TOC --><a name="-unicchat"></a>
## Инструкция по установке корпоративного мессенджера UnicChat

Версия документа: 1.7

<!-- TOC --><a name=""></a>
### Оглавление

<!-- TOC --><a name="-pdf"></a>
### Скачать инструкции в PDF

Инструкции находятся в репозитории [docs](https://github.com/unicommorg/unicchat.enterprise/tree/main/docs):

* [Инструкция пользователя UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F%20%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D0%B5%D0%BB%D1%8F%20UnicChat.pdf)
* [Инструкция по администрированию UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%B8%D1%81%D1%82%D1%80%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Инструкция по лицензированию UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Описание архитектуры UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%9E%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B0%D1%80%D1%85%D0%B8%D1%82%D0%B5%D0%BA%D1%82%D1%83%D1%80%D1%8B%20UnicChat.pdf)

<!-- TOC --><a name="-"></a>
### Архитектура установки

<!-- TOC --><a name="-1-"></a>
#### Установка на 1-м сервере

![Архитектура установки на 1-м сервере](./assets/1vm-unicchat-install-scheme.jpg)

<!-- TOC --><a name="-2-"></a>
#### Установка на 2-х серверах (рекомендуется для промышленного использования)

![Архитектура установки на 2-х серверах](./assets/2vm-unicchat-install-scheme.jpg)

<!-- TOC --><a name="--1"></a>
### Обязательные компоненты

<!-- TOC --><a name="push-"></a>
#### Push-шлюз

Публичный сервис Unicomm для отправки push-уведомлений на мобильные платформы (Apple, Google). Требуются только исходящие соединения к `push1.unic.chat:443`.

<!-- TOC --><a name="--2"></a>
#### ВКС-шлюз

Публичный сервис Unicomm для аудио- и видеоконференций. Требуются исходящие соединения к `mylk-yc.unic.chat:443`, `7881/TCP`, `7882/UDP`, и `50000–60000/UDP` (диапазон портов RTP может быть изменён).

<!-- TOC --><a name="-unicchat-1"></a>
#### Приложения UnicChat

Клиентские приложения для iOS, Android и десктоп. Сервер UnicChat принимает входящие HTTPS-соединения (443/TCP) и использует STUN/TURN (7881/TCP, 7882/UDP, 50000–60000/UDP) для видеозвонков.

<!-- TOC --><a name="--3"></a>
### Опциональные компоненты

<!-- TOC --><a name="smtp-"></a>
#### SMTP-сервер

Используется для отправки OTP, уведомлений и восстановления паролей. Может быть публичным или вашим собственным (в DMZ). Интеграция необязательна.

<!-- TOC --><a name="ldap-"></a>
#### LDAP-сервер

Используется для синхронизации пользователей. Поддерживает как LDAP, так и внутреннюю базу UnicChat. Интеграция необязательна.

<!-- TOC --><a name="-1--1"></a>
### Шаг 1. Подготовка окружения

<!-- TOC --><a name="11-"></a>
#### 1.1 Требования к конфигурации

<!-- TOC --><a name="-20-1-"></a>
##### Для 20 пользователей (1 сервер)

- **CPU**: 4 ядра, 1.7 ГГц (FMA3, SSE4.2, AVX 2.0)
- **RAM**: 8 ГБ
- **Диск**: 150 ГБ (HDD/SSD)
- **ОС**: Ubuntu 20+

<!-- TOC --><a name="-20-50-"></a>
##### Для 20–50 пользователей (2 сервера)

**Сервер приложений**:
- **CPU**: 4 ядра, 1.7 ГГц (FMA3, SSE4.2)
- **RAM**: 8 ГБ
- **Диск**: 200 ГБ (HDD/SSD)

**Сервер базы данных**:
- **CPU**: 4 ядра, 1.7 ГГц (FMA3, SSE4.2, AVX 2.0)
- **RAM**: 8 ГБ
- **Диск**: 100 ГБ (HDD/SSD)

<!-- TOC --><a name="12-unicchat-solid-core"></a>
#### 1.2 Запрос лицензии для UnicChat Solid Core

Свяжитесь с Unicomm по адресу `support@unicomm.pro` для получения лицензионного ключа.

<!-- TOC --><a name="13-"></a>
#### 1.3 Установка сторонних зависимостей

Установите необходимые пакеты на Ubuntu 20+:

```bash
sudo apt update
sudo apt install -y docker.io docker compose nginx certbot python3-certbot-nginx git
sudo systemctl enable docker nginx
sudo systemctl start docker nginx

Авторизуйтесь в Yandex Container Registry:
sudo docker login --username oauth --password y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ cr.yandex

Опционально: Для установки Docker используйте скрипт:
chmod +x vcs.unic.chat.template/install_docker.sh
sudo vcs.unic.chat.template/install_docker.sh


1.4 Клонирование репозитория
Склонируйте репозиторий и проверьте наличие файлов:
git clone https://github.com/unicommorg/unicchat.enterprise.git
cd unicchat.enterprise
ls multi_server_install/*.yml

Ожидаемые файлы:

mongodb.yml
unic.chat.solid.yml
unic.chat.appserver.yml


Шаг 2. Установка UnicChat

2.1 Настройка MongoDB

Проверьте поддержку AVX:

grep avx /proc/cpuinfo

Если AVX отсутствует, используйте MongoDB 4.4 в env_files/mongodb.env:
MONGODB_VERSION=4.4
MONGODB_REPLICA_SET_MODE=primary
MONGODB_REPLICA_SET_NAME=rs0
MONGODB_REPLICA_SET_KEY=rs0key
MONGODB_PORT_NUMBER=27017
MONGODB_INITIAL_PRIMARY_HOST=<your_server_ip>
MONGODB_ADVERTISED_HOSTNAME=<your_server_ip>
MONGODB_ENABLE_JOURNAL=true
MONGODB_ROOT_PASSWORD=<your_root_password>
MONGODB_USERNAME=unicchat_admin
MONGODB_PASSWORD=secure_password_123
MONGODB_DATABASE=unicchat_db


Создайте Docker-сети:

docker network create unicchat-backend
docker network create unicchat-frontend


Запустите MongoDB:

docker compose -f multi_server_install/mongodb.yml up -d


2.2 Создание базы данных и пользователя

Подключитесь к контейнеру MongoDB:

docker exec -it unic.chat.db.mongo /bin/bash
mongosh -u root -p "<your_root_password>"


Создайте базу и пользователя:

use unicchat_db
db.updateUser("unicchat_admin", {
  roles: [
    { role: "readWrite", db: "local" },
    { role: "readWrite", db: "unicchat_db" },
    { role: "dbAdmin", db: "unicchat_db" },
    { role: "clusterMonitor", db: "admin" }
  ]
})
show users


2.3 Настройка unic.chat.solid

Отредактируйте env_files/solid.env:

SOLID_IMAGE_VERSION=prod250421
UnInit.0="'Mongo': { 'Type': 'DbConStringEntry', 'ConnectionString': 'mongodb://unicchat_admin:secure_password_123@<your_server_ip>:27017/unicchat_db?replicaSet=rs0', 'DataBase': 'unicchat_db' }"
UnInit.1="'Minio': { 'Type': 'NamedServiceAuth', 'IpOrHost': 'myminio.unic.chat', 'UserName': 'minioadmin', 'Password': 'rootpassword' }"


Запустите сервис:

docker compose -f multi_server_install/unic.chat.solid.yml up -d
docker compose -f multi_server_install/unic.chat.solid.yml logs -f


2.4 Запуск сервера UnicChat

Отредактируйте env_files/appserver.env:

APPSERVER_IMAGE_VERSION=prod.6-2.1.69
MONGO_URL=mongodb://unicchat_admin:secure_password_123@<your_server_ip>:27017/unicchat_db?replicaSet=rs0
MONGO_OPLOG_URL=mongodb://unicchat_admin:secure_password_123@<your_server_ip>:27017/local
ROOT_URL=http://localhost:3000
UNIC_SOLID_HOST=http://mysolid.unic.chat:8881
PORT=3000
DEPLOY_METHOD=docker
ONLYOFFICE_HOST=https://myonlyoffice.unic.chat
LIVEKIT_HOST=wss://mylk-yc.unic.chat


Запустите сервер:

docker compose -f multi_server_install/unic.chat.appserver.yml up -d


Проверьте доступ:

curl -I http://myapp.unic.chat:8080
docker compose -f multi_server_install/unic.chat.appserver.yml logs -f


Шаг 3. Настройка NGINX

3.1 Регистрация DNS-записей
Настройте DNS или отредактируйте /etc/hosts для локального тестирования:
10.0.XX.XX myapp.unic.chat
10.0.XX.XX mysolid.unic.chat
10.0.XX.XX myminio.unic.chat
10.0.XX.XX myonlyoffice.unic.chat
10.0.XX.XX mylk-yc.unic.chat
10.0.XX.XX turn.mylk-yc.unic.chat
10.0.XX.XX whip.mylk-yc.unic.chat

Замените 10.0.XX.XX на IP-адрес вашего сервера.

3.2 Настройка NGINX

3.2.1 Установка NGINX
Установите NGINX, если он ещё не установлен:
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx


3.2.2 Настройка сайта для UnicChat
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


3.2.3 Подготовка сайта NGINX

Активируйте конфигурацию:

sudo ln -s /etc/nginx/sites-available/myapp.unic.chat /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default


Проверьте конфигурацию:

sudo nginx -t


Перезапустите NGINX:

sudo systemctl restart nginx


3.2.4 Проверка работы
Проверьте доступ к сайту:
curl -I http://myapp.unic.chat

Если сайт не открывается, очистите кэш браузера (Ctrl+R) или используйте режим инкогнито.

3.2.5 Установка Certbot и получение сертификатов

Установите Certbot:

sudo apt install -y certbot python3-certbot-nginx


Получите сертификаты:

sudo certbot certonly --standalone -d myapp.unic.chat


3.2.6 Настройка автоматического обновления сертификатов
Настройте ежедневное обновление сертификатов:
echo "00 7 * * * certbot renew --post-hook 'systemctl reload nginx'" | sudo tee /etc/cron.daily/certbot


3.2.7 Настройка UnicChat для HTTPS
Обновите настройки в MongoDB:
docker exec -it unic.chat.db.mongo mongosh -u root -p "<your_root_password>"
use unicchat_db
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":"https://myapp.unic.chat"}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":"https://myapp.unic.chat"}})

Проверьте доступ: https://myapp.unic.chat

3.3 Открытие сетевых портов

Входящие соединения

UnicChat: 8080/TCP, 443/TCP
unic.chat.solid: 8881/TCP
MinIO: 9000/TCP, 9002/TCP
OnlyOffice: 8880/TCP
VCS: 7880/TCP, 7881/TCP, 5349/TCP, 3478/UDP, 50000–60000/UDP


Исходящие соединения

Push-шлюз: push1.unic.chat:443
ВКС-шлюз: mylk-yc.unic.chat:443, 7881/TCP, 7882/UDP, 50000–60000/UDP
Дополнительно: SMTP, LDAP, DNS (если используются)


Шаг 4. Создание администратора

Откройте https://myapp.unic.chat и зарегистрируйте администратора:
Имя: Отображаемое имя
Имя пользователя: Логин
Электронная почта: Для восстановления пароля
Название организации: Латинские буквы, без пробелов
ID организации: Запросите у support@unicomm.pro
Пароль: Надёжный пароль


Войдите в веб-интерфейс.
В Администрирование → Push включите шлюз https://push1.unic.chat.
Проверьте настройки в Администрирование → Организация.
При первом входе нажмите «ДА» на предупреждении.


Шаг 5. Настройка push-уведомлений
UnicChat использует внешний push-сервер для доставки уведомлений на мобильные устройства. Настройка выполнена в шаге 4.

Шаг 6. Настройка SMTP-сервера
Для настройки SMTP-сервера обратитесь к документации в docs/ или свяжитесь с support@unicomm.pro.

Шаг 7. Настройка LDAP-сервера
Для настройки LDAP-сервера обратитесь к документации в docs/ или свяжитесь с support@unicomm.pro.

Шаг 8. Установка локального медиа-сервера для ВКС

8.1 Порядок установки

Перейдите в директорию:

cd vcs.unic.chat.template


Отредактируйте .env:

VCS_URL=mylk-yc.unic.chat
VCS_TURN_URL=turn.mylk-yc.unic.chat
VCS_WHIP_URL=whip.mylk-yc.unic.chat


Запустите установку:

chmod +x install_server.sh
sudo ./install_server.sh


Запустите медиа-сервер:

cd unicomm-vcs
docker compose -f docker compose.yaml up -d


Настройте NGINX (вместо Caddy, см. example.sites.nginx.md):

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


Активируйте NGINX:

sudo ln -s /etc/nginx/sites-available/vcs.unic.chat /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx


Проверьте ВКС: https://livekit.io/connection-test с токеном:

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzUzNzgxOTEsImlzcyI6IkFQSUZCNnFMeEtKRFc3VCIsIm5hbWUiOiJUZXN0IFVzZXIiLCJuYmYiOjE3MzkzNzgxOTEsInN1YiI6InRlc3QtdXNlciIsInZpZGVvIjp7InJvb20iOiJteS1maXJzdC1yb29tIiwicm9vbUpvaW4iOnRydWV9fQ.20rviVegoNerAE_WiFxshYDpL2DVAHvnJzkjsV3L_0Y


8.2 Проверка портов
Проверьте открытые порты:
sudo lsof -i:7880 -i:7881 -i:5349 -i:3478

Пример вывода:
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
livekit-s 5780 root    8u  IPv6  69483      0t0  TCP *:7881 (LISTEN)
livekit-s 5780 root    9u  IPv4  69493      0t0  TCP *:5349 (LISTEN)
livekit-s 5780 root   10u  IPv4  69494      0t0  UDP *:3478
livekit-s 5780 root   11u  IPv6  70260      0t0  TCP *:7880 (LISTEN)


Шаг 9. Развертывание базы знаний

9.1 Подготовка сервера
Проверьте наличие директорий:

knowledgebase/minio
knowledgebase/Docker-DocumentServer


9.2 Настройка NGINX
Создайте конфигурации NGINX для:

mysolid.unic.chat:8881
myminio.unic.chat:9000 (API), 9002 (консоль)
myonlyoffice.unic.chat:8880
myapp.unic.chat:8080

См. примеры в knowledgebase/nginx/.

9.3 Размещение в локальной сети
Настройте /etc/hosts на сервере:
10.0.XX.XX myapp.unic.chat
10.0.XX.XX mysolid.unic.chat
10.0.XX.XX myminio.unic.chat
10.0.XX.XX myonlyoffice.unic.chat
10.0.XX.XX mylk-yc.unic.chat
10.0.XX.XX turn.mylk-yc.unic.chat
10.0.XX.XX whip.mylk-yc.unic.chat


9.4 Развертывание MinIO S3

9.4.1 Настройка MinIO
В knowledgebase/minio/docker compose.yml установите:
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=rootpassword
MINIO_IP_OR_HOST=myminio.unic.chat


9.4.2 Запуск MinIO
cd knowledgebase/minio
docker compose up -d


9.4.3 Доступ к MinIO

Консоль: http://myminio.unic.chat:9002
Логин: minioadmin
Пароль: rootpassword
S3 Endpoint: http://myminio.unic.chat:9000


9.4.4 Создание бакета
Создайте бакет uc.onlyoffice.docs с политикой доступа public.

9.5 Развертывание OnlyOffice

9.5.1 Запуск OnlyOffice
cd knowledgebase/Docker-DocumentServer
docker compose up -d


9.5.2 Доступ к OnlyOffice

Адрес: https://myonlyoffice.unic.chat


9.6 Обновление unic.chat.solid

9.6.1 Редактирование env-файла
Обновите env_files/solid.env (см. шаг 2.3).

9.6.2 Перезапуск unic.chat.solid
docker compose -f multi_server_install/unic.chat.solid.yml down
docker compose -f multi_server_install/unic.chat.solid.yml up -d

Проверьте: http://mysolid.unic.chat:8881/swagger/index.html

9.7 Обновление unic.chat.appserver

9.7.1 Добавление ONLYOFFICE_HOST
Обновите env_files/appserver.env (см. шаг 2.4).

9.7.2 Перезапуск unic.chat.appserver
docker compose -f multi_server_install/unic.chat.appserver.yml down
docker compose -f multi_server_install/unic.chat.appserver.yml up -d


Частые проблемы при установке

MongoDB не запускается: Проверьте AVX (grep avx /proc/cpuinfo). Используйте MONGODB_VERSION=4.4 при отсутствии AVX.
NGINX ошибки: Проверьте конфигурацию (sudo nginx -t) и логи (/var/log/nginx/).
VCS не работает: Убедитесь, что порты открыты (sudo lsof -i:7880 -i:7881 -i:5349 -i:3478) и сертификаты настроены.
MinIO/OnlyOffice недоступны: Проверьте DNS в /etc/hosts или публичные записи.


Клиентские приложения

Android: https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat
iOS: https://apps.apple.com/ru/app/unicchat/id1665533885
Desktop: https://github.com/unicommorg/unic.chat.desktop.releases/releases


