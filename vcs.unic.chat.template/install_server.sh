#!/bin/sh
# run this script

# Проверяем наличие файла .env
if [ ! -f .env ]; then
  echo "Файл .env не найден!"
  exit 1
fi

# Считываем переменные из файла .env
export $(grep -v '^#' .env | xargs)

# Проверяем, что переменная DIR задана
if [ -z "$VCS_URL" ] && [ -z "$VCS_TURN_URL" ] && [ -z "$VCS_WHIP_URL" ]; then
  echo "Переменная окружения VCS_URL | VCS_WHIP_URL | VCS_TURN_URL не задана в .env!"
  exit 1
fi



# create directories for vcs
mkdir -p ./unicomm-vcs/caddy_data

# vcs config
cat << EOF > ./unicomm-vcs/vcs.yaml
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
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
turn:
    enabled: true
    domain: $VCS_TURN_URL
    tls_port: 5349
    udp_port: 3478
    external_tls: true
keys:
    APIFB6qLxKJDW7T: 1jH9vBVaFfBwMXDaBcjkQG8d6z5GBhUowsz2VhiDoqe

EOF

# caddy config
cat << EOF > ./unicomm-vcs/caddy.yaml
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
        - $VCS_URL
        - $VCS_TURN_URL
#        - $VCS_WHIP_URL
  layer4:
    servers:
      main:
        listen: [":443"]
        routes:
          - match:
            - tls:
                sni:
                  - "$VCS_TURN_URL"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: ["localhost:5349"]
          - match:
              - tls:
                  sni:
                    - "$VCS_URL"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: ["http/1.1"]
              - handler: proxy
                upstreams:
                  - dial: ["localhost:7880"]
#          - match:
#              - tls:
#                  sni:
#                    - "$VCS_WHIP_URL"
#            handle:
#              - handler: tls
#                connection_policies:
#                  - alpn: ["http/1.1"]
#              - handler: proxy
#                upstreams:
#                  - dial: ["localhost:8080"]


EOF

# update ip script
cat << "EOF" > ./unicomm-vcs/update_ip.sh
#!/usr/bin/env bash
ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -1|cut -d" " -f6|cut -d/ -f1`
sed -i.orig -r "s/\\\"(.+)(\:5349)/\\\"$ip\2/" ./unicomm-vcs/caddy.yaml


EOF

# docker compose
cat << EOF > ./unicomm-vcs/docker-compose.yaml
# This docker-compose requires host networking, which is only available on Linux
# This compose will not function correctly on Mac or Windows
services:
  caddy:
    image: livekit/caddyl4:latest
    command: run --config /etc/caddy.yaml --adapter yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./caddy.yaml:/etc/caddy.yaml
      - ./caddy_data:/data
  vcs:
    image: livekit/livekit-server:v1.7.2
    command: --config /etc/livekit.yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./vcs.yaml:/etc/livekit.yaml
  redis:
    image: redis:7.4.1-alpine
    command: redis-server /etc/redis.conf
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./redis.conf:/etc/redis.conf
  egress:
    image: livekit/egress:latest
    restart: unless-stopped
    environment:
      - EGRESS_CONFIG_FILE=/etc/egress.yaml
    network_mode: "host"
    volumes:
      - ./egress.yaml:/etc/egress.yaml
    cap_add:
      - CAP_SYS_ADMIN

EOF

# redis config
cat << EOF > ./unicomm-vcs/redis.conf
bind 127.0.0.1 ::1
protected-mode yes
port 6379
timeout 0
tcp-keepalive 300


EOF
# egress config
cat << EOF > ./unicomm-vcs/egress.yaml
redis:
    address: localhost:6379
    username: ""
    password: ""
    db: 0
    use_tls: false
    sentinel_master_name: ""
    sentinel_username: ""
    sentinel_password: ""
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
api_key: APIFB6qLxKJDW7T
api_secret: 1jH9vBVaFfBwMXDaBcjkQG8d6z5GBhUowsz2VhiDoqe
ws_url: wss://$VCS_URL

EOF


chmod a+x ./unicomm-vcs/update_ip.sh
./unicomm-vcs/update_ip.sh

