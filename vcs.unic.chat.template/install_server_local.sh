#!/bin/sh
set -e

if [ ! -f local.env ]; then
  echo "local.env не найден"
  exit 1
fi

export $(grep -v '^#' local.env | xargs)

if [ -z "$VCS_URL" ] || [ -z "$VCS_LAN_IP" ] || [ -z "$VCS_API_KEY" ] || [ -z "$VCS_API_SECRET" ]; then
  echo "Нужно задать VCS_URL, VCS_LAN_IP, VCS_API_KEY, VCS_API_SECRET"
  exit 1
fi

RTC_PORT_START="${RTC_PORT_START:-50000}"
RTC_PORT_END="${RTC_PORT_END:-60000}"

BASE_DIR="$(pwd)/unicomm-vcs"
TLS_DIR="$BASE_DIR/tls"
DATA_DIR="$BASE_DIR/caddy_data"

mkdir -p "$TLS_DIR" "$DATA_DIR"

command -v openssl >/dev/null || { echo "openssl не установлен"; exit 1; }
command -v docker >/dev/null || { echo "docker не установлен"; exit 1; }

echo "=== Генерация CA ==="

if [ ! -f "$TLS_DIR/ca.crt" ]; then
  openssl genrsa -out "$TLS_DIR/ca.key" 4096
  openssl req -x509 -new -nodes -key "$TLS_DIR/ca.key" \
    -sha256 -days 3650 \
    -subj "/CN=VCS-LOCAL-CA" \
    -out "$TLS_DIR/ca.crt"
fi

echo "=== Выпуск сертификата для $VCS_URL ==="

if [ ! -f "$TLS_DIR/$VCS_URL.crt" ]; then
  openssl genrsa -out "$TLS_DIR/$VCS_URL.key" 2048
  openssl req -new -key "$TLS_DIR/$VCS_URL.key" \
    -subj "/CN=$VCS_URL" \
    -out "$TLS_DIR/$VCS_URL.csr"

  cat > "$TLS_DIR/ext.cnf" <<EOF
subjectAltName = DNS:$VCS_URL
extendedKeyUsage = serverAuth
EOF

  openssl x509 -req -in "$TLS_DIR/$VCS_URL.csr" \
    -CA "$TLS_DIR/ca.crt" \
    -CAkey "$TLS_DIR/ca.key" \
    -CAcreateserial \
    -out "$TLS_DIR/$VCS_URL.crt" \
    -days 825 -sha256 \
    -extfile "$TLS_DIR/ext.cnf"

  rm -f "$TLS_DIR/$VCS_URL.csr" "$TLS_DIR/ext.cnf"
fi

echo "=== Установка CA в систему ==="

if [ "$(id -u)" -ne 0 ]; then
  echo "Требуется root для установки CA:"
  echo "sudo cp $TLS_DIR/ca.crt /usr/local/share/ca-certificates/vcs-local-ca.crt"
  echo "sudo update-ca-certificates"
else
  cp "$TLS_DIR/ca.crt" /usr/local/share/ca-certificates/vcs-local-ca.crt
  update-ca-certificates
fi

echo "=== Добавление записи в /etc/hosts ==="

HOST_LINE="$VCS_LAN_IP $VCS_URL"

if ! grep -q "$VCS_URL" /etc/hosts 2>/dev/null; then
  if [ "$(id -u)" -ne 0 ]; then
    echo "Добавь вручную:"
    echo "echo \"$HOST_LINE\" | sudo tee -a /etc/hosts"
  else
    echo "$HOST_LINE" >> /etc/hosts
  fi
fi

echo "=== Установка и настройка dnsmasq ==="

DNSMASQ_OK=1
DNSMASQ_REASON=""

if [ "$(id -u)" -ne 0 ]; then
  DNSMASQ_OK=0
  DNSMASQ_REASON="нужен root (запусти скрипт через sudo)"
else
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    if ! dpkg -s dnsmasq >/dev/null 2>&1; then
      if apt-get update -y >/dev/null 2>&1 && apt-get install -y dnsmasq >/dev/null 2>&1; then
        :
      else
        DNSMASQ_OK=0
        DNSMASQ_REASON="не удалось установить dnsmasq (apt-get install)"
      fi
    fi

    if [ "$DNSMASQ_OK" -eq 1 ]; then
      DNSMASQ_CONF="/etc/dnsmasq.d/vcs.conf"
      cat > "$DNSMASQ_CONF" <<EOF
domain-needed
bogus-priv
no-resolv
listen-address=127.0.0.1
bind-interfaces

