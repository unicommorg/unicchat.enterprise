## Шаг 1. Установка  медиа сервера для ВКС
Установка идёт на отдельном сервере от UnicChat
<!-- TOC --><a name="31-"></a>
### 1.1 Порядок установки сервера

Перейдите в директорию vcs.unic.chat.template:
```shell
cd vcs.unic.chat.template
```

#### 1.1.1 Установка на публичном VPS сервере
1. В файле `.env` указать домены на которых будет работать ВКС сервер. WHIP пока не обязателен и его можно пропустить.
2. Запустить `./install_server.sh` (возможно, на последнюю операцию в файле нужно sudo). Перед запуском убедиться, что в директории, где запускается скрипт, есть файл `.env`. Сервер будет установлен в текущей поддиректории `./unicomm-vcs`.
3. Если на сервере отсутствует docker, то выполнить скрипт под sudo `./install_docker.sh` (только для Ubuntu) или иным способом установить docker compose.
4. В файле ./unicomm-vcs/egress.yaml при необходимости отредактируйте значения api_key и api_secret
```yml
api_key: 
api_secret: 
ws_url: wss://
```

5. Запустите медиасервер командой `docker compose -f ./unicomm-vcs/docker-compose.yml up -d`.


<!-- TOC --><a name="32-"></a>
### 3.2 Проверка открытия портов


<!-- TOC --><a name="--19"></a>
#### Обязательные порты

<!-- TOC --><a name="tcp-"></a>
##### TCP порты:
- **7880** - Основной порт для клиентских подключений
- **7881** - Health checks и метрики (можно ограничить внутренней сетью)

<!-- TOC --><a name="udp-"></a>
##### UDP порты:
- **3478** - STUN/TURN сервер для NAT traversal
- **50000-60000** - Диапазон для медиа трафика WebRTC

<!-- TOC --><a name="--20"></a>
##### Опциональные порты
- **5349** - WebRTC over TLS (если нужен HTTPS для WebRTC)

Проверка портов:
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
