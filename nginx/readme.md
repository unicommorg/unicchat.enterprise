<<<<<<< HEAD
## Настройка nginx как proxy для Unicchat

### Шаг 1. Установить nginx

Для Установки воспользоваться данной инструкцией: https://help.reg.ru/support/servery-vps/oblachnyye-servery/ustanovka-programmnogo-obespecheniya/kak-ustanovit-linux-nginx-mysql-php-lemp-v-ubuntu-18-04-20-04#2

### Шаг 2. Зарегистрировать DNS запись

Производится за рамками данной инструкции, в инструкции показано на примере app.unic.chat 

### Шаг 3. Настроить сайт для Unicchat

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

### Шаг 4. Подготовка сайта nginx 

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

### Шаг 5. Проверка работы 

Провести настойку для обхода работы CORS в приложение, для этого вы базе выполнить:

```
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":'http://app.unic.chat'}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":'http://app.unic.chat'}})
```

Сайт открывается http://app.unic.chat 
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.

### Шаг 6. Установка certbot и получение сертификата

Установить certbot по этой инструкции: https://certbot.eff.org/instructions?ws=nginx&os=debianbuster

Выполнить получение сертфикатов для необходимых доменов: 
```shell
sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d www.app.unic.chat -d app.unic.chat -v
sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d www.app-api.unic.chat -d app-api.unic.chat -v
``` 

### Шаг 7. Настройка автоматической проверки сертификата certbot

Добавить правила проверки сертификата, например, в 7-00 каждый день, в `/etc/cron.daily/certbot`

`00 7 * * * certbot renew --post-hook "systemctl reload nginx"`

### Шаг 8. Настройка Unicchat для работы с HTTPS

Провести настойку для обхода работы CORS в приложение для HTTPS, для этого вы базе выполнить:

```
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"value":'https://app.unic.chat'}})
db.rocketchat_settings.updateOne({"_id":"Site_Url"},{"$set":{"packageValue":'https://app.unic.chat'}})
```

Сайт открывается https://app.unic.chat
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.
