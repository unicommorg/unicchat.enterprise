# UnicChat Services - Separate Deployment

Эта директория содержит отдельные docker-compose файлы для каждого сервиса UnicChat.

## Использование

Вы можете запустить сервисы по отдельности на разных серверах:

### MongoDB
```bash
cd multi-server-install/services
docker-compose -f mongodb.yml up -d
```

### AppServer
```bash
cd multi-server-install/services
docker-compose -f appserver.yml up -d
```

### Vault
```bash
cd multi-server-install/services
docker-compose -f vault.yml up -d
```

### Logger
```bash
cd multi-server-install/services
docker-compose -f logger.yml up -d
```

### Tasker
```bash
cd multi-server-install/services
docker-compose -f tasker.yml up -d
```

### MinIO
```bash
cd multi-server-install/services
docker-compose -f minio.yml up -d
```

### DocumentServer
```bash
cd multi-server-install/services
docker-compose -f documentserver.yml up -d
```

## Важно!

1. **Сеть**: Все сервисы должны быть в одной сети `unicchat-network`
2. **Env файлы**: Необходимо создать файлы окружения в директории `multi-server-install/`
3. **Зависимости**: Некоторые сервисы зависят от других (например, AppServer от MongoDB)

## Для распределенной установки

Если сервисы на разных серверах, настройте:

1. Внешнюю сеть (overlay network в Docker Swarm или аналог)
2. Измените `unicchat-mongodb` на реальный IP/hostname MongoDB сервера
3. Аналогично для других зависимостей
