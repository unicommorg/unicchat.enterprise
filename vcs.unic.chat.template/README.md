# Установка LiveKit, Coturn и Nginx

Ниже приведён пример развёртывания LiveKit, Coturn, Redis, Nginx и
опционального LiveKit Egress на одном Linux-сервере через Docker Compose.
Nginx завершает TLS и проксирует HTTPS/WSS-запросы в LiveKit. Все сервисы
работают в контейнерах.

> Все адреса и секреты в репозитории являются примерами. Домен
> `example.com` и IP-адрес `203.0.113.10` зарезервированы для документации и
> не будут работать в реальной установке.

## 1. Требования

- Linux-сервер с публичным статическим IPv4-адресом;
- Ubuntu 22.04/24.04 или другой дистрибутив с Docker Engine;
- минимум 2 CPU и 4 ГБ RAM без Egress;
- два DNS-имени, направленных на один сервер:
  - `livekit.example.com` — API и WebSocket LiveKit;
  - `turn.example.com` — Coturn;
- готовый TLS-сертификат и приватный ключ;
- доступ с правами `sudo`.

Docker Compose использует `network_mode: host`, поэтому эту конфигурацию
нужно запускать на Linux. На Docker Desktop для Windows и macOS она работать
корректно не будет.

## 2. DNS и сетевые порты

Создайте две A-записи:

| Имя | Тип | Пример значения |
| --- | --- | --- |
| `livekit.example.com` | A | `203.0.113.10` |
| `turn.example.com` | A | `203.0.113.10` |

Откройте входящие порты в облачном firewall и на самом сервере:

| Порт | Протокол | Назначение |
| --- | --- | --- |
| 80, 443 | TCP | HTTP-редирект и LiveKit HTTPS/WSS через Nginx |
| 7881 | TCP | WebRTC через TCP |
| 50000–60000 | UDP | WebRTC LiveKit |
| 3478 | UDP/TCP | STUN/TURN |
| 5349 | TCP | TURN over TLS |
| 30000–40000 | UDP | relay-трафик Coturn |

Порты LiveKit `7880` и Redis `6379` наружу открывать не нужно.

