# UnicChat Enterprise

Корпоративный мессенджер. Версия документа **1.21**.

Вы устанавливаете продукт из каталога `multi-server-install/` через Docker Compose. Образы лежат в Yandex Container Registry.

## Схемы развёртывания

| Схема | Назначение | Где описана |
|-------|------------|-------------|
| Один сервер | Демонстрация, тест, малый контур | [установка на одном сервере](docs/install/02-single-node.md) |
| Несколько серверов | Промышленная эксплуатация | [установка на нескольких серверах](docs/install/03-multi-node.md) |

Один сервер не является поддерживаемой промышленной схемой: все сервисы делят один хост, диск и окно обслуживания. Для production используйте разнесение ролей.

Схемы состава серверов:

![Один сервер](./assets/1vm-unicchat-install-scheme.jpg)

![Два сервера](./assets/2vm-unicchat-install-scheme.jpg)

## Что нужно до запуска

- Ubuntu 22.04 или 24.04, Docker Engine и плагин Compose
- Лицензия UnicChat от Unicomm (без неё контейнеры стартуют, продукт не работает)
- Три DNS-имени: приложение, DocumentServer, MinIO
- Исходящий доступ к `cr.yandex` и `push1.unic.chat` по 443/tcp

Подробности, sizing и матрица версий — в [требованиях](docs/install/01-requirements.md).

## Быстрый старт (один сервер, тест)

```shell
git clone https://github.com/unicommorg/unicchat.enterprise.git
cd unicchat.enterprise/multi-server-install
cp .env.example .env
```

Замените значения `change_me_*` своими паролями. Войдите в реестр и проверьте файл до запуска:

```shell
docker login --username oauth \
  --password-stdin \
  cr.yandex <<< "y0__wgBEPrL67wHGMHdEyD7rJmMGCeDEOXSuqJalbFdb2Dgucs0mlmU"

./validate-env.sh
docker compose pull
docker compose up -d --wait
```

Критерии готовности — в [проверке установки](docs/install/07-validation.md).

## Документация по установке

Полные инструкции: каталог [`docs/install/`](docs/install/)  
Оглавление: [`docs/install/README.md`](docs/install/README.md)

PDF продукта, администрирования и пользователя: каталог [`docs/`](docs/).

Локальный медиасервер ВКС (LiveKit и Coturn): каталог [`vcs.unic.chat.template/`](vcs.unic.chat.template/).
