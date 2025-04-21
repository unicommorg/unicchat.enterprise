## Конфигурация для VSC сервера
```nginx configuration
upstream vcsserver {
    server 127.0.0.1:7880;
}

# Структура серверов
    server {
        listen 80;
        listen [::]:80;
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name vcsserver.chat;

        ssl_certificate /etc/letsencrypt/live/vcs-vcsserver.chat/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/vcs-vcsserver.chat/privkey.pem;

        # Additional SSL settings
        ssl_session_timeout         1440m;
        ssl_protocols               TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers   on;
        ssl_ciphers                 "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";


        access_log                  /var/log/nginx/vcsserver.access.log;
        error_log                   /var/log/nginx/vcsserver.error.log;

        location / {
                proxy_set_header        Host $host;
                proxy_set_header        X-Real-IP $remote_addr;
                proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header        X-Forwarded-Proto $scheme;

                proxy_pass              http://vcsserver;

                proxy_http_version      1.1;
                proxy_set_header        Upgrade $http_upgrade;
                proxy_set_header        Connection "Upgrade";
                proxy_read_timeout      90;

                proxy_redirect          https://vcsserver http://vcsserver.chat;
        }
    }
```
## Конфигурация для TURN сервера
```nginx configuration
upstream turnserver {
    server 127.0.0.1:5349;
}
    server {
        listen 80;
        listen [::]:80;
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name turnserver.chat;

        ssl_certificate /etc/letsencrypt/live/turnserver.chat/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/turnserver.chat/privkey.pem;


 # Additional SSL settings
        ssl_session_timeout         1440m;
        ssl_protocols               TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers   on;
        ssl_ciphers                 "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";


        access_log                  /var/log/nginx/vcs-turnserver.access.log;
        error_log                   /var/log/nginx/vcs-turnserver.error.log;

        location / {
                proxy_set_header        Host $host;
                proxy_set_header        X-Real-IP $remote_addr;
                proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header        X-Forwarded-Proto $scheme;

                proxy_pass              http://turnserver;

                proxy_http_version      1.1;
                proxy_set_header        Upgrade $http_upgrade;
                proxy_set_header        Connection "Upgrade";
                proxy_read_timeout      90;

                proxy_redirect          https://turnserver http://turnserver.chat;
        }
}
```