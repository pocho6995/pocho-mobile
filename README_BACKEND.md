# PoCho Backend + Admin Panel

Полноценный бэкенд на FastAPI + PostgreSQL и админ-панель на React для управления мобильным приложением PoCho.

## 🚀 Быстрый старт

### 1. Запуск PostgreSQL (Docker)

```bash
cd backend
docker-compose up -d
```

Или установите PostgreSQL локально и создайте базу данных:
```sql
CREATE DATABASE pocho_db;
CREATE USER pocho_user WITH PASSWORD 'pocho_password';
GRANT ALL PRIVILEGES ON DATABASE pocho_db TO pocho_user;
```

### 2. Настройка Backend

```bash
cd backend

# Создайте виртуальное окружение
python -m venv venv

# Активируйте виртуальное окружение
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Установите зависимости
pip install -r requirements.txt

# Создайте .env файл
cp .env.example .env

# Отредактируйте .env (укажите правильный DATABASE_URL и SECRET_KEY)

# Примените миграции
alembic upgrade head

# Создайте админ пользователя
python -m app.initial_data

# Запустите сервер
python run.py
```

Backend будет доступен по адресу: http://localhost:8000
API документация: http://localhost:8000/api/docs

### 3. Настройка Admin Panel

```bash
cd admin-react

# Установите зависимости
npm install

# Создайте .env файл (опционально, по умолчанию используется http://localhost:8000/api/v1)
cp .env.example .env

# Запустите dev сервер
npm run dev
```

Admin Panel будет доступна по адресу: http://localhost:5173

## 📋 Учетные данные по умолчанию

**Email:** admin@pocho.uz  
**Password:** admin123

(Можно изменить в `backend/.env` файле)

## 📁 Структура проекта

```
pocho_new/
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   ├── api/            # API endpoints
│   │   ├── core/           # Настройки и утилиты
│   │   ├── db/             # База данных
│   │   ├── models/         # SQLAlchemy модели
│   │   └── schemas/        # Pydantic схемы
│   ├── alembic/            # Миграции БД
│   ├── requirements.txt    # Python зависимости
│   └── run.py              # Точка входа
│
└── admin-react/            # React Admin Panel
    ├── src/
    │   ├── components/     # React компоненты
    │   ├── pages/          # Страницы админ-панели
    │   └── services/       # API клиент
    └── package.json        # Node зависимости
```

## 🔐 API Endpoints

### Аутентификация
- `POST /api/v1/auth/login` - Вход администратора

### CRUD операции для всех сущностей:
- **Users** - `/api/v1/users/`
- **Stations** - `/api/v1/stations/`
- **Restaurants** - `/api/v1/restaurants/`
- **Car Services** - `/api/v1/car-services/`
- **Car Washes** - `/api/v1/car-washes/`
- **Charging Stations** - `/api/v1/charging-stations/`
- **Advertisements** - `/api/v1/advertisements/`
- **Notifications** - `/api/v1/notifications/`
- **Support Tickets** - `/api/v1/support/`
- **User Requests** - `/api/v1/user-requests/`

Все endpoints требуют JWT токен в заголовке:
```
Authorization: Bearer <token>
```

## 🛠 Технологии

### Backend
- **FastAPI** - современный веб-фреймворк
- **PostgreSQL** - реляционная БД
- **SQLAlchemy** - ORM
- **Alembic** - миграции БД
- **Pydantic** - валидация данных
- **JWT** - аутентификация

### Admin Panel
- **React** - UI библиотека
- **Ant Design** - компоненты UI
- **Axios** - HTTP клиент
- **React Router** - маршрутизация

## 📝 Переменные окружения

### Backend (.env)
```env
DATABASE_URL=postgresql://pocho_user:pocho_password@localhost:5432/pocho_db
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
ADMIN_EMAIL=admin@pocho.uz
ADMIN_PASSWORD=admin123
```

### Admin Panel (.env)
```env
VITE_API_URL=http://localhost:8000/api/v1
```

## 🐛 Решение проблем

### Ошибка подключения к БД
- Убедитесь, что PostgreSQL запущен
- Проверьте правильность DATABASE_URL в .env
- Проверьте права доступа пользователя БД

### Ошибка миграций
```bash
# Пересоздайте миграции
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### CORS ошибки
- Убедитесь, что URL админ-панели добавлен в CORS_ORIGINS

### Проблемы с токеном
- Проверьте SECRET_KEY в .env
- Убедитесь, что токен не истек (по умолчанию 30 минут)

## 📚 Дополнительная документация

- [FastAPI документация](https://fastapi.tiangolo.com/)
- [SQLAlchemy документация](https://docs.sqlalchemy.org/)
- [Ant Design документация](https://ant.design/)

## 🎯 Следующие шаги

1. Настройте production окружение
2. Добавьте обработку файлов (загрузка изображений)
3. Реализуйте отправку уведомлений через Firebase/APNs
4. Добавьте логирование и мониторинг
5. Настройте CI/CD



