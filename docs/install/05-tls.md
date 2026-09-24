# TLS и nginx

Три имени (`APP_SERVER_NAME`, `DOCUMENTSERVER_SERVER_NAME`, `MINIO_SERVER_NAME`) должны открываться по HTTPS с сертификатом доверенного удостоверяющего центра. Самоподписанный сертификат годится только для теста, где корневой сертификат заранее установлен на все клиентские устройства. Мобильные клиенты его иначе отклонят.

Каталог `./certs` в контейнере виден как `/certs`. Пути задают переменные `SSL_CERT`, `SSL_KEY`, `DOCUMENTSERVER_SSL_*`, `MINIO_SSL_*`.

## Где заканчивается TLS

| Способ | Когда | Что запускать |
|--------|-------|----------------|
| Let's Encrypt HTTP-01 | Имена смотрят на этот сервер, порты 80 и 443 свободны | Certbot и `unicchat-nginx` |
| Let's Encrypt DNS-01 | Порт 80 из интернета закрыт | Certbot и `unicchat-nginx` |
| Файлы своего или коммерческого УЦ | Сертификат уже выпущен | только `unicchat-nginx` |
| Nginx на хосте | Веб-сервер уже настроен | ни Certbot, ни `unicchat-nginx` |
| Балансировщик перед сервером | TLS снаружи | ни Certbot, ни `unicchat-nginx` |

В контейнере `unicchat-nginx` TLS заканчивается на nginx. Дальше трафик идёт по HTTP на AppServer, DocumentServer и MinIO.

Сертификат должен покрывать имя, которым пользуются клиенты (SAN или точное CN). Для трёх имён — три сертификата или один SAN/wildcard на все три.

## Let's Encrypt HTTP-01

```shell
cd ~/unicchat.enterprise/multi-server-install
set -a && . ./.env && set +a
mkdir -p certs/config certs/logs certs/work

run_cert() {
  docker run --rm \
    -p 80:80 \
    -v "$(pwd)/certs/config:/etc/letsencrypt" \
    -v "$(pwd)/certs/logs:/var/log/letsencrypt" \
    -v "$(pwd)/certs/work:/var/lib/letsencrypt" \
    certbot/certbot certonly --standalone \
    --agree-tos --register-unsafely-without-email --non-interactive \
    -d "$1"
}

run_cert "$APP_SERVER_NAME"
run_cert "$DOCUMENTSERVER_SERVER_NAME"
run_cert "$MINIO_SERVER_NAME"
```

Продление (nginx на время остановите, порт 80 нужен Certbot):

```shell
docker compose stop unicchat-nginx
docker run --rm \
  -p 80:80 \
  -v "$(pwd)/certs/config:/etc/letsencrypt" \
  -v "$(pwd)/certs/logs:/var/log/letsencrypt" \
  -v "$(pwd)/certs/work:/var/lib/letsencrypt" \
  certbot/certbot renew --non-interactive
docker compose start unicchat-nginx
```

На роли Nginx те же команды с `-f compose.nginx.yml`.

## Let's Encrypt DNS-01

```shell
docker run --rm -it \
  -v "$(pwd)/certs/config:/etc/letsencrypt" \
  -v "$(pwd)/certs/logs:/var/log/letsencrypt" \
  -v "$(pwd)/certs/work:/var/lib/letsencrypt" \
  certbot/certbot certonly --manual --preferred-challenges dns \
  --agree-tos --register-unsafely-without-email \
  -d "$APP_SERVER_NAME" -d "$DOCUMENTSERVER_SERVER_NAME" -d "$MINIO_SERVER_NAME"
```

Создайте TXT `_acme-challenge` для каждого имени. Получится один сертификат. Укажите его путь во всех трёх парах `SSL_*`. Ручной режим не продлевается сам: для автоматического продления используйте плагин Certbot вашего DNS.

## Готовые файлы

1. Выпустите сертификат у своего УЦ. Приватный ключ с сервера не отправляйте.
2. Соберите `fullchain.pem`: сертификат сервера, затем промежуточные.
3. Положите `fullchain.pem` и `privkey.pem` в `certs/config/live/<домен>/`.
4. Проверьте совпадение ключа и сертификата:

```shell
openssl x509 -noout -modulus -in certs/config/live/<домен>/fullchain.pem | openssl md5
openssl rsa  -noout -modulus -in certs/config/live/<домен>/privkey.pem  | openssl md5
```

Суммы должны совпасть. Без промежуточных сертификатов браузер может открыть сайт, а мобильный клиент — нет.

Корневой сертификат внутреннего УЦ установите на рабочие станции и телефоны заранее.

После замены файлов:

```shell
docker compose up -d --force-recreate nginx-config-init unicchat-nginx
```

## Свой nginx или балансировщик

Контейнер `unicchat-nginx` не запускайте. Проксируйте:

| Имя | Куда | Что это |
|-----|------|---------|
| `APP_SERVER_NAME` | `http://<AppServer>:8080` | Приложение |
| `DOCUMENTSERVER_SERVER_NAME` | `http://<Knowledgebase>:8880` | DocumentServer |
| `MINIO_SERVER_NAME` | `http://<MinIO>:9000` | S3 |

Порт 80 — редирект на 443. Примеры: `multi-server-install/nginx/examples/host/`.

Обязательно:

- на AppServer: `proxy_http_version 1.1`, заголовки `Upgrade` и `Connection "upgrade"`, `client_max_body_size 100M`;
- `Host` и `X-Forwarded-Proto` на всех трёх именах;
- на DocumentServer ещё `X-Forwarded-Host` и `X-Forwarded-Port 443`;
- на MinIO: `client_max_body_size 0`, `proxy_buffering off`, `proxy_request_buffering off`;
- `ROOT_URL` в `.env` равен внешнему `https://<APP_SERVER_NAME>`.

Переменные `SSL_*` в этом варианте не читаются. Снаружи оставьте 80/tcp и 443/tcp. Остальные порты — только между серверами установки, см. [сеть](04-network.md).

## Контейнерный nginx

Шаблоны `nginx/templates/` попадают в `nginx/conf.d/`:

| Файл | Домен |
|------|--------|
| `00-app.conf` | `APP_SERVER_NAME` |
| `10-documentserver.conf` | `DOCUMENTSERVER_SERVER_NAME` |
| `20-minio.conf` | `MINIO_SERVER_NAME` |

Правки держите в шаблонах и в `.env`, затем пересоздайте `nginx-config-init` и `unicchat-nginx`.
