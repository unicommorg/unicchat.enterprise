Перейдите в директорию livekit.unic.chat.template.
1. В файле `.env` указать домены на которых будет работать ВСК сервер. WHIP пока не обязателен и его можно пропустить.
2. Запустить `./install_server.sh` (возможно, на последнюю операцию в файле нужно sudo). Перед запуском убедиться, что в директории, 
где запускается скрипт, есть файл `.env`. Сервер будет установлен в текущей директории.
3. Если на сервере отсутствует docker, то выполнить скрипт под sudo `./install_docker.sh` (только для Ubuntu) или иным способом установить docker + compose
4. Можно не использовать caddy, вместо этого использовать nginx. конфигурация сайтов в файле `example.sites.nginx.md`. На домены нужны HTTPS сертификаты. (плохо работает с TUNE сервером, лучше не использовать в продакш)
5. Проверка поднятого сервера утилитой livekit-test: https://livekit.io/connection-test 
token: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzUzNzgxOTEsImlzcyI6IkFQSUZCNnFMeEtKRFc3VCIsIm5hbWUiOiJUZXN0IFVzZXIiLCJuYmYiOjE3MzkzNzgxOTEsInN1YiI6InRlc3QtdXNlciIsInZpZGVvIjp7InJvb20iOiJteS1maXJzdC1yb29tIiwicm9vbUpvaW4iOnRydWV9fQ.20rviVegoNerAE_WiFxshYDpL2DVAHvnJzkjsV3L_0Y`


#### Проверка открытия портов
1. Страница с открытыми портами: https://docs.livekit.io/home/self-hosting/ports-firewall/#ports
2. 
``` shell 
 sudo lsof -i:7880 -i:7881 -i:5349 -i:3478 -i:50879 -i:54655 -i:59763
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
livekit-s 5780 root    8u  IPv6  69483      0t0  TCP *:7881 (LISTEN)
livekit-s 5780 root    9u  IPv4  69493      0t0  TCP *:5349 (LISTEN)
livekit-s 5780 root   10u  IPv4  69494      0t0  UDP *:3478
livekit-s 5780 root   11u  IPv6  70260      0t0  TCP *:7880 (LISTEN)
```
``` shell
telnet `internal_IP` 7880 # 7880 7881 5349
```