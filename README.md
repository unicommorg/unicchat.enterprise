<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) --> 

- [Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat](#-unicchat)
   * [Оглавление](#)
   * [Скачать инструкции в PDF ](#-pdf)
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
      + [1.1 Требования к конфигурации ](#11-)
         - [Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине](#-20-1-)
         - [Конфигурация виртуальной машины](#--4)
         - [Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины](#-20-50-)
         - [Конфигурация виртуальной машины для приложения](#--5)
         - [Конфигурация виртуальной машины для БД](#--6)
      + [1.2. Запрос лицензии для Unicchat Solid Core](#12-unicchat-solid-core)
      + [1.3. Установка сторонних зависимостей](#13-)
      + [1.4. Клонирование репозитория](#14-)
   * [Шаг 2. Установка UnicChat](#-2-unicchat)
      + [2.1 Настройка БД - mongodb](#21-mongodb)
      + [2.2 Создать базу и пользователя для подключения к базе](#22-)
      + [2.3 Настройка unicchat.solid.core](#23-unicchatsolidcore)
      + [2.4 Запуск сервера UnicChat](#24-unicchat)
   * [Шаг 3. Настройка NGINX](#-3-nginx)
      + [3.1 Зарегистрировать DNS запись](#31-dns-)
      + [3.2 Провести настройку Nginx](#32-nginx)
         - [3.2.1 Установить nginx](#321-nginx)
         - [3.2.2 Настроить сайт для Unicchat](#322-unicchat)
         - [3.2.3 Подготовка сайта nginx ](#323-nginx)
         - [3.2.4 Проверка работы ](#324-)
         - [3.2.5 Установка certbot и получение сертификата](#325-certbot-)
         - [3.2.6 Настройка автоматической проверки сертификата certbot](#326-certbot)
         - [3.2.7 Настройка Unicchat для работы с HTTPS](#327-unicchat-https)
      + [3.3 Открыть доступы до внутренних ресурсов](#33-)
         - [Входящие соединения на стороне сервера UnicChat:](#-unicchat-2)
         - [Исходящие соединения на стороне сервера UnicChat:](#-unicchat-3)
   * [Шаг 4. Создание пользователя администратора](#-4-)
   * [Шаг 5. Настройка push-уведомлений](#-5-push-)
   * [Шаг 6. Настройка подключения к SMTP серверу для отправки уведомлений в почту](#-6-smtp-)
   * [Шаг 7. Настройка подключения к LDAP серверу](#-7-ldap-)
   * [Быстрый старт. Запуск на одном сервере](#--7)
   * [Быстрый старт. Запуск на двух серверах](#--8)
   * [Шаг 8. Установка локального медиа сервера для ВКС](#-8-)
      + [Порядок установки сервера](#--9)
      + [Проверка открытия портов](#--10)
   * [Шаг.9  Развертывание базы знаний для UNICCHAT](#9-unicchat)
      + [9.1 Подготовка сервера](#91-)
      + [9.2 Настройка nginx ](#92-nginx)
      + [9.3 Размещение в локальной сети ](#93-)
      + [9.4 Развертывание MinIO S3](#94-minio-s3)
         - [9.4.1 Перейдите в директорию knowledgebase/minio.](#941-knowledgebaseminio)
         - [9.4.2 Запустите MinIO:](#942-minio)
         - [9.4.3 Доступ к MinIO:](#943-minio)
         - [9.4.4 Создание bucket](#944-bucket)
      + [9.5 Развертывание OnlyOffice](#95-onlyoffice)
         - [9.5.1 Запуск OnlyOffice](#951-onlyoffice)
         - [9.5.2 Доступ к OnlyOffice:](#952-onlyoffice)
      + [9.6 Редактироваие сервиcа unic.chat.solid](#96-c-unicchatsolid)
         - [9.6.1 Редактироваие env файла](#961-env-)
         - [9.6.2 Пересоздание сервиса unic.chat.solid](#962-unicchatsolid)
      + [9.7 Редактироваие сервиcа unic.chat.appserver](#97-c-unicchatappserver)
         - [9.7.1 Добавление переменной окружения ONLYOFFICE_HOST ](#971-onlyoffice_host)
         - [9.7.2 Пересоздание сервиса unic.chat.appserver](#972-unicchatappserver)
      + [Частые проблемы при установке](#--11)
      + [Клиентские приложения](#--12)
      + [Частые проблемы при установке](#--13)

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
* [Инструкция_по_администрированию_UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%B8%D1%81%D1%82%D1%80%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Инструкция_по_лицензированию_UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
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

Публичный сервис компании Unicomm. Подключение к нему необходимо для отправки push-сообщений на мобильные платформы
Apple и Google.
Расположен во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и
не требуются входящие соединения.

<!-- TOC --><a name="--2"></a>
##### ВКС шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для работы аудио и видео конференций, а также
аудио-звонков.
Расположены во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и
не требуются входящие соединения.

<!-- TOC --><a name="-unicchat-1"></a>
##### Приложения UnicChat

Пользовательское приложение, установленное на iOS или Android платформе.
Сервер UnicChat должен иметь возможность принимать входящие сообщения от этих приложений, а также отправлять ответы.
Основное взаимодействие осуществляется через протокол HTTPS (443/TCP).
Для работы видео- и аудиозвонков необходимы протоколы STUN и TURN: входящие соединения на порты 7881/TCP и 7882/UDP,
а также входящий и исходящий трафик UDP по портам 50000-60000 (RTP-трафик).

<!-- TOC --><a name="--3"></a>
### Опциональные компоненты

___

<!-- TOC --><a name="smtp-"></a>
##### SMTP сервер

Используется для отправки OTP-сообщений, восстановлений пароля, напоминания о пропущенных сообщениях, предоставляется
вами.
Может быть использован как публичный, так и ваш собственный сервер. На схеме предполагается, что сервер находится в
вашем сегменте DMZ.
**Интеграция с SMTP не является обязательным условием.**

<!-- TOC --><a name="ldap-"></a>
##### LDAP сервер

Используется для получения списка пользователей в системе. UnicChat может обслуживать как пользователей, заведенных в
LDAP каталоге,
так и внутренних пользователей в собсвенной базе. **Интеграция с LDAP не является обязательным условием**



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
Просим обратиться в компанию unicomm  для выдачи лицензии Unicchat Solid Core 
<!-- TOC --><a name="13-"></a>
#### 1.3. Установка сторонних зависимостей

Для ОС Ubuntu 20+ предлагаем воспользоваться нашими краткими инструкциями. Для других ОС воспользуйтесь инструкциями,
размещенными в сети Интернет.

1. Установить `docker` и `docker-compose `
2. Установить `nginx`.
3. Установить `certbot` и плагин `python3-certbot-nginx`.
4. Установить `git`. **Не является обязательным условием.**
5. Авторизоваться в yandex container registry для скачивания образов
``` bash
 sudo docker login \
  --username oauth \
  --password y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ \
  cr.yandex
```

<!-- TOC --><a name="14-"></a>
#### 1.4. Клонирование репозитория

1. Скачать при помощи `git` командой `git clone` файлы по https://github.com/unicommorg/unicchat.enterprise.git .
 Выполнить на сервере

```shell 
 git https://github.com/unicommorg/unicchat.enterprise.git
```

2. Перейти в каталог ./multi_server_install. Проверить наличие `.yml` файлов 
* mongodb.yml
* unicchat.score.yml
* unicchat.yml 
и директории `./app` .


<!-- TOC --><a name="-2-unicchat"></a>
### Шаг 2. Установка UnicChat
<!-- TOC --><a name="21-mongodb"></a>
#### 2.1 Настройка БД - mongodb

1. [Linux] На сервере БД выполните команду `grep avx /proc/cpuinfo`. Если в ответе вы не видите AVX, то вам лучше
 выбрать версию mongodb < 5.х, например, 4.4
 если AVX на вашем сервере поддерживается, рекомендуется выбрать версию mongodb > 5.х.
2. ВАЖНО! Если вы планируете запустить БД и сервер UnicChat на разных виртуальных серверах, то в
 параметрах `MONGODB_INITIAL_PRIMARY_HOST` и `MONGODB_ADVERTISED_HOSTNAME` вам нужно указать адрес (DNS или IP) вашего сервера, где запускается БД.
3. Если же установка планируется на одной машине, создайте вначале сети в которые будут подключаться контейнеры
 приложения и БД 
 ``` shell 
 docker network create unicchat-backend
 docker network create unicchat-frontend
 ```
4. Запустить mongodb командой

``` yml
docker-compose -f mongodb.yml up -d 
```

<!-- TOC --><a name="22-"></a>
#### 2.2 Создать базу и пользователя для подключения к базе

1. После того как база успешно запустилась, подключимся к контейнеру с запущенной БД. Для этого на сервере, где запущен
 docker контейнер c базой, выполните

```shell
docker exec -it   unic.chat.db.mongo.4.4 /bin/bash
```

где `unic.chat.free.db.mongo` - имя нашего контейнера, указанного в `mongodb.yml`, в инструкции `container_name`.


 Теперь в командной строке внутри контейнера выполним подключение с помощью `mongosh`

```shell
mongosh -u root -p password
```

где `password` - это указанный вами пароль в файле `mongosh.yml` в параметре `MONGODB_ROOT_PASSWORD`
Если авторизация выполнена успешно, вы увидите приглашение `mongosh` и текст успешной авторизации, как на примере ниже.

```
Current Mongosh Log ID:	65c5d795e6d642628b94ece4
Connecting to:		mongodb://<credentials>@127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+1.5.0
Using MongoDB:		4.4.15
Using Mongosh:		1.5.0

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
 The server generated these startup warnings when booting
 2023-12-26T14:39:46.393+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
------

rs0 [direct: primary] test>
```

3. Теперь можно выполнить скрипты создания базы и пользователя. Для этого, предварительно, укажите ваши значения в
 параметрах ниже и выполните команды создания БД и пользователя.
 * `{db_name}` - название базы;
 * `{ucusername}` - пользователь, под которым будет подключаться приложение;
 * `{ucpassword}` - пароль пользователя приложения;

```spring-mongodb-json
// проверьте наличие вашей базы данных
show databases

// Перейдите на вашу базу данных и проверьте пользователя
use db_name
show users



db.updateUser( "ucusername",
{
roles: [
{role: "readWrite", db: "local"},
{role: "readWrite", db: "db_name"},
{role: "dbAdmin", db: "db_name"},
{role: "clusterMonitor", db: "admin"}
]
})
// Перейдите на вашу базу данных и проверьте права пользователя
use db_name
show users
```
<!-- TOC --><a name="23-unicchatsolidcore"></a>
#### 2.3 Настройка unicchat.solid.core
 
 Откройте на редактирование файл ./app/environment.env 
 Измените значения переменных 
 * Mongo 
 * Minio (опционально, понадобится при настройке Базы знаний) 
 Запустите 
 ```shell 
 
 docker-compose -f unicchat.score.yml up -d
 docker-compose -f unicchat.score.yml logs -ft
 ```

<!-- TOC --><a name="24-unicchat"></a>
####  2.4 Запуск сервера UnicChat

1. Отредактируйте параметры ниже в `unicchat.yml файле.
 * `{uc_port}` - порт, на котором будет запущен сервер UnicChat,  по умолчанию 8080;
   
 * `{mongodb}` - укажите адрес вашего сервера БД. Если вы запускаете сервер UnicChat и БД на одном сервере, оставьте
 текущее значение без изменений.

``` yaml
environment:
  - MONGO_URL=mongodb://<username>:<password>@mongodb:27017/<database>?replicaSet=rs0
  - MONGO_OPLOG_URL=mongodb://<username>:<password>@mongodb:27017/local
```
Где необходимо заменить:

<username> - имя пользователя MongoDB

<password> - пароль пользователя

<database> - название вашей базы данных

 * `UNIC_SOLID_HOST` - укажите имя или IP адрес вашего сервера с solid.

2. Запустить контейнер, например, командой `docker-compose -f unicchat.yml up -d`

3. После запуска приложения, вы можете открыть веб-интерфейс приложения по адресу `http://unicchat_server_ip:port`,
 где `unicchat_server_ip` - имя или IP адрес сервера,
 где был запущен UnicChat, `port` - значение параметра, которые вы указали выше.
 Открывайте веб интерфейс с сервера, на котором у вас стоит `.yml` файл серверной части unicchat.
 Если у вас нет браузера с привычном виде (сервер без GUI). Проверте доступ при помощи curl. 
 ```shell 
 curl -I http://unicchat_server_ip:port
 ```
 А также посмотрите на логи 
```shell
 docker-compose -f unicchat.yml logs -ft`
```


 

<!-- TOC --><a name="-3-nginx"></a>
### Шаг 3. Настройка NGINX
<!-- TOC --><a name="31-dns-"></a>
#### 3.1 Зарегистрировать DNS запись

Производится за рамками данной инструкции, в инструкции показано на примере free.unic.chat
<!-- TOC --><a name="32-nginx"></a>
#### 3.2 Провести настройку Nginx

<!-- TOC --><a name="321-nginx"></a>
##### 3.2.1 Установить nginx

Установка nginx  выполняется за пределами данной инструкции.


<!-- TOC --><a name="322-unicchat"></a>
#####  3.2.2 Настроить сайт для Unicchat

Создать файл `/etc/nginx/sites-available/app.unic.chat` и добавить туда содержимое:

```nginx configuration
upstream internal {
    server 127.0.0.1:8080;
}

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

    listen 80; 
}
server {
    if ($host = www.app.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    if ($host = app.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
}
```

<!-- TOC --><a name="323-nginx"></a>
##### 3.2.3 Подготовка сайта nginx 

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

<!-- TOC --><a name="324-"></a>
##### 3.2.4 Проверка работы 

Провести настойку для обхода работы CORS в приложение, для этого на базе выполнить:

```
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":'http://app.unic.chat'}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":'http://app.unic.chat'}})
```

Сайт открывается http://app.unic.chat 
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.

<!-- TOC --><a name="325-certbot-"></a>
##### 3.2.5 Установка certbot и получение сертификата

Установить certbot по этой инструкции: https://certbot.eff.org/instructions?ws=nginx&os=debianbuster

Выполнить получение сертфикатов для необходимых доменов: 
```shell
sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d www.app.unic.chat -d app.unic.chat -v
sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d www.app-api.unic.chat -d app-api.unic.chat -v
``` 

либо через  standalone
``` shell
sudo certbot certonly --standalone -d   app.unic.chat -d  www.app.unic.chat
``` 
<!-- TOC --><a name="326-certbot"></a>
##### 3.2.6 Настройка автоматической проверки сертификата certbot

Добавить правила проверки сертификата, например, в 7-00 каждый день, в `/etc/cron.daily/certbot`

`00 7 * * * certbot renew --post-hook "systemctl reload nginx"`

<!-- TOC --><a name="327-unicchat-https"></a>
##### 3.2.7 Настройка Unicchat для работы с HTTPS

Провести настойку для обхода работы CORS в приложение для HTTPS, для этого вы базе выполнить:

```
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":'https://app.unic.chat'}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":'https://app.unic.chat'}})
```

Сайт открывается https://app.unic.chat
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.


<!-- TOC --><a name="33-"></a>
####  3.3 Открыть доступы до внутренних ресурсов

<!-- TOC --><a name="-unicchat-2"></a>
##### Входящие соединения на стороне сервера UnicChat:

Открыть порты:

- 8080/TCP - по-умолчанию, сервер запускается на 8080 порту и доступен http://localhost:8080, где localhost - это IP
 адрес сервера UnicChat;
- 443/TCP - порт будет нужен, если вы настроили nginx с сертификатом HTTPS;

<!-- TOC --><a name="-unicchat-3"></a>
##### Исходящие соединения на стороне сервера UnicChat:

* Открыть доступ для Push-шлюза:
 * 443/TCP, на хост **push1.unic.chat**;

* Открыть доступ для ВКС сервера:
 * 443/TCP, на хост **lk-yc.unic.chat**;
 * 7881/TCP, 7882/UDP
 * (50000 - 60000)/UDP (диапазон этих портов может быть измененён при развертывании лицензионной версии
 непосредственно владельцем лицензии)

* Открыть доступ до внутренних ресурсов: LDAP, SMTP, DNS при необходимости использования этого функционала

<!-- TOC --><a name="-4-"></a>
### Шаг 4. Создание пользователя администратора

* `Name` - Имя пользователя, которое будет отображаться в чате;
* `Username` - Логин пользователя, который вы будете указывать для авторизации;
* `Email` - Действующая почта, используется для восстановления
* `Organization Name` - Краткое название вашей организации латинскими буквами без пробелов и спец. символов,
 используется для регистрации push уведомлений. Может быть указан позже;
* `Organization ID` - Идентификатор вашей организации, используется для подключения к push серверу. Может быть указан
 позже. Для получения ID необходимо написать запрос с указанием значения в Organization Name на почту
 support@unicomm.pro;
* `Password` - пароль вашего пользователя;
* `Confirm your password` - подтверждение пароля;

1. После создания пользователя, авторизоваться в веб-интерфейсе с использованием ранее указанных параметров.
2. Для включения пушей, перейти в раздел Администрирование - Push. Включить использование шлюза и указать адрес
 шлюза https://push1.unic.chat
3. Перейти в раздел Администрирование - Organization, убедиться что поля заполнены в соответствии с вашими данными.
4. Настройка завершена.

При первом входе может возникнуть информационное предупреждение
![](./assets/111.jpg "Предупреждение при первом входе")

Нажмите "ДА"

<!-- TOC --><a name="-5-push-"></a>
### Шаг 5. Настройка push-уведомлений

Приложение Unicchat работает с внешним push сервером для доставки push-уведомлений в приложение Unicchat на мобильные
устройства.

<!-- TOC --><a name="-6-smtp-"></a>
### Шаг 6. Настройка подключения к SMTP серверу для отправки уведомлений в почту

Раздел в разработке.

<!-- TOC --><a name="-7-ldap-"></a>
### Шаг 7. Настройка подключения к LDAP серверу

Раздел в разработке.



<!-- TOC --><a name="--7"></a>
### Быстрый старт. Запуск на одном сервере

Раздел в разработке.

<!-- TOC --><a name="--8"></a>
### Быстрый старт. Запуск на двух серверах

Раздел в разработке.

<!-- TOC --><a name="-8-"></a>
### Шаг 8. Установка локального медиа сервера для ВКС
<!-- TOC --><a name="--9"></a>
#### Порядок установки сервера
Перейдите в директорию vcs.unic.chat.template.
1. В файле `.env` указать домены на которых будет работать ВСК сервер. WHIP пока не обязателен и его можно пропустить.
2. Запустить `./install_server.sh` (возможно, на последнюю операцию в файле нужно sudo). Перед запуском убедиться, что в директории, 
где запускается скрипт, есть файл `.env`. Сервер будет установлен в текущей поддиректории `./unicomm-vcs` .
3. Если на сервере отсутствует docker, то выполнить скрипт под sudo `./install_docker.sh` (только для Ubuntu) или иным способом установить docker + compose .
4. Можно не использовать caddy, вместо этого использовать nginx. конфигурация сайтов в файле `example.sites.nginx.md`. На домены нужны HTTPS сертификаты. (плохо работает с TUNE сервером, лучше не использовать в продакш)
5. В файле ./unicomn-vcs/egress.yaml при необходимости отредактируйте значения api_key и api_secret
``` yml
api_key: 
api_secret: 
ws_url: wss://
```

6. Запустите медиасервер командой `docker compose -f ./unicomm-vcs/docker-compose.yml up -d`.
7. Проверка поднятого сервера утилитой livekit-test: https://livekit.io/connection-test 
token: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzUzNzgxOTEsImlzcyI6IkFQSUZCNnFMeEtKRFc3VCIsIm5hbWUiOiJUZXN0IFVzZXIiLCJuYmYiOjE3MzkzNzgxOTEsInN1YiI6InRlc3QtdXNlciIsInZpZGVvIjp7InJvb20iOiJteS1maXJzdC1yb29tIiwicm9vbUpvaW4iOnRydWV9fQ.20rviVegoNerAE_WiFxshYDpL2DVAHvnJzkjsV3L_0Y`


<!-- TOC --><a name="--10"></a>
#### Проверка открытия портов
1. Страница с открытыми портами: https://docs.livekit.io/home/self-hosting/ports-firewall/#ports
2. 
``` shell 
 sudo lsof -i:7880 -i:7881 -i:5349 -i:3478 -i:50879 -i:54655 -i:59763
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
livekit-s 5780 root    8u  IPv6  69483      0t0  TCP *:7881 (LISTEN)
livekit-s 5780 root    9u  IPv4  69493      0t0  TCP *:5349 (LISTEN)
livekit-s 5780 root   10u  IPv4  69494      0t0  UDP *:3478
livekit-s 5780 root   11u  IPv6  70260      0t0  TCP *:7880 (LISTEN)
```
``` shell
telnet `internal_IP` 7880 # 7880 7881 5349
```
<!-- TOC --><a name="9-unicchat"></a>
### Шаг.9  Развертывание базы знаний для UNICCHAT
Перейдите в директорию knowledgebase
<!-- TOC --><a name="91-"></a>
#### 9.1 Подготовка сервера
Получите DNS имена для сервисов 
* unicchat.solid 
* minio 
* onlyoffice 
* unicchat

Проверьте наличие директорий:
* knowledgebase

<!-- TOC --><a name="92-nginx"></a>
#### 9.2 Настройка nginx 
Создайте conf файлы для nginx. 
Вы можете разместить nginx на отдельном сервере. 

Инструкция для настройк nginx находится в директории nginx.

!!!ВАЖНО!!!

порты по умолчанию для настройки proxy_pass
* unicchat.solid - 8881
* minio - 9000 (unicchat использует порт api Minio)
* onlyoffice - 8880
* unicchat - 8080

<!-- TOC --><a name="93-"></a>
#### 9.3 Размещение в локальной сети 
В случае необходимости размещение сервисов в локальной сети, настройте локальный DNS или файл /etc/hosts. 
На машины с docker container ваших сервисов: 
 
 * solid 
 * onlyoffice
 * minio
 * unichat
 
 Пример файла /etc/hosts
``` shell 
 10.0.XX.XX myminio.unic.chat
 10.0.XX.XX myonlyoffice.unic.chat
 10.0.XX.XX mysolid.unic.chat
 10.0.XX.XX unic.chat
 ```
<!-- TOC --><a name="94-minio-s3"></a>
#### 9.4 Развертывание MinIO S3
<!-- TOC --><a name="941-knowledgebaseminio"></a>
##### 9.4.1 Перейдите в директорию knowledgebase/minio.
Измените в файле docker-compose.yml значения переменных окружения:
``` yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```
<!-- TOC --><a name="942-minio"></a>
##### 9.4.2 Запустите MinIO:
``` bash
docker-compose up -d
```
<!-- TOC --><a name="943-minio"></a>
##### 9.4.3 Доступ к MinIO:
Консоль: http://ваш_сервер:9002
логин и пароль указан в `yml` файле
``` yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```
<!-- TOC --><a name="944-bucket"></a>
##### 9.4.4 Создание bucket
Создайте bucket `uc.onlyoffice.docs` и настройках bucket назначьте Access Policy:public.

S3 Endpoint: http://ваш_сервер:9000

<!-- TOC --><a name="95-onlyoffice"></a>
#### 9.5 Развертывание OnlyOffice
<!-- TOC --><a name="951-onlyoffice"></a>
##### 9.5.1 Запуск OnlyOffice
Перейдите в директорию knowledgebase/Docker-DocumentServer.
Запустите docker-compose.yml
``` shell
docker-compose up -d
```
<!-- TOC --><a name="952-onlyoffice"></a>
##### 9.5.2 Доступ к OnlyOffice:
Адрес: http://ваш_сервер:8880

<!-- TOC --><a name="96-c-unicchatsolid"></a>
#### 9.6 Редактироваие сервиcа unic.chat.solid
<!-- TOC --><a name="961-env-"></a>
##### 9.6.1 Редактироваие env файла
Перейдите в директорию multi_server_install/app/.
Отредактируйте файл environment.env. 
Добавьте значения переменных окружения minio 
``` yml
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD
```
И dns имя Minio без https.

<!-- TOC --><a name="962-unicchatsolid"></a>
##### 9.6.2 Пересоздание сервиса unic.chat.solid
Пересоздайте container для unic.chat.solid:
```bash
 docker-compose -f unic.chat.solid.yml down && docker-compose -f unic.chat.solid.yml up -d
```
Доступ: http://ваш_сервер:8881/swagger/index.html 

<!-- TOC --><a name="97-c-unicchatappserver"></a>
#### 9.7 Редактироваие сервиcа unic.chat.appserver
<!-- TOC --><a name="971-onlyoffice_host"></a>
##### 9.7.1 Добавление переменной окружения ONLYOFFICE_HOST 
Перейдите в директорию multi_server_install.
Отредактируйте ввш unic.chat.appserver.yml.
Добавьте в переменные окружения:
``` yml
 - ONLYOFFICE_HOST=https://адрес_в_формате dns
```
<!-- TOC --><a name="972-unicchatappserver"></a>
##### 9.7.2 Пересоздание сервиса unic.chat.appserver
Запустите:
``` shell
docker-compose -f unic.chat.appserver.yml down && docker-compose -f unic.chat.appserver.yml up -d
```

 
<!-- TOC --><a name="--11"></a>
#### Частые проблемы при установке

Раздел в разработке.

<!-- TOC --><a name="--12"></a>
#### Клиентские приложения

* [Репозитории клиентских приложений]
* Android: (https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat&pcampaignid=web_share)
* iOS: (https://apps.apple.com/ru/app/unicchat/id1665533885)
* Desktop: (https://github.com/unicommorg/unic.chat.desktop.releases/releases)

<!-- TOC --><a name="--13"></a>
#### Частые проблемы при установке

Раздел в разработке.