address=/$VCS_URL/$VCS_LAN_IP
EOF

      if systemctl list-unit-files 2>/dev/null | grep -q '^systemd-resolved\.service'; then
        if systemctl is-active --quiet systemd-resolved; then
          if ! grep -q '^DNSStubListener=no' /etc/systemd/resolved.conf 2>/dev/null; then
            mkdir -p /etc/systemd
            sed -i 's/^\s*#\?\s*DNSStubListener=.*/DNSStubListener=no/g' /etc/systemd/resolved.conf 2>/dev/null || true
            if ! grep -q '^DNSStubListener=' /etc/systemd/resolved.conf 2>/dev/null; then
              printf "\n[Resolve]\nDNSStubListener=no\n" >> /etc/systemd/resolved.conf
            fi
            systemctl restart systemd-resolved >/dev/null 2>&1 || true
          fi
        fi
      fi

      systemctl enable --now dnsmasq >/dev/null 2>&1 || {
        DNSMASQ_OK=0
        DNSMASQ_REASON="dnsmasq не запустился (systemctl enable --now dnsmasq). Проверь: journalctl -u dnsmasq"
      }

      if [ "$DNSMASQ_OK" -eq 1 ]; then
        if systemctl is-active --quiet dnsmasq; then
          if command -v resolvectl >/dev/null 2>&1; then
            IFACE="$(ip route | awk '/default/ {print $5; exit}')"
            if [ -n "$IFACE" ]; then
              resolvectl dns "$IFACE" 127.0.0.1 >/dev/null 2>&1 || true
              resolvectl domain "$IFACE" "~." >/dev/null 2>&1 || true
            fi
          fi

          if getent hosts "$VCS_URL" >/dev/null 2>&1; then
            RESOLVED_IP="$(getent hosts "$VCS_URL" | awk '{print $1}' | head -n1)"
            if [ "$RESOLVED_IP" = "$VCS_LAN_IP" ]; then
              echo "dnsmasq: OK (резолвит $VCS_URL -> $VCS_LAN_IP)"
            else
              DNSMASQ_OK=0
              DNSMASQ_REASON="dnsmasq запущен, но $VCS_URL резолвится в $RESOLVED_IP (ожидалось $VCS_LAN_IP). Проверь resolv.conf/resolved"
            fi
          else
            DNSMASQ_OK=0
            DNSMASQ_REASON="dnsmasq запущен, но getent hosts $VCS_URL не возвращает адрес. Проверь /etc/resolv.conf и resolved"
          fi
        else
          DNSMASQ_OK=0
          DNSMASQ_REASON="dnsmasq не активен (systemctl is-active dnsmasq)"
        fi
      fi
    fi
  else
    DNSMASQ_OK=0
    DNSMASQ_REASON="apt-get не найден (поддерживается Ubuntu/Debian)"
  fi
fi

if [ "$DNSMASQ_OK" -ne 1 ]; then
  echo "dnsmasq: FAIL — $DNSMASQ_REASON"
  echo "Можно продолжать без dnsmasq, но клиентам нужен DNS/hosts для $VCS_URL -> $VCS_LAN_IP"
fi

echo "=== Генерация конфигов ==="

cat > "$BASE_DIR/vcs.yaml" <<EOF
port: 7880
bind_addresses:
  - "0.0.0.0"

rtc:
  tcp_port: 7881
  port_range_start: $RTC_PORT_START
  port_range_end: $RTC_PORT_END
  use_external_ip: false
  enable_loopback_candidate: false

redis:
  address: localhost:6379

turn:
  enabled: false

keys:
  $VCS_API_KEY: $VCS_API_SECRET
EOF

cat > "$BASE_DIR/redis.conf" <<EOF
bind 127.0.0.1 ::1
protected-mode yes
port 6379
EOF

cat > "$BASE_DIR/caddy.yaml" <<EOF
logging:
  logs:
    default:
      level: INFO

storage:
  module: file_system
  root: /data

apps:
  tls:
    certificates:
      load_files:
        - certificate: /tls/$VCS_URL.crt
          key: /tls/$VCS_URL.key

  layer4:
    servers:
      main:
        listen: [":443"]
        routes:
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
EOF

cat > "$BASE_DIR/docker-compose.yaml" <<EOF
services:
  caddy:
    image: livekit/caddyl4:latest
    command: run --config /etc/caddy.yaml --adapter yaml
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./caddy.yaml:/etc/caddy.yaml
      - ./caddy_data:/data
      - ./tls:/tls:ro

  vcs:
    image: livekit/livekit-server:v1.7.2
    command: --config /etc/vcs.yaml
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./vcs.yaml:/etc/vcs.yaml

  redis:
    image: redis:7.4.1-alpine
    command: redis-server /etc/redis.conf
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./redis.conf:/etc/redis.conf
EOF

echo "=== Запуск сервисов ==="
cd "$BASE_DIR"
docker compose up -d

echo "=== Проверка портов ==="
ss -lntp | grep -E ':443|:7880|:7881' || true

echo ""
echo "Сервер готов, укажите адрес в настройках Видеоконференции UnicChat:"
echo "wss://$VCS_URL"
echo ""
echo "Тест:"
echo "lk room join --url https://$VCS_URL --api-key $VCS_API_KEY --api-secret $VCS_API_SECRET --identity testuser testroom"
