# Host nginx + Certbot (вариант B)

Встроенный контейнер `unicchat-nginx` не используется. TLS и reverse proxy — nginx и certbot на хосте или на отдельной edge-VM.

Шаблоны ниже рассчитаны на **тот же хост**, что и Docker: `proxy_pass` на `127.0.0.1`. Если nginx на другой машине, замените `127.0.0.1` на IP app-хоста (и для MinIO/DocumentServer — на IP KB-хоста в варианте C/D).

Порты, которые публикует `compose.external-nginx.yml` / `compose.kb-host.yml`:

| Сервис | Host port | Upstream в примерах |
|--------|-----------|---------------------|
| AppServer | 3000 | `http://127.0.0.1:3000` |
| DocumentServer | 8081 | `http://127.0.0.1:8081` |
| MinIO S3 | 9000 | `http://127.0.0.1:9000` |

## Установка nginx и certbot (Ubuntu)

```shell
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

Порты 80 и 443 на этой машине должны быть свободны (контейнер `unicchat-nginx` не запущен).

```shell
sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
sudo cp 00-app.conf /etc/nginx/sites-available/unicchat-app.conf
sudo cp 10-documentserver.conf /etc/nginx/sites-available/unicchat-documentserver.conf
sudo cp 20-minio.conf /etc/nginx/sites-available/unicchat-minio.conf
```

В каждом файле замените `app.example.com` / `documentserver.example.com` / `minio.example.com` на значения из `.env` (`APP_SERVER_NAME`, `DOCUMENTSERVER_SERVER_NAME`, `MINIO_SERVER_NAME`). Пока сертификатов нет, оставьте только `listen 80` (блоки `listen 443` закомментированы в примерах до первого certbot).

```shell
sudo ln -sf /etc/nginx/sites-available/unicchat-app.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/unicchat-documentserver.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/unicchat-minio.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Сертификаты

A-записи трёх имён должны указывать на **этот** edge-хост. Выпуск HTTP-01:

```shell
sudo certbot --nginx \
  -d app.example.com \
  -d documentserver.example.com \
  -d minio.example.com
```

Либо по одному домену, если нужны отдельные сертификаты (как во встроенном nginx):

```shell
sudo certbot --nginx -d app.example.com
sudo certbot --nginx -d documentserver.example.com
sudo certbot --nginx -d minio.example.com
```

Certbot сам допишет `ssl_certificate` / `ssl_certificate_key` и редирект HTTP→HTTPS. Продление — `certbot.timer` в systemd, **стек Docker останавливать не нужно**.

Проверка:

```shell
sudo nginx -t
sudo systemctl reload nginx
curl -sI "http://app.example.com"
curl -skI "https://app.example.com"
```
