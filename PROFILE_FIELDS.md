# Поля профиля пользователя

## Основная информация (Основная информация)
1. **Имя (name)** - `_nameController`
   - Тип: String
   - Пример: "Водитель PoCho"
   - Поле ввода: TextFormField с иконкой person_outline_rounded

2. **Телефон (phone)** - `_phoneController`
   - Тип: String
   - Пример: "+998 90 123 45 67"
   - Поле ввода: TextFormField с иконкой phone_outlined
   - Тип клавиатуры: TextInputType.phone

3. **Email** - `_emailController`
   - Тип: String
   - Пример: "driver@pocho.uz"
   - Поле ввода: TextFormField с иконкой email_outlined
   - Тип клавиатуры: TextInputType.emailAddress

## Статистика пользователя (_stats)
1. **totalStations** - Количество заправок
   - Тип: int
   - Пример: 127
   - Отображается в шапке профиля

2. **favoriteStations** - Количество избранных станций
   - Тип: int
   - Пример: 8
   - Отображается в шапке профиля

3. **totalSpent** - Всего потрачено (баланс)
   - Тип: double
   - Пример: 1250000.0
   - Отображается в карточке баланса
   - Форматируется с пробелами: "1 250 000 сум"

4. **rating** - Рейтинг пользователя
   - Тип: double
   - Пример: 4.8
   - Отображается в шапке профиля

5. **level** - Уровень пользователя
   - Тип: String
   - Пример: "Золотой"
   - Отображается как badge в шапке профиля

## Документы
1. **Паспорт (passport)**
   - `_passportImagePath` - путь к изображению паспорта
   - `_passportVerified` - статус верификации (bool)
   - Иконка: credit_card_rounded

2. **Водительские права (driving_license)**
   - `_licenseImagePath` - путь к изображению прав
   - `_licenseVerified` - статус верификации (bool)
   - Иконка: drive_eta_rounded

## Достижения (_achievements)
Массив объектов с полями:
- `icon` - IconData (иконка достижения)
- `title` - String (название)
- `description` - String (описание)
- `unlocked` - bool (разблокировано ли)
- `color` - int (цвет в hex формате)

Примеры достижений:
1. Первая заправка
2. Звездный водитель (50+ заправок)
3. Любитель (10+ избранных)
4. Премиум (подписка)

## Настройки
1. **Безопасность**
   - Пароль
   - Двухфакторная аутентификация

2. **Уведомления**
   - Настройка уведомлений

3. **Конфиденциальность**
   - Управление данными

## Дополнительные поля (из user_model.json)
- `id` - int (ID пользователя)
- `avatar` - String? (URL аватара, может быть null)
- `created_at` - DateTime (дата создания)
- `updated_at` - DateTime (дата обновления)
- `language` - String (язык интерфейса, например "ru")

## Структура данных из API (user_model.json)
```json
{
  "user": {
    "id": 1,
    "phone": "+998901234567",
    "name": "Водитель PoCho",
    "email": "driver@pocho.uz",
    "avatar": null,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-12-20T14:25:00Z",
    "language": "ru",
    "balance": 125000.0,
    "level": "Золотой",
    "rating": 4.8,
    "total_stations_visited": 127,
    "total_spent": 1250000.0
  },
  "profile": {
    "documents": {
      "passport": {
        "image_url": null,
        "verified": false,
        "uploaded_at": null
      },
      "driving_license": {
        "image_url": null,
        "verified": false,
        "uploaded_at": null
      }
    },
    "settings": {
      "notifications_enabled": true,
      "language": "ru"
    }
  }
}
```

