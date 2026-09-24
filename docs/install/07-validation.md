# Проверка установки

Выполните чек-лист до `docker compose up`. В конце установки пройдите критерии успеха. Статус контейнера `Up` сам по себе готовность не означает: смотрите `healthy` и ответы сервисов.

## Чек-лист до запуска

- [ ] DNS-имена из `.env` резолвятся в нужный IP (`getent hosts` или `dig`)
- [ ] Время хоста синхронизировано (`timedatectl`)
- [ ] Firewall открывает только согласованные порты из [сети](04-network.md)
- [ ] Порты 80 и 443 свободны, если TLS выпускаете на этом хосте (`ss -lnt`)
- [ ] На диске данных свободно не меньше 30% (`df -h`)
- [ ] Hostname не `localhost`, если на нём строите внутренние имена
- [ ] `docker login` в `cr.yandex` успешен (`docker pull` одного образа из `.env`)
- [ ] С хоста открывается `https://push1.unic.chat/`
- [ ] Сертификаты лежат по путям из `.env`, SAN совпадает с именами
- [ ] `cp .env.example .env` сделан, значения `change_me_*` заменены
- [ ] `./validate-env.sh` печатает `validation PASSED`
- [ ] В `.env` не осталось `example.com`, если это не учебный прогон на заглушках

## Готовность сервисов

После запуска:

```shell
docker compose ps
```

На одном сервере дождитесь `--wait` из [установки на одном сервере](02-single-node.md). На нескольких — `healthy` на каждой роли до перехода к следующей.

| Проверка | Как убедиться |
|----------|----------------|
| Контейнер healthy | колонка STATUS содержит `healthy`, не только `Up` |
| MongoDB replica set | healthcheck `db.hello().isWritablePrimary` проходит |
| MinIO | `curl -f http://127.0.0.1:9000/minio/health/live` на хосте MinIO |
| DocumentServer | в логе есть `Installing plugins, please wait...Done`, затем `GET /healthcheck` |
| PostgreSQL и RabbitMQ | их healthcheck зелёный до DocumentServer |
| Vault | `vault-init` завершился, в логе `KBTConfigs secret created` или `already exists` |
| Tasker | контейнер healthy и доступен с AppServer по `UNIC_SOLID_HOST` |
| Logger | контейнер healthy, AppServer/Tasker не пишут ошибки соединения с `API_LOGGER_URL` |
| Nginx | `curl -skI https://<APP_SERVER_NAME>` возвращает ответ, не таймаут |

Пока в логе DocumentServer нет `Done`, пауза SSH или веб-интерфейса на 1–2 минуты ещё не означает сбой.

## Критерии успешной установки

- [ ] `https://<APP_SERVER_NAME>` открывается
- [ ] Администратор создан ([после установки](post-install.md))
- [ ] Вход этим пользователем проходит
- [ ] Сообщение в тестовом чате отправляется
- [ ] Файл загружается и скачивается
- [ ] Документ открывается в редакторе
- [ ] В админке включён push на `https://push1.unic.chat`, если телефоны в контуре
- [ ] Выбран один контур ВКС: [внешний](11-vcs-external.md) или [локальный](12-vcs-local.md), тестовый звонок проходит
- [ ] Обязательные контейнеры в статусе `healthy`

Если пункт не сходится, откройте [диагностику](10-troubleshooting.md). После успешной установки снимите копию — [резервное копирование](08-backup-restore.md).
