
<!-- TOC --><a name="-unicchat"></a>
# Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat

версия документа 1.7

<!-- TOC --><a name=""></a>
## Оглавление

<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

   * [Скачать инструкции в PDF ](#-pdf)
   * [Архитектура установки](#-)
      + [Установка на 1-м сервере](#-1-)
      + [Установка на 2-х серверах (рекомендуется для промышленного использования)](#-2-)
   * [Обязательные компоненты](#--1)
         - [Push шлюз](#push-)
         - [ВКС шлюз](#--2)
         - [Приложения UnicChat](#-unicchat-1)
   * [Опциональные компоненты](#--3)
         - [SMTP сервер](#smtp-)
         - [LDAP сервер](#ldap-)
   * [Шаг 1. Подготовка окружения](#-1--1)
      + [1.1 Требования к конфигурации](#11-)
         - [Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине](#-20-1-)
         - [Конфигурация виртуальной машины](#--4)
         - [Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины](#-20-50-)
         - [Конфигурация виртуальной машины для приложения](#--5)
         - [Конфигурация виртуальной машины для БД](#--6)
      + [1.2. Запрос лицензии для Unicchat Solid Core](#12-unicchat-solid-core)
      + [1.3. Клонирование репозитория](#13-)
      + [1.4 Зарегистрировать DNS имена](#14-dns-)
   * [Автоматическая настройка для NGINX, базы знаний для UNICCHAT, UNICCHAT](#-nginx-unicchat-unicchat)
      + [Инструкция по скрипту установки unicchat.sh](#-unicchatsh)
         - [Запуск скрипта unicchat.sh](#-unicchatsh-1)
      + [Описание скрипта](#--7)
         - [Основные функции в меню](#--8)
            * [Установка компонентов](#--9)
            * [Настройка конфигурации](#--10)
            * [Настройка веб-сервера](#--11)
            * [Запуск сервисов](#--12)
            * [Автоматизация](#-1)
         - [Детальное описание ключевых функций](#--13)
            * [Линковка сервисов](#--14)
            * [DNS конфигурация](#dns-)
            * [SSL настройка](#ssl-)
            * [Конфигурация баз данных](#--15)
         - [Файлы конфигурации](#--16)
         - [Особенности работы](#--17)
         - [Рекомендуемая последовательность](#--18)
      + [2. Ручная настройка](#--manual)
         - [2.1 Установите Docker](#21-docker)
         - [2.2 Провести настройку Nginx](#22-nginx)
            - [2.2.1 Подготовка Docker Compose стека для Nginx](#221-nginx)
            - [2.2.2 Генерация конфигурации Nginx для UnicChat и Базы знаний](#222-nginx-unicchat-)
            - [2.2.3 Получение SSL сертификатов через Certbot](#223-certbot-)
            - [2.2.4 Развертывание и активация конфигураций Nginx](#224-nginx)
            - [2.2.6 Настройка автоматического обновления сертификатов Certbot](#226-certbot)
      + [2.3 Открыть доступы до внутренних ресурсов](#23-)
         - [Входящие соединения на стороне сервера UnicChat:](#-unicchat-2)
         - [Исходящие соединения на стороне сервера UnicChat на push:](#-unicchat-push)
         - [Исходящие соединения на стороне сервера UnicChat на ВКС:](#-unicchat-)
   * [Шаг 3. Установка локального медиа сервера для ВКС](#-3-)
      + [3.1 Порядок установки сервера](#31-)
      + [3.2 Проверка открытия портов](#32-)
         - [Обязательные порты](#--19)
            * [TCP порты:](#tcp-)
            * [UDP порты:](#udp-)
            * [Опциональные порты](#--20)
   * [Шаг 4. Развертывание базы знаний для UNICCHAT](#-4-unicchat)
      + [4.4 Развертывание MinIO S3](#44-minio-s3)
         - [4.4.1 Создание переменных окружения для Базы Знаний](#441-y-)
         - [4.4.2 Запустите Базу Знаний](#442-)
         - [4.4.3 Доступ к MinIO:](#443-minio)
         - [4.4.4 Создание bucket](#444-bucket)
         - [4.4.5 Настройка DNS записей для проксирования](#445-dns-)
   * [Шаг 5. Установка UnicChat](#-5-unicchat)
      + [5.1 Настройка Unic.Chat](#51-unicchat)
      + [5.2 Раздать права пользователю для подключения к базе](#52-)
   * [Шаг 6. Создание пользователя администратора](#-6-)
   * [Шаг 7. Настройка push-уведомлений](#-7-push-)
   * [Опциональные компоненты](#--21)
      * [Шаг 8. Настройка unicvault](#-8-unicvault)
      * [Шаг 9. Настройка redminebot](#-9-redminebot)
      + [Важные замечания](#--22)
   * [Клиентские приложения](#--23)

<!-- TOC end -->



<!-- TOC --><a name="-pdf"></a>
## Скачать инструкции в PDF 

Инструкции для unicchat лежат в репозитории [docs](https://github.com/unicommorg/unicchat.enterprise/tree/main/docs)

* [Инструкция пользователя UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F%20%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D0%B5%D0%BB%D1%8F%20UnicChat.pdf)
* [Инструкция_по_администрированию_UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%B8%D1%81%D1%82%D1%80%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Инструкция_по_лицензированию_UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E_UnicChat.pdf)
* [Описание архитектуры UnicChat.pdf](https://github.com/unicommorg/unicchat.enterprise/blob/main/docs/%D0%9E%D0%BF%D0%B8%D1%81%D0%B0%D0%BD%D0%B8%D0%B5%20%D0%B0%D1%80%D1%85%D0%B8%D1%82%D0%B5%D0%BA%D1%82%D1%83%D1%80%D1%8B%20UnicChat.pdf)

<!-- TOC --><a name="-"></a>
## Архитектура установки

___

<!-- TOC --><a name="-1-"></a>
### Установка на 1-м сервере

![](./assets/1vm-unicchat-install-scheme.jpg "Архитектура установки на 1-м сервере")

<!-- TOC --><a name="-2-"></a>
### Установка на 2-х серверах (рекомендуется для промышленного использования)

![](./assets/2vm-unicchat-install-scheme.jpg "Архитектура установки на 2-х серверах")

<!-- TOC --><a name="--1"></a>
## Обязательные компоненты

___

<!-- TOC --><a name="push-"></a>
#### Push шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для отправки push-сообщений на мобильные платформы Apple и Google.
Расположен во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и не требуются входящие соединения.

<!-- TOC --><a name="--2"></a>
#### ВКС шлюз

Публичный сервис компании Unicomm. Подключение к нему необходимо для работы аудио и видео конференций, а также аудио-звонков.
Расположены во внешнем периметре на серверах компании. Серверу UnicChat требуются исходящие соединения к этому сервису и не требуются входящие соединения.

<!-- TOC --><a name="-unicchat-1"></a>
#### Приложения UnicChat

Пользовательское приложение, установленное на iOS или Android платформе.
Сервер UnicChat должен иметь возможность принимать входящие сообщения от этих приложений, а также отправлять ответы.
Основное взаимодействие осуществляется через протокол HTTPS (443/TCP).
Для работы видео- и аудиозвонков необходимы протоколы STUN и TURN: входящие соединения на порты 7881/TCP и 7882/UDP, а также входящий и исходящий трафик UDP по портам 50000-60000 (RTP-трафик).

<!-- TOC --><a name="--3"></a>
## Опциональные компоненты

___

<!-- TOC --><a name="smtp-"></a>
#### SMTP сервер

Используется для отправки OTP-сообщений, восстановлений пароля, напоминания о пропущенных сообщениях, предоставляется вами.
Может быть использован как публичный, так и ваш собственный сервер. На схеме предполагается, что сервер находится в вашем сегменте DMZ.
**Интеграция с SMTP не является обязательным условием.**

<!-- TOC --><a name="ldap-"></a>
#### LDAP сервер

Используется для получения списка пользователей в системе. UnicChat может обслуживать как пользователей, заведенных в LDAP каталоге, так и внутренних пользователей в собственной базе. **Интеграция с LDAP не является обязательным условием**
#### 

<!-- TOC --><a name="-1--1"></a>
## Шаг 1. Подготовка окружения

<!-- TOC --><a name="11-"></a>
### 1.1 Требования к конфигурации

<!-- TOC --><a name="-20-1-"></a>
#### Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине

<!-- TOC --><a name="--4"></a>
#### Конфигурация виртуальной машины

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2, AVX 2.0;
RAM 8 Gb;
150 Gb HDD\SSD;
```

<!-- TOC --><a name="-20-50-"></a>
#### Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины

<!-- TOC --><a name="--5"></a>
#### Конфигурация виртуальной машины для приложения

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2;
RAM 8 Gb;
200 Gb HDD\SSD
```

<!-- TOC --><a name="--6"></a>
#### Конфигурация виртуальной машины для БД

```
CPU 4 cores 1.7ghz, с набором инструкций FMA3, SSE4.2, AVX 2.0;
RAM 8 Gb;
100 Gb HDD\SSD
```

<!-- TOC --><a name="12-unicchat-solid-core"></a>
### 1.2. Запрос лицензии для Unicchat Solid Core

Просим обратиться в компанию unicomm для выдачи лицензии Unicchat Solid Core



<!-- TOC --><a name="13-"></a>
### 1.3. Клонирование репозитория

1. Скачать при помощи `git` командой `git clone` файлы по https://github.com/unicommorg/unicchat.enterprise.git.
 Выполнить на сервере

```shell
git clone https://github.com/unicommorg/unicchat.enterprise.git
```
2. Либо клонируйте репозиторий иным способом.

<!-- TOC --><a name="14-dns-"></a>
### 1.4 Зарегистрировать DNS имена

Перед началом работы запросите DNS-имена. Ниже приведены DNS-имена для примера. Вы можете изменить их под свои нужды.

* myapp.unic.chat
* myminio.unic.chat (требуется настройка в /etc/hosts на сервере с NGINX)
* myedt.unic.chat (требуется настройка в /etc/hosts на сервере с NGINX)
* mylk-yc.unic.chat
* turn.mylk-yc.unic.chat
* whip.mylk-yc.unic.chat

1. UnicChat (Основной сервис мессенджера)
* **myapp.unic.chat**

   **Назначение**: Основной адрес сервера приложений UnicChat, через который пользователи получают доступ к веб-интерфейсу мессенджера.  
   **Использование**: Обеспечивает доступ к клиентскому интерфейсу UnicChat, включая чаты, настройки и администрирование. Используется для HTTPS-соединений и проверки работоспособности сервиса.

2. База знаний (Хранение и редактирование документов)
* **myminio.unic.chat**

   **Назначение**: Адрес сервера MinIO, используемого для хранения файлов (S3-совместимое хранилище).  
   **Использование**: Хранит файлы, загружаемые пользователями, и документы DocumentServer. Консоль управления доступна через http://<hostname minio>:9002 (логин: minioadmin, пароль: rootpassword). Бакет uc.onlyoffice.docs создаётся для документов.  


* **myedt.unic.chat**

   **Назначение**: Адрес сервера DocumentServer, используемого для редактирования документов в UnicChat.  
   **Использование**: Обеспечивает интеграцию с DocumentServer для совместной работы с документами. Доступен через https://myedt.unic.chat.  
3. Медиасервер ВКС (Видеоконференцсвязь)
* **mylk-yc.unic.chat**

   **Назначение**: Адрес ВКС-шлюза (видеоконференцсвязи), используемого для аудио- и видеозвонков.  
   **Использование**: Обеспечивает функциональность видеоконференций в UnicChat. Требует исходящих соединений для клиентских приложений и настройки STUN/TURN для NAT-траверсала.

* **turn.mylk-yc.unic.chat**

   **Назначение**: Адрес TURN-сервера, используемого для обхода NAT при видеозвонках.  
   **Использование**: Обеспечивает стабильное соединение для видеоконференций в сетях с ограничениями (например, за NAT). Работает в связке с ВКС-шлюзом.

*  **whip.mylk-yc.unic.chat**

   **Назначение**: Адрес WHIP-сервера (WebRTC-HTTP Ingestion Protocol), используемого для потоковой передачи медиа в видеоконференциях.  
   **Использование**: Поддерживает передачу медиа-данных в реальном времени для видеозвонков.

<!-- TOC --><a name="-nginx-unicchat-unicchat"></a>
## Автоматическая настройка для NGINX, базы знаний для UNICCHAT, UNICCHAT

Этим скриптом вы можете автоматически установить NGINX, базу знаний для UNICCHAT, UNICCHAT.
ВКС устанавливается отдельным скриптом.

<!-- TOC --><a name="-unicchatsh"></a>
### Инструкция по скрипту установки unicchat.sh


<!-- TOC --><a name="-unicchatsh-1"></a>
#### Запуск скрипта unicchat.sh

1. Сделайте скрипт исполняемым:
```shell
chmod +x ./unicchat.sh
```
2. Запустите скрипт:
```shell
./unicchat.sh
```

<!-- TOC --><a name="--7"></a>
### Описание скрипта

Скрипт представляет собой интерактивный помощник для установки и настройки UnicChat.

Скрипт предполагает что вы устанавливаете все компоненты на одном сервере.

<!-- TOC --><a name="--8"></a>
#### Основные функции в меню

<!-- TOC --><a name="--9"></a>
#####  Установка компонентов

| № | Функция | Описание |
|---|---------|-----------|
| 1 | `install_docker` | Устанавливает Docker, Docker Compose и зависимости |
| 2 | `install_nginx_ssl` | Подготавливает Docker Compose стек для Nginx и Certbot |
| 3 | `install_git` | Устанавливает систему контроля версий Git |
| 4 | `install_dns_utils` | Устанавливает DNS-утилиты (nslookup, dig) |
| 5 | `install_minio_client` | Устанавливает клиент MinIO (`mc`) |

<!-- TOC --><a name="--10"></a>
##### Настройка конфигурации

| № | Функция | Описание |
|---|---------|-----------|
| 6 | `check_avx` | Проверяет поддержку AVX для выбора версии MongoDB |
| 7 | `setup_dns_names` | Настраивает доменные имена для сервисов |
| 8 | `setup_license` | Добавляет лицензионный ключ UnicChat |
| 9 | `update_mongo_config` | Настраивает параметры MongoDB |
| 10 | `update_minio_config` | Настраивает параметры MinIO |
| 11 | `setup_local_network` | Обновляет /etc/hosts для локальных DNS |

<!-- TOC --><a name="--11"></a>
##### Настройка веб-сервера

| № | Функция | Описание |
|---|---------|-----------|
| 12 | `generate_nginx_conf` | Генерирует конфиги Nginx для сервисов |
| 13 | `deploy_nginx_conf` | Разворачивает конфиги Nginx |
| 14 | `copy_ssl_configs` | Копирует SSL конфиги и генерирует DH параметры |
| 15 | `setup_ssl` | Настраивает SSL сертификаты через Let's Encrypt |
| 16 | `activate_nginx` | Активирует сайты Nginx |

<!-- TOC --><a name="--12"></a>
##### Запуск сервисов

| № | Функция | Описание |
|---|---------|-----------|
| 17 | `prepare_unicchat` | Подготавливает .env файлы и линкует сервисы |
| 18 | `login_yandex` | Логин в Yandex Container Registry |
| 19 | `start_unicchat` | Запускает основные контейнеры UnicChat |
| 20 | `deploy_knowledgebase` | Разворачивает сервисы базы знаний |
<!-- TOC --><a name="-1"></a>
#####  Автоматизация

| № | Функция | Описание |
|---|---------|-----------|
| 99 | `auto_setup` | Полная автоматическая установка (включая базу знаний) |
| 100 | `cleanup_utilities` | Полное удаление всех компонентов |
| 0 | - | Выход из скрипта |

<!-- TOC --><a name="--13"></a>
#### Детальное описание ключевых функций

<!-- TOC --><a name="--14"></a>
#####  Линковка сервисов

**`update_solid_env`** - связывает MinIO из базы знаний с основным приложением UnicChat:
- Добавляет конфигурацию MinIO в `solid.env`
- Включает лицензию если она настроена

**`update_appserver_env`** - связывает Document Server с основным приложением:
- Настраивает URL Document Server в `appserver.env`
- Обновляет ROOT_URL основного приложения

<!-- TOC --><a name="dns-"></a>
#####  DNS конфигурация

Скрипт настраивает три доменных имени:
- **App Server** - основное веб-приложение (порт 8080)
- **Document Server** - сервер документов OnlyOffice (порт 8880) 
- **MinIO** - объектное хранилище (порт 9000)

<!-- TOC --><a name="ssl-"></a>
#####  SSL настройка

Автоматически получает SSL сертификаты от Let's Encrypt:
- Останавливает Nginx для освобождения портов 80/443
- Получает или обновляет сертификаты
- Настраивает автоматическое обновление

<!-- TOC --><a name="--15"></a>
#####  Конфигурация баз данных

**MongoDB** - основная база данных:
- Настраивает root пароль
- Создает пользователя и базу данных
- Сохраняет конфигурацию в `mongo_config.txt`

**MinIO** - объектное хранилище:
- Настраивает root пользователя и пароль
- Сохраняет конфигурацию в `minio_config.txt`

<!-- TOC --><a name="--16"></a>
#### Файлы конфигурации

| Файл | Назначение |
|------|------------|
| `app_config.txt` | Email для Let's Encrypt |
| `dns_config.txt` | Доменные имена сервисов |
| `license.txt` | Лицензионный ключ |
| `mongo_config.txt` | Учетные данные MongoDB |
| `minio_config.txt` | Учетные данные MinIO |
| `unicchat_install.log` | Лог установки |

<!-- TOC --><a name="--17"></a>
#### Особенности работы

- ✅ **Требует права root** для установки системных пакетов
- ✅ **Автоматическое логирование** всех операций
- ✅ **Проверка зависимостей** перед выполнением операций
- ✅ **Повторное использование** - сохраняет конфигурацию между запусками
- ✅ **Цветной вывод** для лучшей читаемости
- ✅ **Обработка ошибок** с понятными сообщениями

<!-- TOC --><a name="--18"></a>
#### Рекомендуемая последовательность

Для новой установки рекомендуется использовать:
```bash
# Полная автоматическая установка
99 - Full automatic setup

# Или ручная установка по порядку:
1 → 2 → 3 → 4 → 5 → 6 →7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19 → 20 
```

<!-- TOC --><a name="--manual"></a>
## 2. Ручная настройка 

<!-- TOC --><a name="21-docker"></a>
### 2.1 Установите Docker

Установите Docker и Docker Compose согласно официальной документации:
https://docs.docker.com/engine/install/

Для Ubuntu/Debian можно использовать скрипт установки:
```shell
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Убедитесь, что Docker Compose установлен:
```shell
docker compose version
```

<!-- TOC --><a name="22-nginx"></a>
### 2.2 Провести настройку Nginx

Настройка Nginx и Let's Encrypt выполняется через Docker Compose. Все конфигурационные файлы и сертификаты хранятся в директории `nginx/docker/`.

<!-- TOC --><a name="221-nginx"></a>
#### 2.2.1 Подготовка Docker Compose стека для Nginx

Скрипт `unicchat.sh` автоматически подготовит необходимую структуру директорий и запустит Docker Compose стек. 

Структура директорий:
```
nginx/
├── docker-compose.yml          # Docker Compose конфигурация
└── docker/
    ├── conf.d/                  # Конфигурационные файлы Nginx
    └── certbot/
        ├── conf/                # Сертификаты Let's Encrypt
        ├── work/                # Рабочие файлы Certbot
        └── logs/                # Логи Certbot
```

Для ручной настройки выполните:
```shell
cd nginx
docker compose up -d nginx
```

<!-- TOC --><a name="222-nginx-unicchat-"></a>
#### 2.2.2 Генерация конфигурации Nginx для UnicChat и Базы знаний

Конфигурационные файлы генерируются автоматически скриптом `unicchat.sh` (пункт меню 12 - `generate_nginx_conf`).

Конфигурации создаются в директории `nginx/docker/conf.d/` для следующих доменов:

Порты по умолчанию:
* для myapp.unic.chat - 8080
* для myedt.unic.chat - 8880
* для myminio.unic.chat - 9000

Каждый конфигурационный файл содержит:
- Upstream блок с адресом сервера и портом
- HTTP сервер (порт 80) с редиректом на HTTPS
- HTTPS сервер (порт 443) с SSL сертификатами и проксированием на upstream

**Для ручной настройки:**

1. В директории `nginx/` находятся шаблоны конфигурационных файлов:
   - `myapp.unic.chat` - шаблон для основного приложения
   - `myedt.unic.chat` - шаблон для Document Server
   - `myminio.unic.chat` - шаблон для MinIO

2. Отредактируйте эти файлы под свою конфигурацию:
   - Замените доменные имена (`myapp.unic.chat`, `myedt.unic.chat`, `myminio.unic.chat`) на ваши реальные домены
   - В upstream блоке замените `127.0.0.1` на IP-адрес вашего сервера (если сервисы запущены на другом хосте)
   - Убедитесь, что порты (8080, 8880, 9000) соответствуют портам ваших сервисов

3. Скопируйте отредактированные файлы в директорию `nginx/docker/conf.d/` с расширением `.conf`:
```shell
cd nginx
cp myapp.unic.chat docker/conf.d/myapp.unic.chat.conf
cp myedt.unic.chat docker/conf.d/myedt.unic.chat.conf
cp myminio.unic.chat docker/conf.d/myminio.unic.chat.conf
```

Или переименуйте файлы напрямую в директории `nginx/docker/conf.d/` после редактирования.

<!-- TOC --><a name="223-certbot-"></a>
#### 2.2.3 Получение SSL сертификатов через Certbot

SSL сертификаты получаются автоматически через Docker контейнер Certbot. Скрипт `unicchat.sh` (пункт меню 15 - `setup_ssl`) выполнит:

1. Копирование файла `options-ssl-nginx.conf` в `nginx/docker/certbot/conf/`
2. Генерацию DH параметров (`ssl-dhparams.pem`)
3. Остановку контейнера Nginx для освобождения портов 80/443
4. Получение сертификатов для всех доменов через Certbot контейнер
5. Запуск контейнера Nginx с новыми сертификатами

Для ручного получения сертификатов:

1. **Скопируйте файл `options-ssl-nginx.conf`** в директорию certbot:
```shell
cd nginx
cp options-ssl-nginx.conf docker/certbot/conf/
```

2. **Сгенерируйте DH параметры** (если еще не созданы):
```shell
openssl dhparam -out docker/certbot/conf/ssl-dhparams.pem 2048
```

3. **Остановите Nginx контейнер** для освобождения портов 80/443:
```shell
docker compose stop nginx
```

4. **Получите сертификаты** (замените `your-email@example.com` на ваш реальный email адрес):
```shell
docker compose run --rm --service-ports certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email your-email@example.com \
  -d myapp.unic.chat \
  -d myedt.unic.chat \
  -d myminio.unic.chat
```

**Важно**: Используйте действительный email адрес! Let's Encrypt требует валидный email для регистрации аккаунта. Не используйте заглушки типа `your-email@example.com`.

5. **Запустите Nginx контейнер**:
```shell
docker compose up -d nginx
```

Сертификаты будут сохранены в `nginx/docker/certbot/conf/live/<домен>/`.

<!-- TOC --><a name="224-nginx"></a>
#### 2.2.4 Развертывание и активация конфигураций Nginx

После генерации конфигураций и получения сертификатов разверните конфигурации:

**Автоматически через скрипт:**
Используйте скрипт `unicchat.sh`:
- Пункт меню 13 - `deploy_nginx_conf` (развертывание конфигураций)
- Пункт меню 16 - `activate_nginx` (активация и перезагрузка)

**Вручную:**
```shell
cd nginx

# Проверить конфигурацию
docker compose exec nginx nginx -t

# Если проверка успешна, перезагрузить Nginx
docker compose exec nginx nginx -s reload

# Или перезапустить контейнер
docker compose restart nginx
```

Проверка конфигурации должна показать:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

<!-- TOC --><a name="226-certbot"></a>
#### 2.2.6 Настройка автоматического обновления сертификатов Certbot

Для автоматического обновления сертификатов добавьте задачу в cron:

```shell
# Редактировать crontab
crontab -e

# Добавить строку (обновление в 7:00 каждый день)
0 7 * * * cd /path/to/unicchat.enterprise/nginx && docker compose run --rm --service-ports certbot renew --non-interactive && docker compose exec nginx nginx -s reload
```

Или создайте файл `/etc/cron.daily/certbot-renew`:
```bash
#!/bin/bash
cd /path/to/unicchat.enterprise/nginx
docker compose run --rm --service-ports certbot renew --non-interactive
docker compose exec nginx nginx -s reload
```

Сделайте файл исполняемым:
```shell
chmod +x /etc/cron.daily/certbot-renew
```

<!-- TOC --><a name="23-"></a>
### 2.3 Открыть доступы до внутренних ресурсов

<!-- TOC --><a name="-unicchat-2"></a>
#### Входящие соединения на стороне сервера UnicChat:

Открыть порты:

- 8080/TCP - по-умолчанию, сервер запускается на 8080 порту и доступен http://localhost:8080, где localhost - это IP адрес сервера UnicChat;
- 443/TCP - порт будет нужен, если вы настроили nginx с сертификатом HTTPS;

<!-- TOC --><a name="-unicchat-push"></a>
#### Исходящие соединения на стороне сервера UnicChat на push:

* Открыть доступ для Push-шлюза:
 * 443/TCP, на хост **push1.unic.chat**;

<!-- TOC --><a name="-unicchat-"></a>
#### Исходящие соединения на стороне сервера UnicChat на ВКС:
Примечание **lk-yc.unic.chat** адрес внешней ВКС компании `Unicomm`, при развертывание локального медиа сервера используйте свой адрес.
* Открыть доступ для ВКС сервера:
 * 443/TCP, на хост **lk-yc.unic.chat**;
 * 7881/TCP, 7882/UDP
 * (50000 - 60000)/UDP (диапазон этих портов может быть изменён при развертывании лицензионной версии непосредственно владельцем лицензии)

* Открыть доступ до внутренних ресурсов: LDAP, SMTP, DNS при необходимости использования этого функционала

<!-- TOC --><a name="-3-"></a>
## Шаг 3. Установка локального медиа сервера для ВКС
Установка идёт на отдельном сервере от UnicChat
<!-- TOC --><a name="31-"></a>
### 3.1 Порядок установки сервера

Перейдите в директорию vcs.unic.chat.template:
```shell
cd vcs.unic.chat.template
```

1. В файле `.env` указать домены на которых будет работать ВКС сервер. WHIP пока не обязателен и его можно пропустить.
2. Запустить `./install_server.sh` (возможно, на последнюю операцию в файле нужно sudo). Перед запуском убедиться, что в директории, где запускается скрипт, есть файл `.env`. Сервер будет установлен в текущей поддиректории `./unicomm-vcs`.
3. Если на сервере отсутствует docker, то выполнить скрипт под sudo `./install_docker.sh` (только для Ubuntu) или иным способом установить docker compose.
4. Можно не использовать caddy, вместо этого использовать nginx. конфигурация сайтов в файле `example.sites.nginx.md`. На домены нужны HTTPS сертификаты. (плохо работает с TUNE сервером, лучше не использовать в продакш)
5. В файле ./unicomm-vcs/egress.yaml при необходимости отредактируйте значения api_key и api_secret
```yml
api_key: 
api_secret: 
ws_url: wss://
```

6. Запустите медиасервер командой `docker compose -f ./unicomm-vcs/docker-compose.yml up -d`.
7. Проверка поднятого сервера утилитой livekit-test: https://livekit.io/connection-test 
token: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzUzNzgxOTEsImlzcyI6IkFQSUZCNnFMeEtKRFc3VCIsIm5hbWUiOiJUZXN0IFVzZXIiLCJuYmYiOjE3MzkzNzgxOTEsInN1YiI6InRlc3QtdXNlciIsInZpZGVvIjp7InJvb20iOiJteS1maXJzdC1yb29tIiwicm9vbUpvaW4iOnRydWV9fQ.20rviVegoNerAE_WiFxshYDpL2DVAHvnJzkjsV3L_0Y`

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

<!-- TOC --><a name="-4-unicchat"></a>
## Шаг 4. Развертывание базы знаний для UNICCHAT
<!-- TOC --><a name="44-minio-s3"></a>
### 4.4 Развертывание MinIO S3

<!-- TOC --><a name="441-y-"></a>
#### 4.4.1 Создание переменных окружения для Базы Знаний

Перейдите в директорию ./knowledgebase/minio/ .
Скопируйте файл minio_env.env.example в minio_env.env .
Отредактируйте minio_env.env.

```shell
cd knowledgebase/minio/
cp minio_env.env.example minio_env.env
nano minio_env.env
```

<!-- TOC --><a name="442-"></a>
#### 4.4.2 Запустите Базу Знаний

Вернитесь в корневую директорию проекта:
```shell
cd ../../
```

Запустите контейнеры из корня проекта:
```bash
docker compose -f knowledgebase/minio/docker-compose.yml up -d && docker compose -f knowledgebase/Docker-DocumentServer/docker-compose.yml up -d  
```

<!-- TOC --><a name="443-minio"></a>
#### 4.4.3 Доступ к MinIO:

http://<hostname minio>:9002
логин и пароль указан в ` minio_env.env` файле

<!-- TOC --><a name="444-bucket"></a>
#### 4.4.4 Создание bucket

Создайте bucket `uc.onlyoffice.docs` и в настройках bucket назначьте Access Policy:public.

Есть два варианта создания bucket
1. Через веб-интерфейс
2. Через консольную утилиту mc

Способ 1. Через веб-интерфейс
Авторизуйтесь по http://<hostname minio>:9002

Создайте новый bucket `uc.onlyoffice.docs`.
В настройках отредактируйте права `Access Policy` на `public`
![](./assets/minio.png "Права bucket")

Способ 2. Через mc
Скачайте mc
```shell
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/
```

```shell
mc mb myminio/uc.onlyoffice.docs
mc anonymous set public myminio/uc.onlyoffice.docs
```
<!-- TOC --><a name="445-dns-"></a>
#### 4.4.5 Настройка DNS записей для проксирования

**Внимание**: Для корректной работы проксирования через NGINX необходимо на серверах с сервисами `myminio.unic.chat` и `myedt.unic.chat` добавить DNS записи в файл `/etc/hosts`.

1. Отредактируйте файл `/etc/hosts`:
```bash
sudo nano /etc/hosts
```

2. Добавьте следующие строки (замените `10.0.XX.XX` на IP-адрес сервера с NGINX):
```bash
10.0.XX.XX myminio.unic.chat
10.0.XX.XX myedt.unic.chat
```

**Где**:
- `10.0.XX.XX` — IP-адрес сервера с NGINX, на котором настроено проксирование
- Записи указывают, что домены должны разрешаться на NGINX сервер

3. Сохраните файл и перезапустите сетевой сервис:
```bash
sudo systemctl restart systemd-resolved
```
<!-- TOC --><a name="-5-unicchat"></a>
## Шаг 5. Установка UnicChat

<!-- TOC --><a name="51-unicchat"></a>
### 5.1 Настройка Unic.Chat

1. [Linux] На сервере БД выполните команду `grep avx /proc/cpuinfo`. Если в ответе вы не видите AVX, то вам лучше выбрать версию mongodb < 5.х, например, 4.4
 если AVX на вашем сервере поддерживается, рекомендуется выбрать версию mongodb > 5.х.
2. ВАЖНО! Если вы планируете запустить БД и сервер UnicChat на разных виртуальных серверах, то в параметрах `MONGODB_INITIAL_PRIMARY_HOST` и `MONGODB_ADVERTISED_HOSTNAME` вам нужно указать адрес (DNS или IP) вашего сервера, где запускается БД.

```shell
docker network create unicchat-backend
docker network create unicchat-frontend
```
3. Создайте .env файлы в директории `multi-server-install/`:
* solid.env
* appserver.env
* mongo.env

Запустите контейнеры из корневой директории проекта:
```shell
docker compose -f multi-server-install/mongodb.yml up -d && docker compose -f multi-server-install/unic.chat.solid.yml up -d && docker compose -f multi-server-install/unic.chat.appserver.yml up -d
```

<!-- TOC --><a name="52-"></a>
### 5.2 Раздать права пользователю для подключения к базе

1. После того как база успешно запустилась, подключимся к контейнеру с запущенной БД. Для этого на сервере, где запущен docker контейнер c базой, выполните

```shell
docker exec -it unic.chat.db.mongo mongosh -u root -p "rootpassword"
```
где `unic.chat.db.mongo` - имя нашего контейнера, указанного в `multi-server-install/mongodb.yml`, пароль MONGODB_ROOT_PASSWORD  в `multi-server-install/mongodb_env.env`

```javascript
// проверьте наличие вашей базы данных
show databases
```

```javascript
// Перейдите на вашу базу данных и проверьте пользователя
use unicchat_db
show users
```

```javascript
db.updateUser( "unicchat_admin",
{
roles: [
{role: "readWrite", db: "local"},
{role: "readWrite", db: "unicchat_db"},
{role: "dbAdmin", db: "unicchat_db"},
{role: "clusterMonitor", db: "admin"}
]
})
```

```javascript
// Перейдите на вашу базу данных и проверьте права пользователя
use unicchat_db
show users
```


Сайт открывается https://myapp.unic.chat
Если сайт сразу не открывается, то для сброса кеша использовать очистку кеша и cookie браузера, ctrl+R или использовать безопасный режим браузера.

<!-- TOC --><a name="-6-"></a>
## Шаг 6. Создание пользователя администратора

* `Name` - Имя пользователя, которое будет отображаться в чате;
* `Username` - Логин пользователя, который вы будете указывать для авторизации;
* `Email` - Действующая почта, используется для восстановления
* `Organization Name` - Краткое название вашей организации латинскими буквами без пробелов и спец. символов, используется для регистрации push уведомлений. Может быть указан позже;
* `Organization ID` - Идентификатор вашей организации, используется для подключения к push серверу. Может быть указан позже. Для получения ID необходимо написать запрос с указанием значения в Organization Name на почту support@unicomm.pro;
* `Password` - пароль вашего пользователя;
* `Confirm your password` - подтверждение пароля;

1. После создания пользователя, авторизоваться в веб-интерфейсе с использованием ранее указанных параметров.
2. Для включения пушей, перейти в раздел Администрирование - Push. Включить использование шлюза и указать адрес шлюза https://push1.unic.chat
3. Перейти в раздел Администрирование - Organization, убедиться что поля заполнены в соответствии с вашими данными.
4. Настройка завершена.

При первом входе может возникнуть информационное предупреждение
![](./assets/111.jpg "Предупреждение при первом входе")

Нажмите "ДА"

<!-- TOC --><a name="-7-push-"></a>
## Шаг 7. Настройка push-уведомлений

Приложение Unicchat работает с внешним push сервером для доставки push-уведомлений в приложение Unicchat на мобильные устройства.

<!-- TOC --><a name="--21"></a>
## Опциональные компоненты
<!-- TOC --><a name="-8-unicvault"></a>
### Шаг 8. Настройка unicvault

8.1. Подключитесь к mongodb c root правами
``` shell
docker exec -it unic.chat.db.mongo mongosh -u root -p "$MONGODB_ROOT_PASSWORD"
```

8.2. Создайте базу данных для unicvault:
```javascript
use vault_db
```
8.3. Создайте пользователя с правами на базу данных:
```javascript
db.createUser({
  user: "vault_user",
  pwd: "your_secure_password",
  roles: [
    { role: "readWrite", db: "vault_db" },
    { role: "readWrite", db: "admin" }  // или другая база для аутентификации
  ]
})
```
8.4 Перейдите в директорию unicvault
``` shell
cd unicvault
```
Создайте файл `.env` с переменными окружения:

```bash
# Замените значения на ваши реальные данные:
# username - имя пользователя MongoDB
# password - пароль пользователя
# 10.0.X.X - IP-адрес сервера MongoDB
# dbname - имя базы данных для Vault
# authdbname - база данных для аутентификации

MongoCS="mongodb://username:password@10.0.X.X/dbname?directConnection=true&authSource=authdbname&authMechanism=SCRAM-SHA-1"
```
Запустите unicvault.yml
```bash
docker compose -f unicvault.yml up -d
```

<!-- TOC --><a name="-9-redminebot"></a>
### Шаг 9. Настройка redminebot

Перейдите в redminebot 
```shell
cd redminebot
```

Обратите внимание на переменную окружения Vault__Host
Возможные способы подключения
 
* Vault__Host=http://vault:80  # по имени сервиса и внутреннему порту vault. В случае если они на одном сервере
* Vault__Host=http://internal_IP:8200 # по внутреннему адресу сервера на котором крутиться vault. пример 10.0.X.X 192.1.X.X
* Vault__Host=http://domainname:8200 # по  доменному имени и порту. Если 
 
  


Запустите redminebot.yml
```bash
docker compose  -f redminebot.yml  up -d
```

10. Подключение к unicchat к redminebot и unicvault
Перейдите в директорию с unicchat
```
cd multi-server-install/
```
```
nano unic.chat.appserver.yml
```

Добавьте  переменные окружения в envirioment
``` yml
version: "3"
services:
  unic.chat.appserver:
    container_name: unic.chat.appserver
    image: 
    restart: 
    volumes:
      - chat_data:/app/uploads
    ports:
      - "8080:3000"
    envirioment:
	# ---
      - VAULT__HOST=http://internal_IP:8200
      - REDMINE_BOT_HOST=http://internal_IP:8201
    networks:
      - unicchat-frontend
```
Перезапустите unic.chat.appserver
```
docker compose -f unic.chat.appserver.yml up -d
```
<!-- TOC --><a name="--22"></a>
### Важные замечания

- Убедитесь, что все IP-адреса и учетные данные заменены на реальные значения
- Убедитесь, что порты 8201 и 8200 не заняты другими приложениями
- Убедитесь, что пользователь MongoDB имеет необходимые права доступа к созданной базе данных

<!-- TOC --><a name="--23"></a>
## Клиентские приложения

* [Репозитории клиентских приложений]
* Android: (https://play.google.com/store/apps/details?id=pro.unicomm.unic.chat&pcampaignid=web_share)
* iOS: (https://apps.apple.com/ru/app/unicchat/id1665533885)
* Desktop: (https://github.com/unicommorg/unic.chat.desktop.releases/releases)