Пример для UFW:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 7881/tcp
sudo ufw allow 3478/udp
sudo ufw allow 3478/tcp
sudo ufw allow 5349/tcp
sudo ufw allow 30000:40000/udp
sudo ufw allow 50000:60000/udp
sudo ufw enable
```

Не включайте UFW до открытия SSH-порта, если подключены к серверу удалённо.

## 3. Установка Docker

Установите Docker Engine и Compose Plugin по
[официальной инструкции Docker](https://docs.docker.com/engine/install/ubuntu/).
После установки проверьте:

```bash
sudo docker version
sudo docker compose version
```

Скопируйте содержимое репозитория на сервер, например в
`/opt/livekit-coturn`, и перейдите в каталог:

```bash
cd /opt/livekit-coturn
```

Nginx и Coturn отдельно устанавливать на сервер не нужно: Docker Compose
загрузит их образы автоматически.

## 4. Настройка значений

Получите адреса сетевого интерфейса:

```bash
ip -4 addr
curl -4 https://ifconfig.me
```

Сгенерируйте три независимых значения:

```bash
openssl rand -hex 12
openssl rand -hex 32
openssl rand -hex 32
```

Используйте первое значение как ключ LiveKit, второе — как секрет LiveKit,
третье — как общий секрет Coturn. Не используйте примерные значения из
репозитория в рабочей среде.

Замените значения во всех указанных файлах:

| Значение-пример | На что заменить | Файлы |
| --- | --- | --- |
| `livekit.example.com` | домен LiveKit | `vcs.yaml`, `egress.yaml`, `nginx.conf` |
| `turn.example.com` | домен Coturn | `vcs.yaml`, `turnserver.conf` |
| `203.0.113.10` | публичный IP сервера | `vcs.yaml`, `turnserver.conf` |
| `192.168.1.10` | локальный IP интерфейса сервера | `turnserver.conf` |
| `example-api-key` | ключ LiveKit | `vcs.yaml`, `egress.yaml` |
| `example-livekit-api-secret-change-me` | секрет LiveKit | `vcs.yaml`, `egress.yaml` |
| `example-turn-shared-secret-change-me` | общий секрет TURN | `vcs.yaml`, `turnserver.conf`, `turn-shared-secret` |

Ключ и секрет в секции `keys` файла `vcs.yaml` должны точно совпадать с
`api_key` и `api_secret` в `egress.yaml`. Секрет TURN должен точно совпадать
во всех трёх местах.

Конфигурация `turnserver.conf` показывает случай, когда сервер находится за
NAT:

```ini
listening-ip=192.168.1.10
relay-ip=192.168.1.10
external-ip=203.0.113.10/192.168.1.10
```

Если публичный IP назначен непосредственно сетевому интерфейсу, укажите его
в `listening-ip`, `relay-ip` и `external-ip` без части `/локальный-IP`.

## 5. Добавление TLS-сертификатов

Создайте каталог `certs` рядом с `docker-compose.yaml`:

```bash
mkdir -p certs
```

Добавьте в него два PEM-файла:

```text
certs/
├── fullchain.pem
└── privkey.pem
```

- `fullchain.pem` — сертификат вместе с промежуточными сертификатами;
- `privkey.pem` — соответствующий приватный ключ без парольной защиты.

Один комплект используется контейнерами Nginx и Coturn. Сертификат должен
быть действителен сразу для `livekit.example.com` и `turn.example.com`,
например содержать оба имени в Subject Alternative Name. Если сертификаты
для доменов разные, потребуется использовать отдельные файлы и изменить пути
в `nginx.conf` и `turnserver.conf`.

Ограничьте доступ к приватному ключу:

```bash
chmod 755 certs
chmod 644 certs/fullchain.pem
chmod 600 certs/privkey.pem
```

Проверьте сертификат перед запуском:

```bash
openssl x509 \
  -in certs/fullchain.pem \
  -noout \
  -subject \
  -issuer \
  -dates \
  -ext subjectAltName
```

Каталог `certs` добавлен в `.gitignore`, поэтому сертификаты и приватный ключ
не попадут в Git.

При обновлении сертификата замените оба файла и перезапустите использующие
их контейнеры:

```bash
sudo docker compose restart nginx coturn
```

## 6. Запуск

Проверьте итоговую конфигурацию и загрузите образы:

```bash
sudo docker compose config
sudo docker compose pull
```

Запустите весь стек:

```bash
sudo docker compose up -d
sudo docker compose ps
```

Egress нужен только для записи и трансляции. Если эта возможность не нужна,
запустите Nginx, Coturn, LiveKit и Redis без Egress:

```bash
sudo docker compose up -d nginx coturn vcs redis
```

Egress запускает Chromium и требует заметно больше CPU/RAM. Его ключи в
`egress.yaml` должны совпадать с ключами LiveKit.

## 7. Проверка

Посмотрите журналы:

```bash
sudo docker compose logs --tail=100 nginx
sudo docker compose logs --tail=100 vcs
sudo docker compose logs --tail=100 coturn
sudo docker compose logs --tail=100 redis
sudo docker compose logs --tail=100 egress
```

Проверьте HTTPS LiveKit:

```bash
curl -I https://livekit.example.com
```

Проверьте TLS Coturn:

```bash
openssl s_client \
  -connect turn.example.com:5349 \
  -servername turn.example.com
```

В выводе не должно быть ошибок проверки цепочки сертификатов. Финальную
проверку аудио и видео выполняйте из внешней сети: клиент должен подключаться
к `wss://livekit.example.com`, а при блокировке прямого UDP — переходить на
Coturn.

## Обновление контейнеров

Версии образов закреплены в `docker-compose.yaml`. Для обновления сначала
изучите release notes, измените теги образов, затем выполните:

```bash
sudo docker compose pull
sudo docker compose up -d
```
