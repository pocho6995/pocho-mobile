# Dependency Injection (DI)

Этот проект использует `get_it` для управления зависимостями.

## Структура

- `injection_container.dart` - основной файл для регистрации всех зависимостей

## Использование

### Получение зависимостей

```dart
import 'package:pocho_new/di/injection_container.dart' as di;

// Получить сервис
final stationsService = di.getIt<StationsService>();

// Получить состояние
final appState = di.getIt<AppState>();
```

### Регистрация новых зависимостей

Добавьте регистрацию в `setupDependencies()`:

```dart
// Singleton (один экземпляр на все приложение)
getIt.registerLazySingleton<YourService>(
  () => YourService(dependency: getIt<Dependency>()),
);

// Factory (новый экземпляр при каждом запросе)
getIt.registerFactory<YourService>(
  () => YourService(dependency: getIt<Dependency>()),
);
```

## Типы регистрации

- `registerLazySingleton` - создается один раз при первом использовании
- `registerSingleton` - создается сразу при регистрации
- `registerFactory` - новый экземпляр при каждом запросе
- `registerFactoryParam` - фабрика с параметрами

## Тестирование

Для тестирования используйте `resetDependencies()`:

```dart
await di.resetDependencies();
// Зарегистрируйте тестовые зависимости
await di.setupDependencies();
```



