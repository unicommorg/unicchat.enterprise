<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Полная инструкция по развертыванию базы знаний для UNICCHAT](#-unicchat)
   * [Шаг 1: Подготовка сервера](#-1-)
   * [Шаг 2: Настройка nginx ](#-2-nginx)
   * [Шаг 3: Размещение в локальной сети ](#-3-)
   * [Шаг 4: Развертывание MinIO S3](#-4-minio-s3)
      + [4.1. Перейдите в директорию knowledgebase/minio.](#41-knowledgebaseminio)
      + [4.2 Запустите MinIO:](#42-minio)
      + [4.3 Доступ к MinIO:](#43-minio)
      + [4.4 Создание bucket](#44-bucket)
   * [Шаг 5: Развертывание OnlyOffice](#-5-onlyoffice)
      + [5.1 Запуск OnlyOffice](#51-onlyoffice)
      + [5.2 Доступ к OnlyOffice:](#52-onlyoffice)
   * [Шаг 6: Редактироваие сервиcа unic.chat.solid](#-6-c-unicchatsolid)
      + [6.1 Редактироваие env файла](#61-env-)
      + [6.2 Пересоздание сервиса unic.chat.solid](#62-unicchatsolid)
   * [Шаг 7: Редактироваие сервиcа unic.chat.appserver](#-7-c-unicchatappserver)
      + [7.1: Добавление переменной окружения ONLYOFFICE_HOST ](#71-onlyoffice_host)
      + [7.2 Пересоздание сервиса unic.chat.appserver](#72-unicchatappserver)

<!-- TOC end -->


<!-- TOC --><a name="-unicchat"></a>
# Полная инструкция по развертыванию базы знаний для UNICCHAT



<!-- TOC --><a name="-1-"></a>
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

<!-- TOC --><a name="-2-nginx"></a>
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


<!-- TOC --><a name="-3-"></a>
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
<!-- TOC --><a name="-4-minio-s3"></a>
## Шаг 4: Развертывание MinIO S3
<!-- TOC --><a name="41-knowledgebaseminio"></a>
### 4.1. Перейдите в директорию knowledgebase/minio.
Измените в файле docker-compose.yml значения переменных окружения:
``` yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```
<!-- TOC --><a name="42-minio"></a>
### 4.2 Запустите MinIO:
``` bash
docker-compose up -d
```
<!-- TOC --><a name="43-minio"></a>
### 4.3 Доступ к MinIO:
Консоль: http://ваш_сервер:9002
логин и пароль указан в `yml` файле
``` yml
MINIO_ROOT_USER:
MINIO_ROOT_PASSWORD:
```
<!-- TOC --><a name="44-bucket"></a>
### 4.4 Создание bucket
Создайте bucket `uc.onlyoffice.docs` и настройках bucket назначьте Access Policy:public.

S3 Endpoint: http://ваш_сервер:9000

<!-- TOC --><a name="-5-onlyoffice"></a>
## Шаг 5: Развертывание OnlyOffice
<!-- TOC --><a name="51-onlyoffice"></a>
### 5.1 Запуск OnlyOffice
Перейдите в директорию knowledgebase/Docker-DocumentServer.
Запустите docker-compose.yml
``` shell
docker-compose up -d
```
<!-- TOC --><a name="52-onlyoffice"></a>
### 5.2 Доступ к OnlyOffice:
Адрес: http://ваш_сервер:8880

<!-- TOC --><a name="-6-c-unicchatsolid"></a>
## Шаг 6: Редактироваие сервиcа unic.chat.solid
<!-- TOC --><a name="61-env-"></a>
### 6.1 Редактироваие env файла
Перейдите в директорию multi_server_install/app/.
Отредактируйте файл environment.env. 
Добавьте значения переменных окружения minio 
``` yml
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD
```
И dns имя Minio без https.

<!-- TOC --><a name="62-unicchatsolid"></a>
### 6.2 Пересоздание сервиса unic.chat.solid
Пересоздайте container для unic.chat.solid:
```bash
 docker-compose -f unic.chat.solid.yml down && docker-compose -f unic.chat.solid.yml up -d
```
Доступ: http://ваш_сервер:8881/swagger/index.html 

<!-- TOC --><a name="-7-c-unicchatappserver"></a>
## Шаг 7: Редактироваие сервиcа unic.chat.appserver
<!-- TOC --><a name="71-onlyoffice_host"></a>
### 7.1: Добавление переменной окружения ONLYOFFICE_HOST 
Перейдите в директорию multi_server_install.
Отредактируйте ввш unic.chat.appserver.yml.
Добавьте в переменные окружения:
``` yml
 - ONLYOFFICE_HOST=https://адрес_в_формате dns
```
<!-- TOC --><a name="72-unicchatappserver"></a>
### 7.2 Пересоздание сервиса unic.chat.appserver
Запустите:
``` shell
docker-compose -f unic.chat.appserver.yml down && docker-compose -f unic.chat.appserver.yml up -d
```
