## Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat

###### версия enterprise-1.6.2, версия документа 1.7

### Оглавление

<!-- TOC -->

* [Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat](#инструкция-по-установке-корпоративного-мессенджера-для-общения-и-командной-работы-unicchat)
    * [Архитектура установки](#архитектура-установки)
    * [Обязательные компоненты](#обязательные-компоненты)
    * [Опциональные компоненты](#опциональные-компоненты)
    * [Шаг 1. Подготовка окружения](#шаг-1-подготовка-окружения)
    * [Шаг 2. Установка сторонних зависимостей](#шаг-2-установка-сторонних-зависимостей)
    * [Шаг 3. Клонирование репозитория](#шаг-3-Клонирование-репозитория)
    * [Шаг 4. Установка и настройка БД - mongodb](#шаг-4-установка-и-настройка-бд---mongodb)
    * [Шаг 5. Создать базу и пользователя для подключения к базе](#шаг-5-создать-базу-и-пользователя-для-подключения-к-базе)
    * [Шаг 6. Запуск сервера UnicChat](#шаг-6-запуск-сервера-unicchat)
    * [Шаг 7. Зарегистрировать DNS запись](#шаг-7-Зарегистрировать-DNS-запись)
    * [Шаг 8. Подготовить конфигурацию для сайта на nginx](#шаг-8-Подготовить-конфигурацию-для-сайта-на-nginx)
    * [Шаг 9. Настройка nginx как Proxy](#шаг-9-настройка-nginx-как-proxy)
    * [Шаг 10. Получение сертификата Let's Encrypt](#шаг-10-получение-сертификата-lets-encrypt)
    * [Шаг 11. Запуск nginx](#шаг-11-Запуск-nginx)
    * [Шаг 12. Проверка работы](#шаг-12-Проверка-работы)
    * [Шаг 13. Открыть доступы до внутренних ресурсов](#шаг-13-открыть-доступы-до-внутренних-ресурсов)
    * [Шаг 14. Создание пользователя администратора](#шаг-14-создание-пользователя-администратора)
    * [Шаг 15. Настройка push-уведомлений](#шаг-15-настройка-push-уведомлений)
    * [Шаг 16. Настройка подключения к SMTP серверу для отправки уведомлений в почту](#шаг-16-настройка-подключения-к-smtp-серверу-для-отправки-уведомлений-в-почту)
    * [Шаг 17. Настройка подключения к LDAP серверу](#шаг-17-настройка-подключения-к-ldap-серверу)
    * [Шаг 18. Настройка DLP](#шаг-18-настройка-DLP)
    * [Быстрый старт. Запуск на одном сервере](#быстрый-старт-запуск-на-одном-сервере)
    * [Быстрый старт. Запуск на двух серверах](#быстрый-старт-запуск-на-двух-серверах)
    * [Настройка отказоустойчивого решения](#настройка-отказоустойчивого-решения)
    * [Установка локального медиа сервера для ВКС](####Установка-локального-медиа-сервера-для-ВКС)
    * [Частые проблемы при установке](#частые-проблемы-при-установке)
    * [Клиентские приложения](#клиентские-приложения)

<!-- TOC -->

### Архитектура установки

___

#### Установка на 1-м сервере

![](./assets/1vm-unicchat-install-scheme.jpg "Архитектура установки на 1-м сервере")

#### Установка на 2-х серверах (рекомендуется для промышленного использования)

![](./assets/2vm-unicchat-install-scheme.jpg "Архитектура установки на 2-х серверах")

### Обязательные компоненты

___

##### Push шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для отправки push-сообщений на мобильные платформы
Apple и Google.
Расположен во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и
не требуются входящие соединения.

##### ВКС шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для работы аудио и видео конференций, а также
аудио-звонков.
Расположены во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и
не требуются входящие соединения.

##### Приложения UnicChat

Пользовательское приложение, установленное на iOS или Android платформе.
Сервер UnicChat должен иметь возможность принимать входящие сообщения от этих приложений, а также отправлять ответы.
Основное взаимодействие осуществляется через протокол HTTPS (443/TCP).
Для работы видео- и аудиозвонков необходимы протоколы STUN и TURN: входящие соединения на порты 7881/TCP и 7882/UDP,
а также входящий и исходящий трафик UDP по портам 50000-60000 (RTP-трафик).

### Опциональные компоненты

___

##### SMTP сервер

Используется для отправки OTP-сообщений, восстановлений пароля, напоминания о пропущенных сообщениях, предоставляется
вами.
Может быть использован как публичный, так и ваш собственный сервер. На схеме предполагается, что сервер находится в
вашем сегменте DMZ.
**Интеграция с SMTP не является обязательным условием.**

##### LDAP сервер

Используется для получения списка пользователей в системе. UnicChat может обслуживать как пользователей, заведенных в
LDAP каталоге,
так и внутренних пользователей в собсвенной базе. **Интеграция с LDAP не является обязательным условием**

### Шаг 1. Подготовка окружения

#### Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине

##### Конфигурация виртуальной машины

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2, AVX 2.0;
RAM 8 Gb;
150 Gb HDD\SSD;
```

#### Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины

##### Конфигурация виртуальной машины для приложения

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2;
RAM 8 Gb;
200 Gb HDD\SSD
```

##### Конфигурация виртуальной машины для БД

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2, AVX 2.0;
RAM 8 Gb;
100 Gb HDD\SSD
```

### Шаг 2. Установка сторонних зависимостей

Для ОС Ubuntu 20+ предлагаем воспользоваться нашими краткими инструкциями. Для других ОС воспользуйтесь инструкциями,
размещенными в сети Интернет.

1. Установить `docker` и `docker-compose `
2. Установить `nginx`.
3. Установить `certbot` и плагин `python3-certbot-nginx`.
4. Установить `git`. **Не является обязательным условием.**

### Шаг 3. Клонирование репозитория

1. Скачать при помощи `git` командой `git clone` файлы по  https://github.com/unicommorg/unicchat.free.git .
   Выполнить на сервере

```shell   
  git clone https://github.com/unicommorg/unicchat.free.git
```

2. Перейти в каталог ./single_server_install. Проверить наличие `.yml` файла unicchat_all_in_one.yml и
   директории `./config` .

### Шаг 4. Настройка БД - mongodb

1. [Linux] На сервере БД выполните команду `grep avx /proc/cpuinfo`. Если в ответе вы не видите AVX, то вам лучше
   выбрать версию mongodb < 5.х, например, 4.4
   если AVX на вашем сервере поддерживается, рекомендуется выбрать версию mongodb > 5.х.
2. ВАЖНО! Если вы планируете запустить БД и сервер UnicChat на разных виртуальных серверах, то в
   параметрах `MONGODB_INITIAL_PRIMARY_HOST` и `MONGODB_ADVERTISED_HOSTNAME` вам нужно указать адрес (DNS или IP) вашего
   сервера, где запускается БД.
   В клонированном репозитории на шаге 3 сервисы описаны в одном `.yml` файле. Если вы планируете запустить БД и сервер
   UnicChat на разных виртуальных серверах то разделите настройки по разным серверам, к примеру на mongodb.yml и
   unicchat.yml.
   В инструкции ниже настройки unicchat_all_in_one.yml разнесены на mongodb.yml и unicchat.yml, если установка
   планируется на одной машине, можете оставить настройки в одном `.yml`файле.
3. Если же установка планируется на одной машине, создайте вначале сети в которые будут подключаться контейнеры
   приложения и БД `docker network create unic-chat-free`
4. Запустить mongodb командой

``` yml
docker-compose -f mongodb.yml up -d 
```

```yml 
version: "3"
services:
  mongodb:
    image: docker.io/bitnami/mongodb:${MONGODB_VERSION:-5.0}
    container_name: unic.chat.free.db.mongo
    restart: on-failure
    volumes:
      - mongodb_data:/bitnami/mongodb
    environment:
      MONGODB_REPLICA_SET_MODE: primary
      MONGODB_REPLICA_SET_NAME: ${MONGODB_REPLICA_SET_NAME:-rs0}
      MONGODB_REPLICA_SET_KEY: ${MONGODB_REPLICA_SET_KEY:-rs0key}
      MONGODB_PORT_NUMBER: ${MONGODB_PORT_NUMBER:-27017}
      # поменять IP адрес своего сервера в MONGODB_INITIAL_PRIMARY_HOST и MONGODB_ADVERTISED_HOSTNAME
      MONGODB_INITIAL_PRIMARY_HOST: ${MONGODB_INITIAL_PRIMARY_HOST:-mongodb}
      MONGODB_INITIAL_PRIMARY_PORT_NUMBER: ${MONGODB_INITIAL_PRIMARY_PORT_NUMBER:-27017}
      MONGODB_ADVERTISED_HOSTNAME: ${MONGODB_ADVERTISED_HOSTNAME:-mongodb}
      MONGODB_ENABLE_JOURNAL: ${MONGODB_ENABLE_JOURNAL:-true}
      # указать свой пароль для root
      MONGODB_ROOT_PASSWORD: "setrootpassword"
      # Указать логин и пароль пользователя
      MONGODB_USERNAME: "ucusername"
      MONGODB_PASSWORD: "ucpassword"
      # указать базу данных
      MONGODB_DATABASE: "db_name"
    ports:
      - "27017:27017"
    networks:
      - unic-chat-free

networks:
  unic-chat-free:
    external: true

volumes:
  mongodb_data: { driver: local }
```

### Шаг 5. Создать базу и пользователя для подключения к базе

1. После того как база успешно запустилась, подключимся к контейнеру с запущенной БД. Для этого на сервере, где запущен
   docker контейнер c базой, выполним

```shell
docker exec -it unic.chat.free.db.mongo /bin/bash
```

где `unic.chat.free.db.mongo` - имя нашего контейнера, указанного в `mongodb.yml`, в инструкции `container_name`.

2. Теперь в командной строке внутри контейнера выполним подключение с помощью `mongosh`

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


//Если его нет
//Выполним скрипт создания пользователя с назначением ему необходимых ролей
db.createUser({
  user: "ucusername",
  pwd: "ucpassword",
  roles: [
    {
      role: "readWrite",
      db: "local"
    },
    {
      role: "readWrite",
      db: "db_name"
    },
    {
      role: "dbAdmin",
      db: "db_name"
    },
    {
      role: "clusterMonitor",
      db: "admin"
    }
  ]
})

// Если он есть
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

### Шаг 6. Запуск сервера UnicChat

1. Заполните параметры ниже в yml файле и сохраните его как `unicchat.yml`
    * `{port}` - порт, на котором будет запущен сервер UnicChat (должен быть тот же что был указан для nginx);
    * `{db_name}` - название базы данных;
    * `{ucusername}` - пользователь, под которым будет подключаться сервер UnicChat к БД;
    * `{ucpassword}` - пароль пользователя;
    * `{mongodb}` - укажите адрес вашего сервера БД. Если вы запускаете сервер UnicChat и БД на одном сервере, оставьте
      текущее значение без изменений.
    * `{ucserver}` - укажите имя или IP адрес вашего сервера UnicChat, например, публичный адрес вашего сервера для
      пользователей

```yml
version: "3"
services:
  unic.chat.free:
    container_name: unic.chat.appserver.free
    image: index.docker.io/unicommhub/unicchat_free:prod.6-1.4.2
    restart: on-failure
    environment:
      - MONGO_URL=mongodb://ucusername:ucpassword@mongodb:27017/db_name?replicaSet=rs0
      - MONGO_OPLOG_URL=mongodb://ucusername:ucpassword@mongodb:27017/local
      - ROOT_URL=http://localhost:8080
      - PORT=8080
      - DEPLOY_METHOD=docker
      - UNIC_SOLID_HOST=http://ucserver:8881
    ports:
      # указать свой порт, на котором будет доступен сервер UnicChat
      - "port:8080"
    networks:
      - unic-chat-free

  uc.media.score:
    image: unicommhub/unicchat_free:sc-1.4.1
    container_name: uc.score
    restart: unless-stopped
    environment:
      - UniComm.Config=/app/sc.config.json
    ports:
      - "8881:80"
      - "4443:443"
    volumes:
      - ./config/sc.config.json:/app/sc.config.json
    networks:
      - unic-chat-free

networks:
  unic-chat-free:
    external: true

```

2. Скачайте в каталог с файлом `unicchat.yml`, каталог `/config/sc.config.json` из раздела `single server install`
3. В файле `sc.config.json` отредактируйте параметры:

```json
    /* адрес mongodb базы UnicChat */
"ConnectionString": "mongodb://ucusername:ucpassword@mongodb:27017/db_name?replicaSet=rs0",
"DataBase": "db_name"
```

4. Запустить контейнер, например, командой `docker-compose -f unicchat.yml up -d`

5. После запуска приложения, вы можете открыть веб-интерфейс приложения по адресу `http://unicchat_server_ip:port`,
   где `unicchat_server_ip` - имя или IP адрес сервера,
   где был запущен UnicChat, `port` - значение параметра, которые вы указали выше.
   Открывайте веб интерфейс с сервера, на котором у вас стоит `.yml` файл серверной части unicchat.
   Если у вас нет браузера с привычном виде (сервер без GUI). Проверте доступ при помощи curl.
   А также посмотрите на логи docker-compose -f unicchat.yml logs -ft`
   ВАЖНО! Если при открытие веб интерфейса с
6. Теперь можно приступить к настройке сервера и создания первого пользователя (перейдите
   на  [Шаг 14. Создание пользователя администратора](#шаг-14-создание-пользователя-администратора)) или  
   настройте прокси сервер и получите сертификат HTTPS, для этого перейдите
   на [Шаг 9. Настройка nginx как Proxy](#шаг-9-настройка-nginx-как-proxy)

<a name="Шаг-7-Зарегистрировать-DNS-запись"></a>

### Шаг 7. Зарегистрировать DNS запись

Производится за рамками данной инструкции, в инструкции показано на примере free.unic.chat

### Шаг 8. Подготовить конфигурацию для сайта на nginx

Проверить что у вас установлен nginx

```shell
 nginx -v
```

Создать файл

```shell
sudo touch /etc/nginx/sites-available/free.unic.chat
```

Активировать конфигурацию

```shell 
sudo ln -s /etc/nginx/sites-available/free.unic.chat /etc/nginx/sites-enabled/free.unic.chat
```

Деактивровать конфигурацию по-умолчанию

```shell 
sudo rm /etc/nginx/sites-enabled/default
```

### Шаг 9. Настройка nginx как Proxy

Для того чтобы сервер приложения не был доступен в Интернет, рекомендуется использовать proxy-сервер, для фильтрации
запросов на сервер приложения.
Мы предлагаем использовать бесплатный сервер nginx с настройкой reverse proxy.
Ниже приведен пример конфигурации. Значения в которые необходимо указать:

- `host` - IP или DNS имя сервера на котором запущен сервер UnicChat;
- `port` - порт на котором запущен сервер UnicChat;
- `domain` - ваш домен, на котором вы будете открывать чат;

Приведенная ниже конфигурация запускает виртуальный сервер, который будет принимать запросы по адресу http://domain и
перенаправлять их на `host:port`, который вы укажете. Это должен быть адрес и порт сервера UnicChat.

```nginx configuration

#пример для domain free.unic.chat c портом 8080
upstream free {
    server 127.0.0.1:8080;
}

# HTTPS Server
server {
    server_name free.unic.chat www.free.unic.chat;

    # You can increase the limit if your need to.
    client_max_body_size 200M;

    error_log /var/log/nginx/unicchat.free.error.log;
    access_log /var/log/nginx/unicchat.free.access.log;

    location / {
        proxy_pass http://free;
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
# certbot certificate 
# если вы не используете https, то закоментируйте  строчки ниже с listen 443 ssl  до ssl_dhparam
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/free.unic.chat/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/free.unic.chat/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot


}

server {
    if ($host = www.free.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    if ($host = free.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

   server_name free.unic.chat www.free.unic.chat;

    listen 80;
#    return 404; # managed by Certbot

}

server {
    if ($host = free.unic.chat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    server_name free.unic.chat www.free.unic.chat;

    listen 80;
    return 404; # managed by Certbot


}
```

### Шаг 10. Получение сертификата Let's Encrypt

Этот пункт нужен, если вам необходим доступ по https

1. Проверьте что у вас установлен certbot
   ```shell apt-cache policy certbot | grep -i Installed ```
2. Сгенерировать новый сертификат

```shell 
sudo certbot certonly -d example.com -d www.example.com  # в случае домена free.unic.chat. free.unic.chat и www.free.unic.chat соответственно 
```

Вам будет предоставлено меню

* 1 Nginx Web Server plugin (nginx)
* 2 Spin up a temporary webserver (standalone)
* 3 Place files in webroot directory (webroot)

Выберите пункт 2

3. Расскоментируйте в строчки в nginx конфигурации в части certbot certificate

### Шаг 11. Запуск nginx

1. Проверить корректность конфигураций

```shell
sudo nginx -t
```

Ответ

```shell
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

2. Перезапустить nginx

```shell
sudo systemctl restart nginx.service
```

### Шаг 12. Проверка работы

1. Провести настройку для обхода работы CORS в приложение, для этого вы базе выполнить:

```spring-mongodb-json
db.rocketchat_settings.updateOne({
  "_id": "Site_Url"
},{"$set": {"value": 'url_address'}})
db.rocketchat_settings.updateOne({"_id": "Site_Url"}, {"$set":{
"packageValue": 'url_address'
}
})

```

2. Для работы без SSL-сертификата от используйте http. Для работы с SSL-сертификатом https.
   Пример для free.unic.chat
   зайдите на вашу базу mongodb. Как в шаге 5

* для http

```spring-mongodb-json
use db_name
db.rocketchat_settings.updateOne({
  "_id": "Site_Url"
},{"$set": {"value": 'http://free.unic.chat'}})
db.rocketchat_settings.updateOne({"_id": "Site_Url"}, {"$set":{
"packageValue": 'http://free.unic.chat'
}
}) 
```

* для https

```spring-mongodb-json
use db_name
db.rocketchat_settings.updateOne({
  "_id": "Site_Url"
},{"$set": {"value": 'https://free.unic.chat'}})
db.rocketchat_settings.updateOne({"_id": "Site_Url"}, {"$set":{
"packageValue": 'https://free.unic.chat'
}
})
```

3. Проверить применение настроек

```spring-mongodb-json
use db_name
db.rocketchat_settings.find({
  "_id": "Site_Url"
})
```

Сайт открывается http://app.unic.chat Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и
cookie браузера, ctrl+R или использовать безопасный режим браузера.

### Шаг 13. Открыть доступы до внутренних ресурсов

#### Входящие соединения на стороне сервера UnicChat:

Открыть порты:

- 8080/TCP - по-умолчанию, сервер запускается на 8080 порту и доступен http://localhost:8080, где localhost - это IP
  адрес сервера UnicChat;
- 443/TCP - порт будет нужен, если вы настроили nginx с сертификатом HTTPS;

#### Исходящие соединения на стороне сервера UnicChat:

* Открыть доступ для Push-шлюза:
    * 443/TCP, на хост **push1.unic.chat**;

* Открыть доступ для ВКС сервера:
    * 443/TCP, на хост **live.unic.chat**;
    * 7881/TCP, 7882/UDP
    * (50000 - 60000)/UDP (диапазон этих портов может быть измененён при развертывании лицензионной версии
      непосредственно владельцем лицензии)

* Открыть доступ до внутренних ресурсов: LDAP, SMTP, DNS при необходимости использования этого функционала

### Шаг 14. Создание пользователя администратора

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

4. После создания пользователя, авторизоваться в веб-интерфейсе с использованием ранее указанных параметров.
5. Для включения пушей, перейти в раздел Администрирование - Push. Включить использование шлюза и указать адрес
   шлюза https://push1.unic.chat
6. Перейти в раздел Администрирование - Organization, убедиться что поля заполнены в соответствии с п.2
7. Настройка завершена.

При первом входе может возникнуть информационное предупреждение
![](./assets/111.jpg "Предупреждение при первом входе")

Нажмите "ДА"

### Шаг 15. Настройка push-уведомлений

Приложение Unicchat работает с внешним push сервером для доставки push-уведомлений в приложение Unicchat на мобильные
устройства.

### Шаг 16. Настройка подключения к SMTP серверу для отправки уведомлений в почту

Раздел в разработке.

### Шаг 17. Настройка подключения к LDAP серверу

Раздел в разработке.

### Шаг 18. Настройка DLP

1. Предварительно загрузите на рабочее место с административным доступом к чату модуль DLP, и создаём канал, доступный
   ответственному за мониторинг DLP пользователю.
   ![DLP Module](https://github.com/unicommorg/unicchat.free/blob/main/8a30dc27-0cfe-4639-8e30-c7efb60c17f4.zip)
2. Главная -> Левая боковая панель, нажимаем на три точки в правой верхней части -> Приложения (установленные)
3. В разделе Установленные приложения -> правая верхняя часть экрана кнопка "Установить приложение" -> Установить из
   файла -> выбрать ранее загруженный zip файл, содержащий DL модуль.
4. Подтверждаем установку приложения модуля.
5. После установки на странице приложения переходим на вкладку Настройки:

- в поле ввода «Moderator Channel" обязательно указываем название канала в который будут отправляться сообщения на
  проверку
- В окне редактирования можно добавить regExp паттерны для проверок (сейчас проверяются банковские карты, номера
  телефонов, ip адреса)

### Быстрый старт. Запуск на одном сервере

Раздел в разработке.

### Быстрый старт. Запуск на двух серверах

Раздел в разработке.

### Настройка отказоустойчивого решения

1. Вы можете поменять политику работы контейнеров. Тогда они будут подниматься в случае если их принудительно не
   остановить. К примеру, они самостоятельно поднимутся после перезагрузки сервера.
   Перейдите в `.yml` файлы ваших сервисов и поставьте значение restart: always

### Установка локального медиа сервера для ВКС

Для работы ВКС приложение Unicchat использует медиа сервер установленный в облаке компании Unicomm. Пользователи
самостоятельно, для обеспечения большей безопасности или индивидуальной конфигурации для высоконагруженых ВКС, могут
установить и сконфигурировать медиа-сервер внутри своей организации.
Установка и настройка медиа-сервера включает шаги:

- Регистрация доменов для медиа-сервера;
- Запуск `redis` и `caddy`;
- Запуск медиа-сервера;
- Запуск компоненты медиа-сервера для управления потоком вещания;
- Настройка приложения Unicchat для работы с медиа-сервером;

#### Регистрация домена для медиа-сервера

Для корректной работы ВКС с приложением на мобильных устройствах необходимо обеспечить доступность сервера на котором
будет установлен медиа сервера в Интернет и зарегистрировать домены для сервера:

- media-server.your_domain;
- turn.media-server.your_domain;
- whip.media-server.your_domain

#### Запуск медиа-сервера

Запуск медиа-сервера включает в себя:

- Запуск redis;
- Запуск caddy;
- Запуск media server;
- Запуск media server egress;

##### Запуск redis

1. Загрузите файл `unicchat.media.server.free/redis.yml` и разместите на сервере, где будет установлен медиа-сервер.
2. Запустите контейнер `redis` командой `docker-compose -f redis.yml up -d`.
3. Для работы `redis` должен быть разрешен порт 6379/tcp.

##### Запуск caddy

1. Загрузите файл `unicchat.media.server.free/caddy.yml` и разместите на сервере, где будет установлен медиа-сервер.
2. В этом каталоге, создайте папку `config` и сохраните туда файл
   конфигурации `unicchat.media.server.free/config/caddy.yaml`.
3. Отредактируйте файл `./config/caddy.yaml` указав ваши названия доменов в файле. У вас должно быть зарегистрировано 3
   домена для работы медиа-сервера

* **media-server.your_domain** - основной домен,
* **turn.media-server.your_domain** и **whip.media-server.your_domain** - дополнительные домены.

```yaml
logging:
  logs:
    default:
      level: INFO
storage:
  "module": "file_system"
  "root": "/data"
apps:
  tls:
    certificates:
      automate:
        - media-server.your_domain
        - turn.media-server.your_domain
        - whip.media-server.your_domain
  layer4:
    servers:
      main:
        listen: [ ":443" ]
        routes:
          - match:
              - tls:
                  sni:
                    - "turn.media-server.your_domain"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: [ "media-server.your_domain:5349" ]
          - match:
              - tls:
                  sni:
                    - "media-server.your_domain"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: [ "http/1.1" ]
              - handler: proxy
                upstreams:
                  - dial: [ "media-server.your_domain:7880" ]
          - match:
              - tls:
                  sni:
                    - "whip.media-server.your_domain"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: [ "http/1.1" ]
              - handler: proxy
                upstreams:
                  - dial: [ "media-server.your_domain:8080" ]
```

4. Разрешите на вашем firewall доступ к медиа-серверу по портам:

* 443/tcp
* 8080/tcp
* 7880/tcp, 7881/tcp, 7882/udp
* 5349/tcp, 3478/udp

5. Запустите контейнер `caddy` командой `docker-compose -f caddy.yml up -d`.
6. Важно, сервис самостоятельно получит сертификаты с LetsEncrypt. Запускайте когда вы делегировали основной и
   вспомогательные домены и открыли 443/tcp порт на firewall.

##### Запуск медиа-сервера

1. Загрузите файл `unicchat.media.server.free/unicchat.media.server.yml` и разместите на сервере, где будет установлен
   медиа-сервер.
2. В этом каталоге, создайте папку `config` и сохраните туда файл
   конфигурации `unicchat.media.server.free/config/server.yaml`.
3. Отредактируйте файл `./config/server.yaml`, для этого заполните параметры в файле:

* `{domain}` - название вашего домена;
* `{keys}` - укажите вашу пару ключ-секрет в формате `key:secret` или воспользуйтесь предложенной. Длина строки `secret`
  должна быть не менее 32 символов;

```yaml
log_level: info
port: 7880
bind_addresses:
  - ""
rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
  enable_loopback_candidate: false
redis:
  address: localhost:6379
  username: ""
  password: ""
  db: 0
  use_tls: false
  sentinel_master_name: ""
  sentinel_username: ""
  sentinel_password: ""
  sentinel_addresses: [ ]
  cluster_addresses: [ ]
  max_redirects: null
turn:
  enabled: true
  domain: turn.media-server.your_domain
  tls_port: 5349
  udp_port: 3478
  external_tls: true
keys:
  gs528shsa3gGFFD: jshGshsil2439dxznHGSOPWIjnxb27e02nzak238iHSHw32i9o
```

Запустите контейнер медиа-сервера командой `docker-compose -f unicchat.media.server.yml up -d`

#### Запуск egress для медиа-сервера

1. Загрузите файл `unicchat.media.server.free/unicchat.media.server.egress.yml` и разместите на сервере, где будет
   установлен медиа-сервер.
2. В этом каталоге, создайте папку `config` и сохраните туда файл
   конфигурации `unicchat.media.server.free/config/egress.yaml`.
3. Отредактируйте файл `./config/egress.yaml`, для этого заполните параметры:

* `{ws_url}` - укажите название вашего домена;
* `{api_key}` - укажите ваш ключ или воспользуйтесь предложенным. Указанное значение должно совпадать со значением `key`
  указанным в файле `unicchat.media.server.free/config/server.yaml`;
* `{api_secret}` - укажите ваш секрет или воспользуйтесь предложенным. Указанное значение должно совпадать со
  значением `secret` указанным в файле `unicchat.media.server.free/config/server.yaml`;

```yaml
redis:
  address: localhost:6379
  username: ""
  password: ""
  db: 0
  use_tls: false
  sentinel_master_name: ""
  sentinel_username: ""
  sentinel_password: ""
  sentinel_addresses: [ ]
  cluster_addresses: [ ]
  max_redirects: null
log_level: info
api_key: gs528shsa3gGFFD
api_secret: jshGshsil2439dxznHGSOPWIjnxb27e02nzak238iHSHw32i9o
ws_url: wss://media-server.your_domain
insecure: true
```

Запустите контейнер egress, командой `docker-compose -f unicchat.media.server.egress.yml up -d`.

#### Настройка приложения Unicchat для работы с медиа-сервером

В интерфейсе приложения Unicchat, в разделе **Администрирование** - **Настройки** - **Видеоконференция** заполнить
параметры для подключения к медиа серверу:

* **URL для подключения** - адрес для подключения к медиа серверу, параметр `{ws_url}` из
  файла `unicchat.media.server.free/config/egress.yaml`. В примере - `wss://media-server.your_domain`.
* **API key** - ключ для подключения к медиа серверу, параметр `{api_key}` из
  файла `unicchat.media.server.free/config/egress.yaml`. В примере - `gs528shsa3gGFFD`.
* **API secret** - секрет для подключения к медиа серверу, параметр `{api_secret}` из
  файла `unicchat.media.server.free/config/egress.yaml`. В
  примере - `jshGshsil2439dxznHGSOPWIjnxb27e02nzak238iHSHw32i9o`.

### Частые проблемы при установке

Раздел в разработке.

### Клиентские приложения

* [Репозитории клиентских приложений]
* Android: (https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat&pcampaignid=web_share)
* iOS: (https://apps.apple.com/ru/app/unicchat/id1665533885)
* Desktop:  (https://github.com/unicommorg/unic.chat.desktop.releases/releases)

### Частые проблемы при установке

Раздел в разработке.

### Клиентские приложения

* [Репозитории клиентских приложений]
* Android: (https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat&pcampaignid=web_share)
* iOS: (https://apps.apple.com/ru/app/unicchat/id1665533885)
* Desktop:  (https://github.com/unicommorg/unic.chat.desktop.releases/releases)
