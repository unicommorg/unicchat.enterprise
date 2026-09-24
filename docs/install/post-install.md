# После установки

Выполните это, когда [критерии](07-validation.md) по веб-интерфейсу уже зелёные: страница `https://<APP_SERVER_NAME>` открывается.

## Администратор

В мастере первого входа заполните:

- **Name** — имя в чате
- **Username** — логин
- **Email** — почта для восстановления
- **Organization Name** — короткое имя латиницей без пробелов
- **Organization ID** — идентификатор для push; можно указать позже. Запросите его письмом на support@unicomm.pro, указав Organization Name
- **Password** — отдельный длинный пароль. Не берите пароль из `.env`

Войдите этим пользователем. Если видите предупреждение при первом входе, подтвердите его.

Откройте Администрирование — Organization и проверьте поля организации.

## Push

Откройте Администрирование — Push. Включите шлюз и укажите `https://push1.unic.chat`. С сервера должен быть исходящий 443/tcp на этот адрес.

## Клиенты

- Android: https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat
- iOS: https://apps.apple.com/ru/app/unicchat/id1665533885
- Desktop: https://github.com/unicommorg/unic.chat.desktop.releases/releases

## Redminebot (необязательно)

Бот связывает UnicChat с Redmine. Без него мессенджер работает.

1. В `redminebot/redminebot.yml` сеть должна быть внешняя `unicchat-network`.
2. `Vault__Host`: `http://unicchat-vault:80` в одной сети Docker, либо `http://<ip vault>:8200` с другого сервера.
3. Запуск:

```shell
cd redminebot
docker compose -f redminebot.yml up -d
docker logs ucredminebot
```

4. В окружение AppServer добавьте `REDMINE_BOT_HOST`. На одном сервере это `http://ucredminebot:8080`. С другого хоста — `http://<ip>:8201`.
5. Перезапустите AppServer:

```shell
docker compose restart unicchat-appserver
```

На роли AppServer используйте `-f compose.appserver.yml`. Порт 8201 не должен быть занят.
