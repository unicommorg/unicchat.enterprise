# Локальный ВКС (LiveKit и Coturn)

Ставьте медиасервер на отдельный Linux-хост, не на сервер UnicChat. Стек лежит в каталоге [`vcs.unic.chat.template/`](../../vcs.unic.chat.template/).

Пошаговая настройка доменов, секретов, сертификатов и запуск — в [`vcs.unic.chat.template/README.md`](../../vcs.unic.chat.template/README.md).

Старые скрипты `install_server.sh` и Caddy в этот каталог больше не входят. Их заменил Docker Compose: nginx, Coturn, LiveKit, Redis и необязательный Egress. Все сервисы в `network_mode: host`, поэтому хост должен быть Linux. Docker Desktop на Windows и macOS этот файл не поднимет корректно.

## Когда выбирать локальный контур

- Звонки не должны уходить на `lk-yc.unic.chat`.
- Нужны свои DNS-имена и свой TURN.

Внешний шлюз в этом случае не используйте. Сравнение — в [внешнем ВКС](11-vcs-external.md).

## Порты этого хоста, не сервера UnicChat

| Порт | Протокол | Назначение | Required |
|------|----------|------------|----------|
| 80, 443 | TCP | HTTPS/WSS LiveKit через nginx | Required |
| 7881 | TCP | WebRTC TCP | Required |
| 50000–60000 | UDP | Медиа LiveKit | Required |
| 3478 | UDP и TCP | STUN/TURN | Required |
| 5349 | TCP | TURN over TLS | Required |
| 30000–40000 | UDP | Relay Coturn | Required |

Порты LiveKit `7880` и Redis `6379` наружу не открывайте: сервисы слушают localhost на этом же хосте.

На сервере UnicChat эти порты не открывайте.

## Связка с UnicChat

1. Поднимите стек по README каталога шаблона.
2. В клиентских настройках ВКС укажите `wss://<ваш livekit-домен>`.
3. Проверьте звонок из внешней сети. Если прямой UDP закрыт, клиент должен уйти на Coturn.

Секреты LiveKit и общий секрет TURN задаются в файлах шаблона (`vcs.yaml`, `turnserver.conf`, `egress.yaml`). Примерные значения `example-` в работу не оставляйте.
