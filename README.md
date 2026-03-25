

<!-- TOC --><a name="-unicchat"></a>
# Инструкция по установке корпоративного мессенджера для общения и командной работы UnicChat

версия документа 1.9

<!-- TOC --><a name=""></a>
## Оглавление

<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Скачать инструкции в PDF ](#-pdf)
- [Архитектура установки](#-)
   * [Установка на 1-м сервере](#-1-)
   * [Установка на 2-х серверах (рекомендуется для промышленного использования)](#-2-)
- [Обязательные компоненты](#--1)
      + [Push шлюз](#push-)
      + [ВКС шлюз](#--2)
      + [Приложения UnicChat](#-unicchat-1)
- [Опциональные компоненты](#--3)
      + [SMTP сервер](#smtp-)
      + [LDAP сервер](#ldap-)
- [Шаг 1. Подготовка окружения](#-1--1)
   * [1.1 Требования к конфигурации](#11-)
      + [Требования к конфигурации на 20 пользователей. Приложение и БД устанавливаются на 1-й виртуальной машине](#-20-1-)
      + [Конфигурация виртуальной машины](#--4)
      + [Требования к конфигурации на 20-50 пользователей. Приложение и БД устанавливаются на разные виртуальные машины](#-20-50-)
      + [Конфигурация виртуальной машины для приложения](#--5)
      + [Конфигурация виртуальной машины для БД](#--6)
   * [1.2. Запрос лицензии для Unicchat Solid Core](#12-unicchat-solid-core)
   * [1.3. Клонирование репозитория](#13-)
   * [1.4 Зарегистрировать DNS имена](#14-dns-)
- [Автоматическая настройка для NGINX, базы знаний для UNICCHAT, UNICCHAT](#-nginx-unicchat-unicchat)
   * [Инструкция по скрипту установки unicchat.sh](#-unicchatsh)
      + [Запуск скрипта unicchat.sh](#-unicchatsh-1)
   * [Описание скрипта](#--7)
      + [Основные функции в unicchat.sh](#unicchatsh-functions)
      + [Основные функции в меню](#--8)
         - [Установка компонентов](#--9)
         - [Настройка конфигурации](#--10)
         - [Настройка веб-сервера](#--11)
         - [Запуск сервисов](#--12)
         - [Автоматизация](#-1)
      + [Детальное описание ключевых функций](#--13)
         - [Линковка сервисов](#--14)
         - [DNS конфигурация](#dns-)
         - [SSL настройка](#ssl-)
         - [Конфигурация баз данных](#--15)
      + [Файлы конфигурации](#--16)
      + [Особенности работы](#--17)
      + [Рекомендуемая последовательность](#--18)
- [2. Ручная настройка ](#2-)
   * [2.0 Локальная установка по HTTP (без nginx)](#20-http-nginx)
   * [2.16 Локальная установка по HTTP — ручной порядок](#216-http-manual)
   * [2.1 Установите Docker](#21-docker)
   * [2.2 Провести настройку Nginx](#22-nginx)
      + [2.2.1 Подготовка структуры директорий](#221-)
      + [2.2.2 Получение SSL сертификатов через Certbot](#222-ssl-certbot)
      + [2.2.3 Генерация конфигурации Nginx для UnicChat и Базы знаний](#223-nginx-unicchat-)
      + [2.2.4 Запуск и активация Nginx](#224-nginx)
      + [2.2.6 Настройка автоматического обновления сертификатов Certbot](#226-certbot)
   * [2.3 Открыть доступы до внутренних ресурсов](#23-)
      + [Входящие соединения на стороне сервера UnicChat:](#-unicchat-2)
      + [Исходящие соединения на стороне сервера UnicChat на push:](#-unicchat-push)
      + [Исходящие соединения на стороне сервера UnicChat на ВКС:](#-unicchat-)
- [Шаг 3. Установка локального медиа сервера для ВКС](#-3-)
   * [3.1 Порядок установки сервера](#31-)
   * [3.2 Проверка открытия портов](#32-)
      + [Обязательные порты](#--19)
         - [TCP порты:](#tcp-)
         - [UDP порты:](#udp-)
         - [Опциональные порты](#--20)
- [Шаг 4. Развертывание базы знаний для UNICCHAT](#-4-unicchat)
   * [4.4 Развертывание MinIO S3](#44-minio-s3)
      + [4.4.1 Создание переменных окружения для Базы Знаний](#441-)
      + [4.4.2 Запустите Базу Знаний](#442-)
      + [4.4.3 Доступ к MinIO:](#443-minio)
      + [4.4.4 Создание bucket](#444-bucket)
      + [4.4.5 Настройка DNS записей для проксирования](#445-dns-)
- [Шаг 5. Установка UnicChat](#-5-unicchat)
   * [5.1 Настройка Unic.Chat](#51-unicchat)
   * [5.2 Раздать права пользователю для подключения к базе](#52-)
- [Шаг 6. Создание пользователя администратора](#-6-)
- [Шаг 7. Настройка push-уведомлений](#-7-push-)
- [Опциональные компоненты](#--21)
   * [Шаг 8. Настройка unicvault](#-8-unicvault)
   * [Шаг 9. Настройка redminebot](#-9-redminebot)
   * [Важные замечания](#--22)
- [Клиентские приложения](#--23)

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

Проект использует модульную архитектуру с отдельными скриптами для каждого компонента:
- **`unicchat.sh`** — главный скрипт установки UnicChat (основное приложение, MongoDB, Vault, Logger, AppServer, Tasker, MinIO, DocumentServer и др.). **Не вызывает** другие скрипты.
- **`nginx/generate_ssl.sh`** — скрипт настройки NGINX и SSL (Let's Encrypt). Запускается **отдельно**, не из `unicchat.sh`.

ВКС устанавливается отдельным скриптом (см. раздел "Шаг 3. Установка локального медиа сервера для ВКС").

<div style="background-color: #ff0000; border: 4px solid #cc0000; padding: 20px; margin: 30px 0; border-radius: 8px; color: #ffffff; font-weight: bold;">
  
### 🚨 КРИТИЧЕСКИ ВАЖНО: ЛИЦЕНЗИЯ ОБЯЗАТЕЛЬНА ПЕРЕД УСТАНОВКОЙ

**⚠️ ВНИМАНИЕ! Перед началом установки UnicChat Enterprise ОБЯЗАТЕЛЬНО необходимо:**

1. **📋 Запросить лицензию** у поставщика или администратора системы
2. **⚙️ Установить лицензию** в переменную окружения `UniCommLicenseData` перед запуском Docker Compose
3. **✅ Проверить**, что лицензия корректно передана во все сервисы

**❌ БЕЗ ДЕЙСТВУЮЩЕЙ ЛИЦЕНЗИИ СИСТЕМА НЕ БУДЕТ РАБОТАТЬ КОРРЕКТНО!**

**Как установить лицензию:**

```bash
# Экспортируйте переменную окружения с лицензией
export UniCommLicenseData="ваша_лицензия_здесь"

# Или добавьте в файл export_variables.txt:
# export UniCommLicenseData="ваша_лицензия_здесь"
```

> **⚠️ ВАЖНО**: Лицензия используется всеми сервисами (Backend, Frontend, Logger, Vault, Tasker). Убедитесь, что переменная `UniCommLicenseData` экспортирована перед запуском `docker-compose up`.

</div>


---

<!-- TOC --><a name="-unicchatsh"></a>
### 1. Скрипт установки UnicChat (`unicchat.sh`)

Интерактивный скрипт с меню. Читает и пишет конфиги в корне проекта (`dns_config.txt`, `mongo_config.txt`, `minio_config.txt`), генерирует файлы в `multi-server-install/` и запускает контейнеры из `multi-server-install/docker-compose.yml`.

<!-- TOC --><a name="-unicchatsh-1"></a>
#### Запуск

```shell
chmod +x ./unicchat.sh
sudo ./unicchat.sh
```

Требуется root (Docker, логи).

<!-- TOC --><a name="--7"></a>
#### Меню скрипта

Текст пунктов меню совпадает с выводом скрипта.

| № | Пункт меню | Что делает |
|---|------------|------------|
| **1** | Check AVX support | Проверяет наличие AVX в `/proc/cpuinfo`; выводит, можно ли использовать MongoDB 5.x+ или нужна 4.4. |
| **2** | Setup DNS names for services (APP, EDT, MinIO) | Запрашивает APP_DNS, EDT_DNS, MINIO_DNS, PUSH_DNS; сохраняет в `dns_config.txt`; проверяет резолвинг через `dig`. |
| **3** | Update MongoDB configuration | Интерактивно задаёт параметры MongoDB (root, пользователь приложения, база, пользователи Logger и Vault); сохраняет в `mongo_config.txt`. |
| **4** | Update MinIO configuration | Интерактивно задаёт MINIO_ROOT_USER и MINIO_ROOT_PASSWORD; сохраняет в `minio_config.txt`. |
| **5** | Prepare .env files | Читает `dns_config.txt`, `mongo_config.txt`, `minio_config.txt` и создаёт в `multi-server-install/` файлы: `mongo.env`, `mongo_creds.env`, `appserver.env`, `appserver_creds.env`, `logger.env`, `logger_creds.env`, `vault_creds.env`, `env/minio_env.env`, `env/documentserver_env.env`. Перед этим должны быть выполнены пункты 2, 3, 4. |
| **6** | Login to Yandex registry | Выполняет `docker login` в Yandex Container Registry (образы для контейнеров). |
| **7** | Create Docker network | Создаёт сеть `unicchat-network`, если её ещё нет. |
| **8** | Start UnicChat containers | Запускает `docker compose -f multi-server-install/docker-compose.yml up -d`. Все сервисы (MongoDB, Vault, Logger, AppServer, Tasker, MinIO, DocumentServer, RabbitMQ, PostgreSQL и др.) описаны в этом одном файле. |
| **9** | Setup MongoDB users (separate DB per service) | Подключается к уже запущенному контейнеру MongoDB, создаёт базы и пользователей для Logger и Vault по данным из `logger_creds.env` и `vault_creds.env`. Имеет смысл после [8]. |
| **10** | Setup Vault secrets for KBT service | Обращается к API контейнера Vault, получает токен и создаёт секрет KBTConfigs (MongoDB, MinIO) для сервиса KBT. Имеет смысл после [8] и [9]. |
| **11** | Restart all services | Выполняет `docker compose -f multi-server-install/docker-compose.yml restart`. |
| **99** | 🚀 Full automatic setup | Последовательно: check_avx, setup_dns_names, update_mongo_config, update_minio_config, create_network, prepare_all_envs, login_yandex, start_unicchat; пауза 15 сек; setup_mongodb_users; пауза 10 сек; setup_vault_secrets. В конце выводит URL по APP_DNS, EDT_DNS, MINIO_DNS. |
| **101** | Patch env for local HTTP (AppServer + DocumentServer) | `prepare_local_http_envs`: только после [5]. Подставляет LAN-IP в `appserver.env` (`ROOT_URL`, `DOCUMENT_SERVER_HOST`) и выставляет `UNIC_SOLID_HOST=http://unicchat-tasker:8080`; в `env/documentserver_env.env` отключает JWT и включает `ALLOW_PRIVATE_IP_ADDRESS` / `ALLOW_META_IP_ADDRESS` для работы с MinIO в Docker-сети. |
| **102** | Setup Vault KBTConfigs (local HTTP MinIO) | `setup_vault_secrets_local`: как [10], но секрет `KBTConfigs` с `MinioHost=unicchat-minio:9000`, `MinioSecure="false"` (HTTP), при необходимости удаляет старый секрет перед созданием. |
| **103** | 🚀 Full automatic setup (локальный HTTP) | `local_http_auto_setup`: [1]→[3]→[4]→[5]→[101]→[6]→[7]→[8]→[9]→[102]→[11] без nginx и публичных HTTPS-URL. |
| **100** | 🗑️ Cleanup (remove containers & volumes) | Запрос подтверждения (`yes`). Затем: `docker compose -f multi-server-install/docker-compose.yml down -v`, удаление образов (unicchat, unic, uniceditor, minio, mongodb, rabbitmq, postgres), удаление сети `unicchat-network`, удаление сгенерированных .env в `multi-server-install/`. Каталоги не удаляет. |
| **0** | Exit | Выход из скрипта. |

После пункта **[99]** в том же меню выводится блок **«Локальная установка по HTTP (без HTTPS / nginx)»**: номера **[1]**, **[3]**–**[9]**, **[11]** вызывают **те же действия**, что и в верхней части меню; блок напоминает рекомендуемый порядок шагов для HTTP-only стенда. Перед каждым показом меню вызывается `ensure_local_dns_placeholder` — если нет `dns_config.txt`, создаётся заглушка (можно обойтись без пункта **[2]** до генерации .env). Ручной порядок для клиента — в **[2.16](#216-http-manual)**; кратко — **[2.0](#20-http-nginx)**.

<!-- TOC --><a name="unicchatsh-functions"></a>
#### Основные функции в `unicchat.sh`

Ниже — внутренние функции скрипта (имена совпадают с кодом). Пункты меню **[1]**–**[11]**, **[99]**, **[100]** вызывают их напрямую или через цепочки.

| Функция | Назначение |
|---------|------------|
| `check_docker` | Проверка наличия Docker и Compose перед запуском меню. |
| `docker_compose` | Вызов `docker compose` или fallback на `docker-compose`. |
| `log_info` / `log_success` / `log_warning` / `log_error` | Сообщения в консоль и в `unicchat_install.log`. |
| `load_dns_config` | Загрузка `dns_config.txt` при старте `main_menu`. |
| `setup_dns_names` | Интерактивная настройка DNS-имён, запись `dns_config.txt`. |
| `urlencode` / `urldecode` | Кодирование паролей в строках подключения MongoDB для .env. |
| `update_mongo_config` | Интерактивное заполнение `mongo_config.txt`. |
| `update_minio_config` | Интерактивное заполнение `minio_config.txt`. |
| `prepare_all_envs` | Генерация `mongo.env`, `mongo_creds.env`, `appserver.env`, `appserver_creds.env`, `logger.env`, `logger_creds.env`, `vault_creds.env`, `env/minio_env.env`, `env/documentserver_env.env` в `multi-server-install/`. |
| `setup_mongodb_users` | Создание БД и пользователей MongoDB для Logger и Vault по `logger_creds.env` / `vault_creds.env`. |
| `setup_vault_secrets` | Ожидание Vault, получение JWT, создание секрета `KBTConfigs` (MongoCS из logger, MinIO из DNS-конфига). |
| `ensure_local_dns_placeholder` | Если нет `dns_config.txt` — создаёт минимальный файл для прохождения `prepare_all_envs` без пункта [2]. |
| `prepare_local_http_envs` | Правка env под локальный HTTP (см. пункт меню [101]). |
| `setup_vault_secrets_local` | Секрет `KBTConfigs` для HTTP и внутреннего MinIO (см. пункт [102]). |
| `local_http_auto_setup` | Полный автоматический сценарий локального HTTP (пункт [103]; тот же порядок вручную — [раздел 2.16](#216-http-manual)). |
| `login_yandex` | `docker login` в Yandex Container Registry. |
| `create_network` | Создание внешней сети `unicchat-network`. |
| `start_unicchat` | `docker compose up -d` в `multi-server-install/`, инициализация bucket MinIO для OnlyOffice. |
| `restart_unicchat` | Перезапуск всех сервисов compose. |
| `cleanup_all` | Остановка, удаление томов и сгенерированных env (п. [100]). |
| `auto_setup` | Полная автоматическая установка для сценария с DNS и HTTPS-URL в .env (п. [99]). |
| `main_menu` | Главный цикл меню и обработка выбора. |

<!-- TOC --><a name="--16"></a>
#### Что использует скрипт

- **В корне проекта:** `dns_config.txt`, `mongo_config.txt`, `minio_config.txt` (создаются/обновляются пунктами 2–4); `unicchat_install.log` (лог).
- **Каталог `multi-server-install/`:** скрипт генерирует там .env-файлы (п. 5) и всегда запускает только один compose-файл: `multi-server-install/docker-compose.yml`. Состав сервисов — по этому файлу (MongoDB, Vault, Logger, AppServer, Tasker, MinIO, DocumentServer, RabbitMQ, PostgreSQL и вспомогательные).

---

<!-- TOC --><a name="-nginx-ssl"></a>
### 2. Скрипт развёртки NGINX (`nginx/generate_ssl.sh`)

Скрипт для управления SSL (Let's Encrypt) и контейнером nginx. Читает домены из `../dns_config.txt` (должен быть создан, например, через `unicchat.sh`). Работает из каталога `nginx/`: использует локальный `docker-compose.yml`, создаёт `config/nginx.conf`, сертификаты в `ssl/`. Не вызывается из `unicchat.sh` — запускается отдельно.

#### Запуск

```shell
cd nginx
sudo ./generate_ssl.sh
```

Требуется root (порты 80/443, Docker).

#### Меню скрипта

Текст пунктов совпадает с выводом в терминале.

| № | Пункт меню | Что делает |
|---|------------|------------|
| **1** | 🔐 Генерация SSL сертификатов (Let's Encrypt) | Загружает `../dns_config.txt` и при необходимости email из `../unicchat_config.txt`. Проверяет наличие `ssl/options-ssl-nginx.conf`; при отсутствии генерирует `ssl/ssl-dhparams.pem` (DH 2048). Создаёт сеть `unicchat-network` при необходимости. Останавливает контейнер nginx, проверяет занятость портов 80/443. Запускает контейнер Certbot (standalone), получает сертификаты для APP_DNS, EDT_DNS, MINIO_DNS. Генерирует `config/nginx.conf` и запускает nginx. |
| **2** | 📝 Генерация/обновление конфигурации nginx | Читает `../dns_config.txt` и записывает один файл `config/nginx.conf`: upstream app_server (unicchat-appserver:3000), doc_server (unicchat-documentserver:80), minio_server (9000); виртуальные хосты для APP_DNS, EDT_DNS, MINIO_DNS (HTTPS 443 + HTTP 80 с редиректом). Подключение к сертификатам в `ssl/live/$APP_DNS/`. |
| **3** | 🌐 Запуск nginx | Проверяет сеть `unicchat-network`, при наличии сертификатов в `ssl/live/$APP_DNS/` вызывает генерацию конфига и выполняет `docker compose up -d nginx`. Проверяет, что контейнер запущен и `nginx -t` успешен. |
| **4** | 🛑 Остановка nginx | `docker compose stop nginx` или `docker stop unicchat-nginx`. |
| **5** | 🔄 Перезапуск nginx | При наличии сертификатов обновляет `config/nginx.conf`, затем перезапускает контейнер nginx. |
| **6** | 📊 Статус сервисов | Выводит статус контейнеров unicchat-nginx и unicchat-certbot (в т.ч. healthcheck), наличие и срок действия SSL в `ssl/live/$APP_DNS/`, порты 80/443. |
| **7** | 📋 Логи nginx | Последние 50 строк логов контейнера unicchat-nginx. |
| **8** | 🔍 Проверка конфигурации nginx | В запущенном контейнере выполняет `nginx -t`. |
| **99** | 🚀 Полная автоустановка (SSL + nginx) | По шагам: генерация SSL (п. 1), запуск nginx (п. 3), `docker compose up -d certbot`, вывод статуса (п. 6). |
| **0** | 🚪 Выход | Выход из скрипта. |

#### Что использует скрипт

- **Конфиг:** `../dns_config.txt` (APP_DNS, EDT_DNS, MINIO_DNS); при первом запросе email — `../unicchat_config.txt`.
- **В каталоге `nginx/`:** `docker-compose.yml` (сервисы nginx и certbot), генерируемый `config/nginx.conf`, каталог `ssl/` (в т.ч. `options-ssl-nginx.conf`, `ssl-dhparams.pem`, `live/<домен>/` от Certbot). Сертификаты общие для всех трёх доменов (один мультидоменный от Let's Encrypt).


<!-- TOC --><a name="--18"></a>
#### Рекомендуемая последовательность полной установки

**Для полной установки всех компонентов:**

1. **Установка UnicChat (основное приложение):**
   ```bash
   sudo ./unicchat.sh
   # Выберите [99] - Full automatic setup
   ```
   Для **локального стенда только по HTTP** (без nginx/HTTPS): **[2.0](#20-http-nginx)** и пошагово **[2.16](#216-http-manual)**; в меню `unicchat.sh` — блок «Локальная установка по HTTP», пункт **[103]** или цепочка **[101]**/**[102]**.

2. **Настройка NGINX и SSL:**
   ```bash
   cd nginx
   sudo ./generate_ssl.sh
   # Выберите [99] - Полная автоустановка (SSL + nginx)
   ```



**Важно:** Убедитесь, что DNS записи настроены и указывают на IP вашего сервера перед запуском скрипта NGINX/SSL.

<!-- TOC --><a name="2-"></a>
## 2. Ручная настройка 

В этом разделе описана полностью ручная установка всех компонентов UnicChat без использования автоматизированных скриптов. Все действия выполняются системным администратором.

<!-- TOC --><a name="20-http-nginx"></a>
### 2.0 Локальная установка по HTTP (без nginx и HTTPS)

Для **внутреннего или тестового стенда** UnicChat можно развернуть **только по HTTP**, без reverse-proxy nginx и без публичных HTTPS-URL в конфигурации приложения. Проброс портов на хост задаётся в [`multi-server-install/docker-compose.yml`](multi-server-install/docker-compose.yml) (типично: приложение **8080**, DocumentServer **8880**, при необходимости Vault **8200**, MinIO **9000** / консоль **9002**).

**Автоматизация:** `sudo ./unicchat.sh` → после пункта меню **[99]** блок «Локальная установка по HTTP» → **[103]** (полная цепочка) или отдельные **[101]** и **[102]** по таблице [«Меню скрипта»](#--7).

**Ручной порядок** совпадает с логикой скрипта и собран в конце этой главы: **[2.16 Локальная установка по HTTP — ручной порядок](#216-http-manual)**. Перед запуском контейнеров задайте переменную **`UniCommLicenseData`** (см. [шаг 1.2](#12-unicchat-solid-core) и разделы про запуск compose ниже).

Промышленная установка с доменами и **HTTPS** описана далее в этой главе (nginx, Certbot) и в пункте **[99]** `unicchat.sh`.

<!-- TOC --><a name="21-docker"></a>
### 2.1 Установите Docker

Установите Docker и Docker Compose согласно официальной документации:
https://docs.docker.com/engine/install/

Убедитесь, что Docker и Docker Compose установлены:
```shell
docker --version
docker compose version
```

Запустите Docker daemon:
```shell
sudo systemctl start docker
sudo systemctl enable docker
```

Проверьте, что Docker работает:
```shell
docker info
```

<!-- TOC --><a name="22-avx"></a>
### 2.2 Проверка поддержки AVX процессором

MongoDB версии 5.x и выше требуют поддержки инструкций AVX процессором. Проверьте наличие AVX:

```shell
grep avx /proc/cpuinfo
```

**Результат проверки:**
- Если команда выводит строки с `avx` - используйте MongoDB 5.x или выше
- Если вывода нет - используйте MongoDB 4.4 или ниже

<!-- TOC --><a name="23-dns"></a>
### 2.3 Настройка DNS имён

Подготовьте DNS-имена для ваших сервисов. Вам потребуется минимум 3 домена:

1. **APP_DNS** - основное приложение UnicChat (например, `myapp.unic.chat`)
2. **EDT_DNS** - сервер документов DocumentServer (например, `myedt.unic.chat`)
3. **MINIO_DNS** - объектное хранилище MinIO (например, `myminio.unic.chat`)

Убедитесь, что DNS-записи настроены и указывают на IP-адрес вашего сервера. Проверьте разрешение имён:

```shell
dig +short myapp.unic.chat
dig +short myedt.unic.chat
dig +short myminio.unic.chat
```

Если DNS ещё не настроен публично, но вы хотите продолжить установку, добавьте записи в `/etc/hosts`:

```shell
sudo nano /etc/hosts
```

Добавьте строки (замените IP на адрес вашего сервера):
```
<IP_СЕРВЕРА> myapp.unic.chat
<IP_СЕРВЕРА> myedt.unic.chat
<IP_СЕРВЕРА> myminio.unic.chat
```

<!-- TOC --><a name="24-network"></a>
### 2.4 Создание Docker-сети

Создайте Docker-сеть для связи между контейнерами:

```shell
docker network create unicchat-network
```

Проверьте создание сети:
```shell
docker network ls | grep unicchat-network
```

<!-- TOC --><a name="25-"></a>
### 2.5 Подготовка конфигурационных файлов

Перейдите в директорию `multi-server-install/`:
```shell
cd multi-server-install/
```

#### 2.5.1 Конфигурация MongoDB

Создайте файл `mongo.env` для настройки MongoDB Replica Set:

```shell
nano mongo.env
```

Содержимое файла:
```ini
# Replica Set Configuration
MONGODB_REPLICA_SET_MODE=primary
MONGODB_REPLICA_SET_NAME=rs0
MONGODB_REPLICA_SET_KEY=rs0key
MONGODB_PORT_NUMBER=27017
MONGODB_INITIAL_PRIMARY_HOST=unicchat-mongodb
MONGODB_INITIAL_PRIMARY_PORT_NUMBER=27017
MONGODB_ADVERTISED_HOSTNAME=unicchat-mongodb
MONGODB_ENABLE_JOURNAL=true
```

**Важно:** Если MongoDB будет установлена на отдельном сервере, замените значения `MONGODB_INITIAL_PRIMARY_HOST` и `MONGODB_ADVERTISED_HOSTNAME` на IP-адрес или DNS-имя сервера БД.

Создайте файл `mongo_creds.env` с учётными данными:

```shell
nano mongo_creds.env
```

Содержимое файла (замените пароли на свои):
```ini
# MongoDB Authentication
MONGODB_ROOT_PASSWORD=rootpass_change_me
MONGODB_USERNAME=unicchat_admin
MONGODB_PASSWORD=secure_password_change_me
MONGODB_DATABASE=unicchat_db
```

Установите ограниченные права доступа:
```shell
chmod 600 mongo_creds.env
```

#### 2.5.2 Конфигурация AppServer

Создайте файл `appserver.env`:

```shell
nano appserver.env
```

Содержимое файла (замените домены на свои):
```ini
# UnicChat AppServer Configuration
ROOT_URL=https://myapp.unic.chat
DOCUMENT_SERVER_HOST=https://myedt.unic.chat
LICENSE_HOST=https://push1.unic.chat/
PORT=3000
DEPLOY_METHOD=docker
DB_COLLECTIONS_PREFIX=unicchat_
MONGODB_HOST=unicchat-mongodb
MONGODB_PORT=27017
```

Создайте файл `appserver_creds.env` с подключением к MongoDB:

```shell
nano appserver_creds.env
```

Содержимое файла (используйте данные из `mongo_creds.env`):
```ini
# UnicChat AppServer Credentials
MONGO_URL=mongodb://unicchat_admin:secure_password_change_me@unicchat-mongodb:27017/unicchat_db?replicaSet=rs0
MONGO_OPLOG_URL=mongodb://unicchat_admin:secure_password_change_me@unicchat-mongodb:27017/local
```

Установите ограниченные права:
```shell
chmod 600 appserver_creds.env
```

#### 2.5.3 Конфигурация Logger

Создайте файл `logger.env`:

```shell
nano logger.env
```

Содержимое:
```ini
# Logger API URL (internal)
api.logger.url=http://unicchat-logger:8080/
```

Создайте файл `logger_creds.env` (замените пароль):

```shell
nano logger_creds.env
```

Содержимое:
```ini
# MongoDB connection for logger service
MongoCS="mongodb://logger_user:logger_pass_change_me@unicchat-mongodb:27017/logger_db?directConnection=true&authSource=logger_db&authMechanism=SCRAM-SHA-256"
```

Установите права:
```shell
chmod 600 logger_creds.env
```

#### 2.5.4 Конфигурация Vault

Создайте файл `vault_creds.env`:

```shell
nano vault_creds.env
```

Содержимое:
```ini
# MongoDB connection for vault service
MongoCS="mongodb://vault_user:vault_pass_change_me@unicchat-mongodb:27017/vault_db?directConnection=true&authSource=vault_db&authMechanism=SCRAM-SHA-256"
```

Установите права:
```shell
chmod 600 vault_creds.env
```

#### 2.5.5 Конфигурация MinIO

Создайте директорию для конфигов MinIO:
```shell
mkdir -p env
```

Создайте файл `env/minio_env.env`:

```shell
nano env/minio_env.env
```

Содержимое (замените учётные данные и домен):
```ini
# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin_pass_change_me
MINIO_BROWSER=on
MINIO_DOMAIN=myminio.unic.chat
```

#### 2.5.6 Конфигурация DocumentServer

Создайте файл `env/documentserver_env.env`:

```shell
nano env/documentserver_env.env
```

Содержимое:
```ini
# DocumentServer Configuration
JWT_ENABLED=true
JWT_SECRET=your_jwt_secret_change_me
JWT_HEADER=Authorization
DB_TYPE=postgres
DB_HOST=unicchat-postgresql
DB_PORT=5432
DB_NAME=dbname
DB_USER=dbuser
AMQP_URI=amqp://guest:guest@unicchat-rabbitmq
```

Вернитесь в корневую директорию проекта:
```shell
cd ..
```

<!-- TOC --><a name="26-registry"></a>
### 2.6 Авторизация в Container Registry

Выполните вход в Yandex Container Registry для доступа к образам:

```shell
docker login --username oauth \
  --password y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ \
  cr.yandex
```

<!-- TOC --><a name="27-unicchat"></a>
### 2.7 Запуск сервисов UnicChat

Запустите все сервисы из корневой директории проекта:

```shell
docker compose -f multi-server-install/docker-compose.yml up -d
```

Проверьте запуск контейнеров:
```shell
docker ps
```

Вы должны увидеть следующие контейнеры:
- `unicchat-mongodb`
- `unicchat-appserver`
- `unicchat-vault`
- `unicchat-logger`
- `unicchat-tasker`
- `unicchat-minio`
- `unicchat-documentserver`
- `unicchat-rabbitmq`
- `unicchat-postgresql`

Дождитесь полного запуска всех сервисов (это может занять 1-2 минуты). Проверьте логи:
```shell
docker logs unicchat-mongodb
docker logs unicchat-appserver
```

<!-- TOC --><a name="28-mongodb"></a>
### 2.8 Настройка пользователей MongoDB

После запуска MongoDB необходимо создать пользователей для служб Logger и Vault.

#### 2.8.1 Проверка готовности MongoDB

Подождите, пока MongoDB полностью запустится (15-30 секунд). Проверьте готовность:

```shell
docker exec unicchat-mongodb mongosh -u root -p "rootpass_change_me" --quiet --eval "db.adminCommand('ping')"
```

Если команда возвращает `{ ok: 1 }`, MongoDB готов к работе.

#### 2.8.2 Создание пользователя Logger

Подключитесь к MongoDB:

```shell
docker exec -it unicchat-mongodb mongosh -u root -p "rootpass_change_me" --authenticationDatabase admin
```

В консоли MongoDB выполните:

```javascript
use admin
db = db.getSiblingDB('logger_db')
db.createUser({
  user: 'logger_user',
  pwd: 'logger_pass_change_me',
  roles: [{ role: 'readWrite', db: 'logger_db' }]
})
```

Если пользователь уже существует, обновите пароль:
```javascript
db.changeUserPassword('logger_user', 'logger_pass_change_me')
```

#### 2.8.3 Создание пользователя Vault

В той же консоли MongoDB выполните:

```javascript
use admin
db = db.getSiblingDB('vault_db')
db.createUser({
  user: 'vault_user',
  pwd: 'vault_pass_change_me',
  roles: [{ role: 'readWrite', db: 'vault_db' }]
})
```

Если пользователь уже существует:
```javascript
db.changeUserPassword('vault_user', 'vault_pass_change_me')
```

Выйдите из консоли:
```javascript
exit
```

<!-- TOC --><a name="29-vault"></a>
### 2.9 Настройка секретов Vault для KBT

Сервис KBT (Knowledge Base Tasker) использует Vault для хранения конфигурации подключения к MongoDB и MinIO.

#### 2.9.1 Установка curl в контейнер Vault (если требуется)

Проверьте наличие curl в контейнере:

```shell
docker exec unicchat-vault bash -c "command -v curl"
```

Если curl отсутствует, установите его:

```shell
docker exec -u root unicchat-vault bash -c "apt-get update && apt-get install -y curl"
```

#### 2.9.2 Получение токена доступа к Vault

Подождите, пока Vault полностью запустится (10-15 секунд). Получите JWT токен:

```shell
VAULT_TOKEN=$(docker exec unicchat-vault bash -c "curl -s 'http://localhost:80/api/token/0f8e160416b94225a73f86ac23b9118b?username=KBTservice'")
echo "Token: $VAULT_TOKEN"
```

Токен должен иметь формат JWT (три части, разделённые точками).

#### 2.9.3 Создание секрета KBTConfigs

Создайте секрет с конфигурацией MongoDB и MinIO. Замените значения на ваши реальные данные:

```shell
docker exec unicchat-vault bash -c "curl -X POST 'http://localhost:80/api/Secrets' \
  -H 'Authorization: Bearer $VAULT_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'accept: text/plain' \
  -d '{
    \"id\": \"KBTConfigs\",
    \"name\": \"KBTConfigs\",
    \"type\": \"Password\",
    \"data\": \"All info in META\",
    \"metadata\": {
      \"MongoCS\": \"mongodb://logger_user:logger_pass_change_me@unicchat-mongodb:27017/logger_db?directConnection=true&authSource=logger_db&authMechanism=SCRAM-SHA-256\",
      \"MinioHost\": \"myminio.unic.chat\",
      \"MinioUser\": \"minioadmin\",
      \"MinioPass\": \"minioadmin_pass_change_me\"
    },
    \"tags\": [\"KB\", \"Tasker\", \"Mongo\", \"Minio\"],
    \"expiresAt\": \"2030-12-31T23:59:59.999Z\"
  }'"
```

Проверьте создание секрета:

```shell
docker exec unicchat-vault bash -c "curl -s -X GET 'http://localhost:80/api/Secrets/KBTConfigs' \
  -H 'Authorization: Bearer $VAULT_TOKEN'" | grep KBTConfigs
```

Если в выводе присутствует `KBTConfigs`, секрет успешно создан.

<!-- TOC --><a name="210-nginx"></a>
### 2.10 Настройка Nginx и SSL сертификатов

#### 2.10.1 Подготовка директорий

Перейдите в директорию nginx:
```shell
cd nginx
```

Создайте необходимые директории:
```shell
mkdir -p ssl www config
chmod 755 ssl www
```

Файл `ssl/options-ssl-nginx.conf` должен присутствовать в репозитории. Проверьте его наличие:
```shell
ls -la ssl/options-ssl-nginx.conf
```

#### 2.10.2 Генерация DH параметров

Сгенерируйте параметры Диффи-Хеллмана для усиления SSL:

```shell
openssl dhparam -out ssl/ssl-dhparams.pem 2048
```

Эта операция может занять несколько минут.

#### 2.10.3 Остановка сервисов на портах 80/443

Перед получением сертификатов убедитесь, что порты 80 и 443 свободны:

```shell
sudo ss -tulpn | grep -E ':(80|443) '
```

Если nginx уже запущен, остановите его:
```shell
docker stop unicchat-nginx 2>/dev/null || true
docker rm unicchat-nginx 2>/dev/null || true
```

#### 2.10.4 Получение SSL сертификатов через Let's Encrypt

Запустите Certbot для получения сертификатов. Замените `your-email@example.com` на ваш реальный email и домены на ваши:

```shell
docker run --rm \
  --network unicchat-network \
  -p 80:80 \
  -p 443:443 \
  -v "$(pwd)/ssl:/etc/letsencrypt" \
  certbot/certbot certonly \
  --standalone \
  --preferred-challenges http \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  --non-interactive \
  --verbose \
  -d myapp.unic.chat \
  -d myedt.unic.chat \
  -d myminio.unic.chat
```

**Важно:** 
- Используйте действительный email! Let's Encrypt требует валидный email для уведомлений.
- Убедитесь, что DNS-записи настроены и указывают на ваш сервер.
- Порты 80 и 443 должны быть доступны из интернета.

Сертификаты будут сохранены в `ssl/live/myapp.unic.chat/`.

#### 2.10.5 Создание конфигурации Nginx

Создайте конфигурационный файл Nginx:

```shell
nano config/nginx.conf
```

Вставьте следующее содержимое (замените `myapp.unic.chat`, `myedt.unic.chat`, `myminio.unic.chat` на ваши домены):

```nginx
# Nginx configuration for UnicChat Enterprise

# Upstream для App Server
upstream app_server {
    server unicchat-appserver:3000;
}

# Upstream для Document Server  
upstream doc_server {
    server unicchat-documentserver:80;
}

# Upstream для MinIO
upstream minio_server {
    server unicchat-minio:9000;
}

# ============================================================================
# App Server (UnicChat Application)
# ============================================================================
server {
    listen 443 ssl;
    http2 on;
    server_name myapp.unic.chat;

    client_max_body_size 200M;

    error_log /var/log/nginx/app.error.log;
    access_log /var/log/nginx/app.access.log;

    # CORS headers
    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Credentials true;
    add_header "Access-Control-Allow-Methods" "GET, POST, OPTIONS, HEAD, PUT, DELETE";
    add_header "Access-Control-Allow-Headers" "Authorization, Origin, X-Requested-With, Content-Type, Accept";

    # Preflight requests
    if ($request_method = OPTIONS) {
        return 204;
    }

    location / {
        proxy_pass http://app_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Nginx-Proxy true;

        proxy_redirect off;
    }

    ssl_certificate /etc/letsencrypt/live/myapp.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.unic.chat/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name myapp.unic.chat;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# ============================================================================
# Document Server (OnlyOffice)
# ============================================================================
server {
    listen 443 ssl;
    http2 on;
    server_name myedt.unic.chat;

    client_max_body_size 200M;

    error_log /var/log/nginx/edt.error.log;
    access_log /var/log/nginx/edt.access.log;

    location / {
        proxy_pass http://doc_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_redirect off;
    }

    ssl_certificate /etc/letsencrypt/live/myapp.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.unic.chat/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name myedt.unic.chat;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# ============================================================================
# MinIO S3 API
# ============================================================================
server {
    listen 443 ssl;
    http2 on;
    server_name myminio.unic.chat;

    client_max_body_size 500M;

    error_log /var/log/nginx/minio.error.log;
    access_log /var/log/nginx/minio.access.log;

    # Disable buffering for large files
    proxy_buffering off;
    proxy_request_buffering off;

    location / {
        proxy_pass http://minio_server;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # MinIO-specific headers
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-NginX-Proxy true;

        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }

    ssl_certificate /etc/letsencrypt/live/myapp.unic.chat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.unic.chat/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name myminio.unic.chat;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

```

Сохраните файл (Ctrl+O, Enter, Ctrl+X).

#### 2.10.6 Запуск Nginx

Запустите контейнер Nginx:

```shell
docker compose up -d nginx
```

Дождитесь запуска контейнера (2-3 секунды):
```shell
sleep 3
```

Проверьте статус:
```shell
docker ps | grep unicchat-nginx
```

#### 2.10.7 Проверка конфигурации

Проверьте корректность конфигурации Nginx:

```shell
docker exec unicchat-nginx nginx -t
```

Вывод должен содержать:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Если есть ошибки, проверьте файл `config/nginx.conf` и исправьте их.

#### 2.10.8 Настройка автоматического обновления сертификатов

Для автоматического продления сертификатов запустите контейнер Certbot в фоновом режиме:

```shell
docker compose up -d certbot
```

Certbot будет автоматически проверять и обновлять сертификаты каждые 12 часов.

Также рекомендуется добавить задачу в cron для перезагрузки Nginx после обновления:

```shell
crontab -e
```

Добавьте строку:
```
0 7 * * * cd /path/to/unicchat.enterprise/nginx && docker compose run --rm certbot renew --non-interactive && docker restart unicchat-nginx
```

Замените `/path/to/unicchat.enterprise` на абсолютный путь к директории проекта.

Вернитесь в корневую директорию проекта:
```shell
cd ..
```

<!-- TOC --><a name="211-"></a>
### 2.11 Настройка /etc/hosts для MinIO и DocumentServer

**Важно:** Для корректной работы проксирования через NGINX необходимо на серверах с сервисами MinIO и DocumentServer добавить DNS-записи в файл `/etc/hosts`.

Отредактируйте файл `/etc/hosts`:
```shell
sudo nano /etc/hosts
```

Добавьте следующие строки (замените `<IP_NGINX_SERVER>` на IP-адрес сервера с NGINX):
```
<IP_NGINX_SERVER> myminio.unic.chat
<IP_NGINX_SERVER> myedt.unic.chat
```

Сохраните файл и перезапустите сетевую службу:
```shell
sudo systemctl restart systemd-resolved
```

<!-- TOC --><a name="212-minio"></a>
### 2.12 Создание bucket в MinIO

После запуска всех сервисов необходимо создать bucket для хранения документов.

Откройте консоль MinIO в браузере:
```
https://myminio.unic.chat:9002
```

Используйте учётные данные из `multi-server-install/env/minio_env.env`:
- Username: `minioadmin`
- Password: `minioadmin_pass_change_me`

Создайте bucket с именем `uc.onlyoffice.docs`:

**Вариант 1: Через веб-интерфейс**
1. Нажмите "Create Bucket"
2. Введите имя: `uc.onlyoffice.docs`
3. Нажмите "Create"
4. Откройте настройки bucket
5. Установите "Access Policy" на `public`

**Вариант 2: Через утилиту mc**

Установите MinIO Client:
```shell
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/
```

Настройте подключение:
```shell
mc alias set myminio https://myminio.unic.chat minioadmin minioadmin_pass_change_me
```

Создайте bucket и установите публичный доступ:
```shell
mc mb myminio/uc.onlyoffice.docs
mc anonymous set public myminio/uc.onlyoffice.docs
```

<!-- TOC --><a name="213-"></a>
### 2.13 Настройка прав доступа MongoDB для AppServer

После первого запуска UnicChat необходимо настроить права доступа для основного пользователя приложения в MongoDB.

Подключитесь к MongoDB:

```shell
docker exec -it unicchat-mongodb mongosh -u root -p "rootpass_change_me"
```

Проверьте наличие базы данных:
```javascript
show databases
```

Перейдите в базу данных UnicChat и проверьте пользователей:
```javascript
use unicchat_db
show users
```

Обновите права пользователя `unicchat_admin`:

```javascript
db.updateUser("unicchat_admin", {
  roles: [
    {role: "readWrite", db: "local"},
    {role: "readWrite", db: "unicchat_db"},
    {role: "dbAdmin", db: "unicchat_db"},
    {role: "clusterMonitor", db: "admin"}
  ]
})
```

Проверьте права:
```javascript
show users
```

Выйдите из консоли:
```javascript
exit
```

<!-- TOC --><a name="214-"></a>
### 2.14 Проверка работы установки

Откройте в браузере адрес вашего приложения:
```
https://myapp.unic.chat
```

Если сайт не открывается сразу:
- Очистите кеш браузера (Ctrl+Shift+Del)
- Используйте режим инкогнито
- Выполните жёсткую перезагрузку страницы (Ctrl+F5)

При первом входе создайте пользователя администратора (см. "Шаг 6. Создание пользователя администратора").

Проверьте доступность других сервисов:
- Document Server: `https://myedt.unic.chat`
- MinIO Console: `https://myminio.unic.chat:9002`

<!-- TOC --><a name="215-"></a>
### 2.15 Открытие сетевых доступов и портов

Для корректной работы UnicChat необходимо открыть следующие порты и доступы:

#### Входящие соединения на сервере UnicChat

Откройте порты в firewall:

```shell
# Для HTTP/HTTPS (Nginx)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Для MinIO Console
sudo ufw allow 9002/tcp

# Для ВКС (если устанавливается локальный медиа-сервер)
sudo ufw allow 7881/tcp
sudo ufw allow 7882/udp
sudo ufw allow 50000:60000/udp
```

Проверьте статус firewall:
```shell
sudo ufw status
```

#### Исходящие соединения

Убедитесь, что сервер UnicChat может устанавливать исходящие соединения:

**Для Push-шлюза:**
- 443/TCP на хост **push1.unic.chat**

**Для ВКС-сервера:**
Примечание: **lk-yc.unic.chat** — адрес внешней ВКС компании Unicomm. При развертывании локального медиа-сервера используйте свой адрес.
- 443/TCP на хост **lk-yc.unic.chat**
- 7881/TCP, 7882/UDP
- (50000-60000)/UDP (диапазон портов может быть изменён при развертывании лицензионной версии)

**Для опциональных компонентов:**
- LDAP (обычно 389/TCP или 636/TCP для LDAPS)
- SMTP (обычно 25/TCP, 465/TCP или 587/TCP)
- DNS (53/TCP и 53/UDP)

<!-- TOC --><a name="216-http-manual"></a>
### 2.16 Локальная установка по HTTP — ручной порядок

Ниже — те же шаги, что выполняет сценарий **`local_http_auto_setup`** в `unicchat.sh` (пункт **[103]**), без вызова скрипта. Номера в скобках — соответствующие пункты меню `unicchat.sh`, на которые можно опереться при полуавтоматической установке.

1. **Проверка AVX** — как в [разделе 2.2](#22-avx) (аналог пункта **[1]**).

2. **Имена для генерации .env** — либо заполните `dns_config.txt` по [разделу 2.3](#23-dns), либо создайте минимальный файл в корне репозитория (аналог `ensure_local_dns_placeholder` перед пунктом **[5]**), если отдельная настройка DNS не нужна:
   ```text
   APP_DNS="local-app.local"
   EDT_DNS="local-docs.local"
   MINIO_DNS="unicchat-minio"
   PUSH_DNS="push1.unic.chat"
   ```
   Значения APP/EDT для HTTP-стенда позже заменятся URL с IP в `appserver.env` (шаг 6).

3. **MongoDB** — подготовьте `mongo_config.txt` и файлы окружения по [разделу 2.5](#25-), подраздел про MongoDB (аналог **[3]**).

4. **MinIO** — задайте учётные данные в `minio_config.txt` по [разделу 2.5](#25-) (аналог **[4]**).

5. **Файлы `.env` в `multi-server-install/`** — сформируйте вручную по [разделу 2.5](#25-) так же, как после пункта **[5]** в скрипте (все перечисленные там `*.env` должны существовать до следующего шага).

6. **Правка под локальный HTTP** (аналог **[101]** / `prepare_local_http_envs`, только после шага 5). Подставьте вместо `<LAN-IP>` IP этой машины в LAN (тот адрес, с которого пользователи откроют браузер):
   - В **`multi-server-install/appserver.env`:**  
     `ROOT_URL=http://<LAN-IP>:8080`  
     `DOCUMENT_SERVER_HOST=http://<LAN-IP>:8880`  
     `UNIC_SOLID_HOST=http://unicchat-tasker:8080`
   - В **`multi-server-install/env/documentserver_env.env`:**  
     `JWT_ENABLED=false`  
     `ALLOW_PRIVATE_IP_ADDRESS=true`  
     `ALLOW_META_IP_ADDRESS=true`

7. **Вход в Container Registry** — как в [разделе 2.6](#26-registry) (аналог **[6]**).

8. **Сеть Docker** — создайте внешнюю сеть `unicchat-network`, если её ещё нет ([раздел 2.4](#24-network); аналог **[7]**).

9. **Запуск контейнеров** — экспортируйте `UniCommLicenseData`, затем выполните `docker compose -f multi-server-install/docker-compose.yml up -d` ([раздел 2.7](#27-unicchat); аналог **[8]**). Убедитесь, что при необходимости создан bucket `uc.onlyoffice.docs` в MinIO ([раздел 2.12](#212-minio)).

10. **Пользователи MongoDB для Logger и Vault** — после готовности MongoDB выполните шаги из [раздела 2.8](#28-mongodb) (аналог **[9]**).

11. **Секрет Vault `KBTConfigs` для локального MinIO по HTTP** — по смыслу как [раздел 2.9](#29-vault), но в метаданных секрета укажите **`MinioHost=unicchat-minio:9000`**, **`MinioSecure=false`**, пользователь и пароль MinIO — из вашего `minio_config.txt`, строка подключения MongoDB **`MongoCS`** — из `multi-server-install/logger_creds.env` (аналог **[102]** / `setup_vault_secrets_local`). При необходимости сначала удалите существующий секрет `KBTConfigs` через API Vault, затем создайте заново.

12. **Перезапуск сервисов** — `docker compose -f multi-server-install/docker-compose.yml restart` (аналог **[11]**).

**Не выполняйте** для этого сценария настройку nginx и публичных сертификатов ([раздел 2.10](#210-nginx) и далее по цепочке HTTPS), если цель — только HTTP в локальной сети. Проверка в браузере: адрес из `ROOT_URL` (например `http://<LAN-IP>:8080`).

<!-- TOC --><a name="-3-"></a>
## Шаг 3. Установка локального медиа сервера для ВКС

Подробная инструкция также доступна в **веб-версии** или **в репозитории**:
*   🔗 **Веб:** [github.com/unicommorg/unicchat.enterprise/blob/main/vcs.unic.chat.template/readme.first.md](https://github.com/unicommorg/unicchat.enterprise/blob/main/vcs.unic.chat.template/readme.first.md)
*   📁 **Локальный путь:** `./vcs.unic.chat.template/readme.first.md`

---

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

**Примечание:** Vault уже настроен в разделе "2.9 Настройка секретов Vault для KBT" основной инструкции.

<!-- TOC --><a name="-9-redminebot"></a>
### Шаг 8. Настройка redminebot

Redminebot - это опциональный сервис для интеграции с системой отслеживания задач Redmine.

#### 8.1 Настройка redminebot

Перейдите в директорию redminebot:
```shell
cd redminebot
```

Проверьте файл `redminebot.yml`. По умолчанию он настроен для работы с Vault, но **необходимо изменить сеть** на `unicchat-network`:

```yaml
version: "3.7"
networks:
  unicchat-network:
    external: true
services:
  ucredminebot:
    image: cr.yandex/crpi5ll6mqcn793fvu9i/unic/unicchatbotredmine:prod
    container_name: ucredminebot
    ports:
      - 8201:8080
    environment:
      - Vault__Host=http://unicchat-vault:80
    restart: always
    networks:
      - unicchat-network
```

**Настройка переменной окружения Vault__Host:**

Возможные варианты подключения к Vault:

1. **По имени сервиса Docker** (если redminebot и Vault в одной сети):
   ```
   Vault__Host=http://unicchat-vault:80
   ```

2. **По внутреннему IP-адресу сервера** (если на разных серверах):
   ```
   Vault__Host=http://10.0.X.X:8200
   ```
   где `10.0.X.X` - IP-адрес сервера с Vault

3. **По доменному имени** (если настроен DNS):
   ```
   Vault__Host=http://vault.example.com:8200
   ```

Отредактируйте файл при необходимости:
```shell
nano redminebot.yml
```

Запустите redminebot:
```bash
docker compose -f redminebot.yml up -d
```

Проверьте запуск:
```bash
docker ps | grep ucredminebot
docker logs ucredminebot
```

#### 8.2 Подключение UnicChat к redminebot

Если redminebot запущен, необходимо добавить его адрес в конфигурацию AppServer.

Отредактируйте файл `multi-server-install/docker-compose.yml`:
```bash
cd ../multi-server-install/
nano docker-compose.yml
```

Найдите секцию `unicchat-appserver` и добавьте переменную окружения `REDMINE_BOT_HOST`:

```yaml
  unicchat-appserver:
    container_name: unicchat-appserver
    image: cr.yandex/crpvpl7g37r2id3i2qe5/unic_chat_appserver:prod.6-2.1.83-1
    restart: on-failure
    depends_on:
      unicchat-mongodb:
        condition: service_healthy
      unicchat-vault:
        condition: service_started
    ports:
      - "8080:3000"
    environment:
      - MONGODB_HOST=unicchat-mongodb
      - MONGODB_PORT=27017
      - REDMINE_BOT_HOST=http://ucredminebot:8080  # Добавьте эту строку
    env_file:
      - appserver.env
      - appserver_creds.env
    volumes:
      - chat_data:/app/uploads
    networks:
      - unicchat-network
```

**Возможные значения REDMINE_BOT_HOST:**

1. **Если redminebot в той же Docker-сети:**
   ```yaml
   - REDMINE_BOT_HOST=http://ucredminebot:8080
   ```

2. **Если на другом сервере (по IP):**
   ```yaml
   - REDMINE_BOT_HOST=http://10.0.X.X:8201
   ```

3. **Если по доменному имени:**
   ```yaml
   - REDMINE_BOT_HOST=http://redminebot.example.com:8201
   ```

Перезапустите AppServer:
```bash
docker compose -f docker-compose.yml restart unicchat-appserver
```

Проверьте логи:
```bash
docker logs unicchat-appserver | grep -i redmine
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
