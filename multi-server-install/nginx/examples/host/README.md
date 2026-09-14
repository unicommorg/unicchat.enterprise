# Host nginx + Certbot

Если TLS терминирует ваш nginx (не контейнер `unicchat-nginx`), используйте эти vhost’ы.

`proxy_pass` ниже рассчитан на тот же хост, что и Docker (`127.0.0.1`). Если nginx на другой машине — подставьте IP серверов AppServer / Knowledgebase / MinIO.

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

Порты 80 и 443 должны быть свободны (контейнер `unicchat-nginx` не запущен).

```shell
sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
sudo cp 00-app.conf /etc/nginx/sites-available/unicchat-app.conf
sudo cp 10-documentserver.conf /etc/nginx/sites-available/unicchat-documentserver.conf
sudo cp 20-minio.conf /etc/nginx/sites-available/unicchat-minio.conf
```

Замените `app.example.com` / `documentserver.example.com` / `minio.example.com` на значения из `.env`.

```shell
sudo ln -sf /etc/nginx/sites-available/unicchat-app.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/unicchat-documentserver.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/unicchat-minio.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Сертификаты

```shell
sudo certbot --nginx -d app.example.com
sudo certbot --nginx -d documentserver.example.com
sudo certbot --nginx -d minio.example.com
```

Продление — `certbot.timer`, стек Docker останавливать не нужно.
