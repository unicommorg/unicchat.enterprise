<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat](#-unicchat)
   * [Оглавление](#)
   * [Скачать инструкции в PDF](#-pdf)
   * [Архитектура установки](#-)
      + [Установка на 1-м сервере](#-1-)
      + [Установка на 2-х серверах (рекомендуется для промышленного использования)](#-2-)
   * [Обязательные компоненты](#--1)
      - [Push шлюз](#push-)
      - [ВКС шлюз](#--2)
      - [Приложения UnicChat](#-unicchat-1)
   * [Опциональные компоненты](#--3)
      - [SMTP сервер](#smtp-)
      - [LDAP сервер](#ldap-)
   * [Шаг 1. Подготовка окружения](#-1--1)
      + [1.1 Требования к конфигурации](#11-)
         - [Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине](#-20-1-)
         - [Конфигурация виртуальной машины](#--4)
         - [Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины](#-20-50-)
         - [Конфигурация виртуальной машины для приложения](#--5)
         - [Конфигурация виртуальной машины для БД](#--6)
      + [1.2. Запрос лицензии для Unicchat Solid Core](#12-unicchat-solid-core)
      + [1.3. Установка сторонних зависимостей](#13-)
      + [1.4. Клонирование репозитория](#14-)
   * [Шаг 2. Настройка NGINX](#-2-nginx)
      + [2.1 Зарегистрировать DNS запись](#21-dns-)
      + [2.2 Провести настройку Nginx](#22-nginx)
         - [2.2.1 Установить nginx](#221-nginx)
         - [2.2.2 Настроить сайт для Unicchat](#222-unicchat)
         - [2.2.3 Подготовка сайта nginx](#223-nginx)
         - [2.2.4 Проверка работы](#224-)
         - [2.2.5 Установка certbot и получение сертификата](#225-certbot-)
         - [2.2.6 Настройка автоматической проверки сертификата certbot](#226-certbot)
         - [2.2.7 Настройка Unicchat для работы с HTTPS](#227-unicchat-https)
      + [2.3 Открыть доступы до внутренних ресурсов](#23-)
         - [Входящие соединения на стороне сервера UnicChat:](#-unicchat-2)
         - [Исходящие соединения на стороне сервера UnicChat:](#-unicchat-3)
   * [Шаг 3. Установка локального медиа сервера для ВКС](#-3-)
      + [3.1 Порядок установки сервера](#31-)
      + [3.2 Проверка открытия портов](#32-)
   * [Шаг 4. Развертывание базы знаний для UNICCHAT](#-4-unicchat)
      + [4.1 Подготовка сервера](#41-)
      + [4.2 Настройка nginx](#42-nginx)
      + [4.3 Размещение в локальной сети](#43-)
      + [4.4 Развертывание MinIO S3](#44-minio-s3)
         - [4.4.1 Перейдите в директорию knowledgebase/minio.](#441-knowledgebaseminio)
         - [4.4.2 Запустите MinIO:](#442-minio)
         - [4.4.3 Доступ к MinIO:](#443-minio)
         - [4.4.4 Создание bucket](#444-bucket)
      + [4.5 Развертывание OnlyOffice](#45-onlyoffice)
         - [4.5.1 Запуск OnlyOffice](#451-onlyoffice)
         - [4.5.2 Доступ к OnlyOffice:](#452-onlyoffice)
      + [4.6 Редактирование сервиса unic.chat.solid](#46-unicchatsolid)
         - [4.6.1 Редактирование env файла](#461-env-)
         - [4.6.2 Пересоздание сервиса unic.chat.solid](#462-unicchatsolid)
      + [4.7 Редактирование сервиса unic.chat.appserver](#47-unicchatappserver)
         - [4.7.1 Добавление переменной окружения ONLYOFFICE_HOST](#471-onlyoffice_host)
         - [4.7.2 Пересоздание сервиса unic.chat.appserver](#472-unicchatappserver)
      + [Частые проблемы при установке](#--11)
      + [Клиентские приложения](#--12)
      + [Частые проблемы при установке](#--13)
   * [Шаг 5. Установка UnicChat](#-5-unicchat)
      + [5.1 Настройка БД - mongodb](#51-mongodb)
      + [5.2 Создать базу и пользователя для подключения к базе](#52-)
      + [5.3 Настройка unicchat.solid.core](#53-unicchatsolidcore)
      + [5.4 Запуск сервера UnicChat](#54-unicchat)
   * [Шаг 6. Создание пользователя администратора](#-6-)
   * [Шаг 7. Настройка push-уведомлений](#-7-push-)
   * [Шаг 8. Настройка подключения к SMTP серверу для отправки уведомлений в почту](#-8-smtp-)
   * [Шаг 9. Настройка подключения к LDAP серверу](#-9-ldap-)
   * [Быстрый старт. Запуск на одном сервере](#--7)
   * [Быстрый старт. Запуск на двух серверах](#--8)

<!-- TOC end -->

<!-- TOC --><a name="-unicchat"></a>
## Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat

версия документа 1.7

<!-- TOC --><a name=""></a>
### Оглавление

<!-- TOC --><a name="-pdf"></a>
### Скачать инструкции в PDF 

Инструкции для unicchat лежат в репозитории [docs](https://github.com/unicommorg/unicchat.enterprise/tree/main/docs)

* [Инструкция пользователя UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F%20%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D0%B5%D0%BB%D1%8F%20UnicChat.pdf)
* [Инструкция_по_администрированию_UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D1%8F_%D0%BF%D0%BE_%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%B8%D1%81%D1%82%D1%80%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Инструкция_по_лицензированию_UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D1%8F_%D0%BF%D0%BE_%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Описание архитектуры UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%9E%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B0%D1%80%D1%85%D0%B8%D1%82%D0%B5%D0%BA%D1%82%D1%83%D1%80%D1%8B%20UnicChat.pdf)

<!-- TOC --><a name="-"></a>
### Архитектура установки

___

<!-- TOC --><a name="-1-"></a>
#### Установка на 1-м сервере

![](./assets/1vm-unicchat-install-scheme.jpg "Архитектура установки на 1-м сервере")

<!-- TOC --><a name="-2-"></a>
#### Установка на 2-х серверах (рекомендуется для промышленного использования)

![](./assets/2vm-unicchat-install-scheme.jpg "Архитектура установки на 2-х серверах")

<!-- TOC --><a name="--1"></a>
### Обязательные компоненты

___

<!-- TOC --><a name="push-"></a>
##### Push шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для отправки push-сообщений на мобильные платформы Apple и Google.
Расположен во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и не требуются входящие соединения.

<!-- TOC --><a name="--2"></a>
##### ВКС шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для работы аудио и видео конференций, а также аудио-звонков.
Расположены во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и не требуются входящие соединения.

<!-- TOC --><a name="-unicchat-1"></a>
##### Приложения UnicChat

Пользовательское приложение, установленное на iOS или Android платформе.
Сервер UnicChat должен иметь возможность принимать входящие сообщения от этих приложений, а также отправлять ответы.
Основное взаимодействие осуществляется через протокол HTTPS (443/TCP).
Для работы видео- и аудиозвонков необходимы протоколы STUN и TURN: входящие соединения на порты 7881/TCP и 7882/UDP, а также входящий и исходящий трафик UDP по портам 50000-60000 (RTP-трафик).

<!-- TOC --><a name="--3"></a>
### Опциональные компоненты

___

<!-- TOC --><a name="smtp-"></a>
##### SMTP сервер

Используется для отправки OTP-сообщений, восстановлений пароля, напоминания о пропущенных сообщениях, предоставляется вами.
Может быть использован как публичный, так и ваш собственный сервер. На схеме предполагается, что сервер находится в вашем сегменте DMZ.
**Интеграция с SMTP не является обязательным условием.**

<!-- TOC --><a name="ldap-"></a>
##### LDAP сервер

Используется для получения списка пользователей в системе. UnicChat может обслуживать как пользователей, заведенных в LDAP каталоге, так и внутренних пользователей в собственной базе. **Интеграция с LDAP не является обязательным условием**

<!-- TOC --><a name="-1--1"></a>
### Шаг 1. Подготовка окружения

<!-- TOC --><a name="11-"></a>
#### 1.1 Требования к конфигурации

<!-- TOC --><a name="-20-1-"></a>
##### Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине

<!-- TOC --><a name="--4"></a>
##### Конфигурация виртуальной машины

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2, AVX 2.0;
RAM 8 Gb;
150 Gb HDD\SSD;
```

<!-- TOC --><a name="-20-50-"></a>
##### Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины

<!-- TOC --><a name="--5"></a>
##### Конфигурация виртуальной машины для приложения

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2;
RAM 8 Gb;
200 Gb HDD\SSD
```

<!-- TOC --><a name="--6"></a>
##### Конфигурация виртуальной машины для БД

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2, AVX 2.0;
RAM 8 Gb;
100 Gb HDD\SSD
```

<!-- TOC --><a name="12-unicchat-solid-core"></a>
#### 1.2. Запрос лицензии для Unicchat Solid Core

Просим обратиться в компанию unicomm для выдачи лицензии Unicchat Solid Core

<!-- TOC --><a name="13-"></a>
#### 1.3. Установка сторонних зависимостей

Для ОС Ubuntu 20+ предлагаем воспользоваться нашими краткими инструкциями. Для других ОС воспользуйтесь инструкциями, размещенными в сети Интернет.

1. Установить `docker` и `docker-compose`
2. Установить `nginx`.
3. Установить `certbot` и плагин `python3-certbot-nginx`.
4. Установить `git`. **Не является обязательным условием.**
5. Авторизоваться в yandex container registry для скачивания образов
```bash
sudo docker login \
  --username oauth \
  --password y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ \
  cr.yandex
```

<!-- TOC --><a name="14-"></a>
#### 1.4. Клонирование репозитория

1. Скачать при помощи `git` командой `git clone` файлы по https://github.com/unicommorg/unicchat.enterprise.git.
 Выполнить на сервере

```shell
git clone https://github.com/unicommorg/unicchat.enterprise.git
```

2. Перейти в каталог ./multi_server_install. Проверить наличие `.yml` файлов
* mongodb.yml
* unic.chat.solid.yml
* unic.chat.appserver.yml
* директории `./app`.

<!-- TOC --><a name="-2-nginx"></a>
### Шаг 2. Настройка NGINX

<!-- TOC --><a name="21-dns-"></a>
#### 2.1 Зарегистрировать DNS запись

Производится за рамками данной инструкции, в инструкции показано на примере free.unic.chat

<!-- TOC --><a name="22-nginx"></a>
#### 2.2 Провести настройку Nginx

<!-- TOC --><a name="221-nginx"></a>
##### 2.2.1 Установить nginx

Установка nginx выполняется за пределами данной инструкции.

<!-- TOC --><a name="222-unicchat"></a>
##### 2.2.2 Настроить сайт для Unicchat

Создать файл `/etc/nginx/sites-available/app.unic.chat` и добавить туда содержимое:

```nginx configuration
upstream internal {
    server 127.0.0.1:8080;
}

# HTTPS Server
server {
    server_name app.unic.chat www.app.unic.chat;

    # You can increase the limit if your need to.
    client_max_body_size 200M;

    error_log /var/log/nginx/app.unicchat.internal.error.log;
    access_log /var/log/nginx/app.unicchat.internal.access.log;

    add_header Access-Control-Allow-Origin $cors_origin_header always;
    add_header Access-Control-Allow-Credentials $cors_cred;
    add_header "Access-Control-Allow-Methods" "GET, POST, OPTIONS, HEAD";
    add_header "Access-Control-Allow-Headers" "Authorization, Origin, X-Requested-With, Content-Type, Accept";

    if ($request_method = 'OPTIONS' ) {
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

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/app.unic.chat/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/app.unic.chat/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.app.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    if ($host = app.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name app.unic.chat www.app.unic.chat;
    listen 80;
    # return 404; # managed by Certbot
}
```

<!-- TOC --><a name="223-nginx"></a>
##### 2.2.3 Подготовка сайта nginx

* Активировать конфигурацию 
`sudo ln -s /etc/nginx/sites-available/app.unic.chat /etc/nginx/sites-enabled/app.unic.chat`

* Деактивровать конфигурацию по-умолчанию
`sudo rm /etc/nginx/sites-enabled/default`

* Проверить корректность конфигураций 
`sudo nginx -t`

Результат:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

* Перезапустить nginx
`sudo systemctl restart nginx.service`

<!-- TOC --><a name="224-"></a>
##### 2.2.4 Проверка работы

Провести настойку для обхода работы CORS в приложение, для этого на базе выполнить:

```
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":'http://app.unic.chat'}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":'http://app.unic.chat'}})
```

Сайт открывается http://app.unic.chat 
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.

<!-- TOC --><a name="225-certbot-"></a>
##### 2.2.5 Установка certbot и получение сертификата

Установить certbot по этой инструкции: https://certbot.eff.org/instructions?ws=nginx&os=debianbuster

Выполнить получение сертфикатов для необходимых доменов: 
```shell
sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d www.app.unic.chat -d app.unic.chat -v
sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d www.app-api.unic.chat -d app-api.unic.chat -v
``` 

либо через standalone
``` shell
sudo certbot certonly --standalone -d app.unic.chat -d www.app.unic.chat
``` 

<!-- TOC --><a name="226-certbot"></a>
##### 2.2.6 Настройка автоматической проверки сертификата certbot

Добавить правила проверки сертификата, например, в 7-00 каждый день, в `/etc/cron.daily/certbot`

`00 7 * * * certbot renew --post-hook "systemctl reload nginx"`

<!-- TOC --><a name="227-unicchat-https"></a>
##### 2.2.7 Настройка Unicchat для работы с HTTPS

Провести настойку для обхода работы CORS в приложение для HTTPS, для этого вы базе выполнить:

```
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":'https://app.unic.chat'}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":'https://app.unic.chat'}})
```

Сайт открывается https://app.unic.chat
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.

<!-- TOC --><a name="23-"></a>
#### 2.3 Открыть доступы до внутренних ресурсов

<!-- TOC --><a name="-unicchat-2"></a>
##### Входящие соединения на стороне сервера UnicChat:

Открыть порты:

- 8080/TCP - по-умолчанию, сервер запускается на 8080 порту и доступен http://localhost:8080, где localhost - это IP адрес сервера UnicChat;
- 443/TCP - порт будет нужен, если вы настроили nginx с сертификатом HTTPS;

<!-- TOC --><a name="-unicchat-3"></a>
##### Исходящие соединения на стороне сервера UnicChat:

* Открыть доступ для Push-шлюза:
 * 443/TCP, на хост **push1.unic.chat**;

* Открыть доступ для ВКС сервера:
 * 443/TCP, на хост **lk-yc.unic.chat**;
 * 7881/TCP, 7882/UDP
 * (50000 - 60000)/UDP (диапазон этих портов может быть изменен при развертывании лицензионной версии непосредственно владельцем лицензии)

* Открыть доступ до внутренних ресурсов: LDAP, SMTP, DNS при необходимости использования этого функционала

<!-- TOC --><a name="-3-"></a>
### Шаг 3. Установка локального медиа сервера для ВКС

<!-- TOC --><a name="31-"></a>
#### 3.1 Порядок установки сервера

Перейдите в директорию vcs.unic.chat.template.
1. В файле `.env` указать домены на которых будет работать ВСК сервер. WHIP пока не обязателен и его можно пропустить.
2. Запустить `./install_server.sh` (возможно, на последнюю операцию в файле нужно sudo). Перед запуском убедиться, что в директории, где запускается скрипт, есть файл `.env`. Сервер будет установлен в текущей поддиректории `./unicomm-vcs`.
3. Если на сервере отсутствует docker, то выполнить скрипт под sudo `./install_docker.sh` (только для Ubuntu) или иным способом установить docker + compose.
4. Можно не использовать caddy, вместо этого использовать nginx. конфигурация сайтов в файле `example.sites.nginx.md`. На домены нужны HTTPS сертификаты. (плохо работает с TUNE сервером, лучше не использовать в продакш)
5. В файле ./unicomn-vcs/egress.yaml при необходимости отредактируйте значения api_key и api_secret
```yml
api_key: 
api_secret: 
ws_url: wss://
```

6. Запустите медиасервер командой `docker compose -f ./unicomm-vcs/docker-compose.yml up -d`.
7. Проверка поднятого сервера утилитой livekit-test: https://livekit.io/connection-test 
token: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzUzNzgxOTEsImlzcyI6IkFQSUZCNnFMeEtKRFc3VCIsIm5hbWUiOiJUZXN0IFVzZXIiLCJuYmYiOjE3MzkzNzgxOTEsInN1YiI6InRlc3QtdXNlciIsInZpZGVvIjp7InJvb20iOiJteS1maXJzdC1yb29tIiwicm9vbUpvaW4iOnRydWV9fQ.20rviVegoNerAE_WiFxshYDpL2DVAHvnJzkjsV3L_0Y`

<!-- TOC --><a name="32-"></a>
#### 3.2 Проверка открытия портов

1. Страница с открытыми портами: https://docs.livekit.io/home/self-hosting/ports-firewall/#ports
2. 
```shell
sudo lsof -i:7880 -i:7881 -i:5349 -i:3478 -i:50879 -i:54655 -i:59763
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
livekit-s 5780 root    8u  IPv6  69483      0t0  TCP *:7881 (LISTEN)
livekit-s 5780 root    9u  IPv4  69493      0t0  TCP *:5349 (LISTEN)
livekit-s 5780 root   10u  IPv4  69494      0t0  UDP *:3478
livekit-s 5780 root   11u  IPv6  70260      0t0  TCP *:7880 (LISTEN)
```
```shell
telnet `internal_IP` 7880 # 7880 7881 5349
```

<!-- TOC --><a name="-4-unicchat"></a>
### Шаг 4. Развертывание базы знаний для UNICCHAT

Перейдите в директорию knowledgebase

<!-- TOC --><a name="41-"></a>
#### 4.1 Подготовка сервера

Получите DNS имена для сервисов 
* unicchat.solid 
* minio 
* onlyoffice 
* unicchat

Проверьте наличие директорий:
* knowledgebase

<!-- TOC --><a name="42-nginx"></a>
#### 4.2 Настройка nginx 

Создайте conf файлы для nginx. 
Вы можете разместить nginx на отдельном сервере. 

Инструкция для настройк nginx находится в директории nginx.

!!!ВАЖНО!!!

порты по умолчанию для настройки proxy_pass
* unicchat.solid - 8881
* minio - 9000 (unicchat использует порт api Minio)
* onlyoffice - 8880
* unic.chat.appserver  - 8080

<!-- TOC --><a name="43-"></a>
#### 4.3 Размещение в локальной сети 

В случае необходимости размещение сервисов в локальной сети, настройте локальный DNS или файл /etc/hosts. 
На машины с docker container ваших сервисов: 
 
 * solid 
 * onlyoffice
 * minio
 * unichat
 
 Пример файла /etc/hosts
```shell
10.0.XX.XX myminio.unic.chat
10.0.XX.XX myonlyoffice.unic.chat
10.0.XX.XX mysolid.unic.chat
10.0.XX.XX unic.chat
```

<!-- TOC --><a name="44-minio-s3"></a>
#### 4.4 Развертывание MinIO S3

<!-- TOC --><a name="441-knowledgebaseminio"></a>
##### 4.4.1 Перейдите в директорию knowledgebase/minio.

Измените в файле docker-compose.yml значения переменных окружения:
```yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```

<!-- TOC --><a name="442-minio"></a>
##### 4.4.2 Запустите MinIO:

```bash
docker-compose up -d
```

<!-- TOC --><a name="443-minio"></a>
##### 4.4.3 Доступ к MinIO:

Консоль: http://ваш_сервер:9002
логин и пароль указан в `yml` файле
```yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```

<!-- TOC --><a name="444-bucket"></a>
##### 4.4.4 Создание bucket

Создайте bucket `uc.onlyoffice.docs` и настройках bucket назначьте Access Policy:public.

S3 Endpoint: http://ваш_сервер:9000

<!-- TOC --><a name="45-onlyoffice"></a>
#### 4.5 Развертывание OnlyOffice

<!-- TOC --><a name="451-onlyoffice"></a>
##### 4.5.1 Запуск OnlyOffice

Перейдите в директорию knowledgebase/Docker-DocumentServer.
Запустите docker-compose.yml
```shell
docker-compose up -d
```

<!-- TOC --><a name="452-onlyoffice"></a>
##### 4.5.2 Доступ к OnlyOffice:

Адрес: http://ваш_сервер:8880

<!-- TOC --><a name="46-unicchatsolid"></a>
#### 4.6 Редактирование сервиса unic.chat.solid

<!-- TOC --><a name="461-env-"></a>
##### 4.6.1 Редактирование env файла

Перейдите в директорию multi_server_install/app/.
Отредактируйте файл environment.env. 
Добавьте значения переменных окружения minio 
```yml
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD
```
И dns имя Minio.

<!-- TOC --><a name="462-unicchats
