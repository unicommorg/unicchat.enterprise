---
gitea: none
include_toc: true
---
# Полная инструкция по развертыванию базы знаний для UNICCHAT



## Шаг 1: Подготовка сервера
Получите DNS имена для сервисов 
* unicchat.solid 
* minio 
* onlyoffice 
* unicchat

Скачайте материалы текущего репозитория.
После скачивания проверьте наличие директорий:
* multi_server_install
* knowledgebase
* nginx

## Шаг 2: Настройка nginx 
Создайте conf файлы для nginx. 
Вы можете разместить nginx на отдельном сервере. 

Инструкция для настройк nginx находится в директории nginx.

!!!ВАЖНО!!!

порты по умолчанию для настройки proxy_pass
* unicchat.solid - 8881
* minio - 9000 (unicchat использует порт api Minio)
* onlyoffice - 8880
* unicchat - 8080


## Шаг 3: Размещение в локальной сети 
В случае необходимости размещение сервисов в локальной сети, настройте локальный DNS или файл /etc/hosts. 
На машины с docker container ваших сервисов: 
 
 * solid 
 * onlyoffice
 * minio
 * unichat
 
 Пример файла /etc/hosts
``` shell 
 10.0.XX.XX myminio.unic.chat
 10.0.XX.XX myonlyoffice.unic.chat
 10.0.XX.XX mysolid.unic.chat
 10.0.XX.XX unic.chat
 ```
## Шаг 4: Развертывание MinIO S3
### 4.1. Перейдите в директорию knowledgebase/minio.
Измените в файле docker-compose.yml значения переменных окружения:
``` yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```
### 4.2 Запустите MinIO:
``` bash
docker-compose up -d
```
### 4.3 Доступ к MinIO:
Консоль: http://ваш_сервер:9002
логин и пароль указан в `yml` файле
``` yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```
### 4.4 Создание bucket
Создайте bucket `uc.onlyoffice.docs` и настройках bucket назначьте Access Policy:public.

S3 Endpoint: http://ваш_сервер:9000

## Шаг 5: Развертывание OnlyOffice
### 5.1 Запуск OnlyOffice
Перейдите в директорию knowledgebase/Docker-DocumentServer.
Запустите docker-compose.yml
``` shell
docker-compose up -d
```
### 5.2 Доступ к OnlyOffice:
Адрес: http://ваш_сервер:8880

## Шаг 6: Редактироваие сервиcа unic.chat.solid
### 6.1 Редактироваие env файла
Перейдите в директорию multi_server_install/app/.
Отредактируйте файл environment.env. 
Добавьте значения переменных окружения minio 
``` yml
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD
```
И dns имя Minio без https.

### 6.2 Пересоздание сервиса unic.chat.solid
Пересоздайте container для unic.chat.solid:
```bash
 docker-compose -f unic.chat.solid.yml down && docker-compose -f unic.chat.solid.yml up -d
```
Доступ: http://ваш_сервер:8881/swagger/index.html 

## Шаг 7: Редактироваие сервиcа unic.chat.appserver
### 7.1: Добавление переменной окружения ONLYOFFICE_HOST 
Перейдите в директорию multi_server_install.
Отредактируйте ввш unic.chat.appserver.yml.
Добавьте в переменные окружения:
``` yml
 - ONLYOFFICE_HOST=https://адрес_в_формате dns
```
### 7.2 Пересоздание сервиса unic.chat.appserver
Запустите:
``` shell
docker-compose -f unic.chat.appserver.yml down && docker-compose -f unic.chat.appserver.yml up -d
```

