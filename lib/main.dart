import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'config/app_config.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/car_service_page.dart';
import 'screens/car_wash_page.dart';
import 'screens/charging_stations_page.dart';
import 'screens/notifications_page.dart';
import 'screens/restaurants_page.dart';
import 'screens/restaurant_detail_page.dart';
import 'screens/stations_page.dart';
import 'screens/user_menu_page.dart';
import 'screens/ai_assistant_page.dart';
import 'screens/favorites_restaurants_page.dart';
import 'screens/favorites_car_service_page.dart';
import 'screens/car_service_detail_page.dart';
import 'screens/favorites_car_wash_page.dart';
import 'screens/car_wash_detail_page.dart';
import 'screens/favorites_charging_stations_page.dart';
import 'screens/charging_station_detail_page.dart';
import 'screens/profile_page.dart';
import 'screens/legal/terms_and_privacy_page.dart';

import 'screens/support/support_chat_page.dart';
import 'screens/support/support_tickets_page.dart';
import 'screens/global_chat/global_chat_page.dart';
import 'presentation/pages/gas_station_detail_page.dart';
import 'screens/gas_stations_map_page.dart';
import 'screens/delivery/delivery_map_page.dart';
import 'screens/delivery/from_to_address_page.dart';
import 'screens/delivery/my_orders_page.dart';
import 'screens/delivery/delivery_balance_page.dart';
import 'screens/delivery/driver_orders_page.dart';
import 'models/restaurant.dart';
import 'models/car_service.dart';
import 'models/car_wash.dart';
import 'models/charging_station.dart';
import 'state/app_state.dart';
import 'di/injection_container.dart' as di;
import 'utils/custom_page_route.dart';

// Глобальный ключ навигатора для доступа из любого места приложения
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

TextTheme _getTextTheme() {
  try {
    return GoogleFonts.interTextTheme(ThemeData.light().textTheme);
  } catch (e) {
    return ThemeData.light().textTheme;
  }
}

ThemeData _getTheme() {
  final flexTheme = FlexThemeData.light(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    textTheme: _getTextTheme(),
  );

  return flexTheme.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    // Глобальные настройки переходов между страницами
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env file loaded successfully');
    debugPrint('   API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? 'not set'}');
    debugPrint('   WS_BASE_URL: ${dotenv.env['WS_BASE_URL'] ?? 'not set'}');
  } catch (e) {
    // Если .env файл не найден, используем значения по умолчанию
    debugPrint('⚠️ .env file not found, using default values: $e');
  }
  debugPrint('🌐 Resolved API: ${AppConfig.apiBaseUrl}');
  debugPrint('🌐 Resolved WS:  ${AppConfig.wsBaseUrl}');

  // Инициализация SharedPreferences заранее для избежания проблем с каналом
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    // Игнорируем ошибки инициализации на этом этапе
  }

  // Инициализация зависимостей
  await di.setupDependencies();

  GoogleFonts.config.allowRuntimeFetching = true;

  // Убираем цвет верхней панели (статус-бара)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PochoApp());
}

class PochoApp extends StatelessWidget {
  const PochoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => di.getIt<AppState>(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'PoCho',
            theme: _getTheme(),
            locale: appState.locale,
            supportedLocales: const [Locale('ru'), Locale('uz')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: SplashScreen.routeName,
            onGenerateRoute: (settings) {
              // Кастомные переходы для разных страниц
              switch (settings.name) {
                case SplashScreen.routeName:
                  return FadePageRoute(page: const SplashScreen());
                case PhoneAuthScreen.routeName:
                  return FadePageRoute(page: const PhoneAuthScreen());
                case OtpScreen.routeName:
                  return SlideUpPageRoute(
                    page: const OtpScreen(),
                    arguments: settings.arguments,
                  );
                case MainShell.routeName:
                  return FadePageRoute(page: const MainShell());
                case RestaurantsPage.routeName:
                  return SlideRightPageRoute(page: const RestaurantsPage());
                case CarServicePage.routeName:
                  return SlideRightPageRoute(page: const CarServicePage());
                case CarWashPage.routeName:
                  return SlideRightPageRoute(page: const CarWashPage());
                case ChargingStationsPage.routeName:
                  return SlideRightPageRoute(
                    page: const ChargingStationsPage(),
                  );
                case StationsPage.routeName:
                  return SlideRightPageRoute(page: const StationsPage());
                case NotificationsPage.routeName:
                  return SlideRightPageRoute(page: const NotificationsPage());
                case ProfilePage.routeName:
                  return SlideRightPageRoute(page: const ProfilePage());
                case RestaurantDetailPage.routeName:
                  final args = settings.arguments as Restaurant;
                  return ModernPageRoute(
                    page: RestaurantDetailPage(restaurant: args),
                  );
                case CarServiceDetailPage.routeName:
                  final args = settings.arguments as CarService;
                  return ModernPageRoute(
                    page: CarServiceDetailPage(carService: args),
                  );
                case CarWashDetailPage.routeName:
                  final args = settings.arguments as CarWash;
                  return ModernPageRoute(
                    page: CarWashDetailPage(carWash: args),
                  );
                case ChargingStationDetailPage.routeName:
                  final args = settings.arguments as ChargingStation;
                  return ModernPageRoute(
                    page: ChargingStationDetailPage(station: args),
                  );
                case GasStationDetailPage.routeName:
                  final args = settings.arguments as int;
                  return ModernPageRoute(
                    page: GasStationDetailPage(stationId: args),
                  );
                case DeliveryMapPage.routeName:
                  return FadePageRoute(page: const DeliveryMapPage());
                case FromToAddressPage.routeName:
                  return SlideUpPageRoute(page: const FromToAddressPage());
                case MyOrdersPage.routeName:
                  return SlideRightPageRoute(page: const MyOrdersPage());
                case DeliveryBalancePage.routeName:
                  return SlideRightPageRoute(page: const DeliveryBalancePage());
                case DriverOrdersPage.routeName:
                  return SlideRightPageRoute(page: const DriverOrdersPage());
                default:
                  // Для остальных страниц используем стандартный переход
                  return null;
              }
            },
            // Fallback routes для страниц, которые не обрабатываются в onGenerateRoute
            routes: {
              FavoritesRestaurantsPage.routeName: (_) =>
                  const FavoritesRestaurantsPage(),
              FavoritesCarServicePage.routeName: (_) =>
                  const FavoritesCarServicePage(),
              FavoritesCarWashPage.routeName: (_) =>
                  const FavoritesCarWashPage(),
              FavoritesChargingStationsPage.routeName: (_) =>
                  const FavoritesChargingStationsPage(),
              UserMenuPage.routeName: (_) => const UserMenuPage(),
              AiAssistantPage.routeName: (_) => const AiAssistantPage(),
              TermsAndPrivacyPage.routeName: (_) => const TermsAndPrivacyPage(),
              SupportTicketsPage.routeName: (_) => const SupportTicketsPage(),
              SupportChatPage.routeName: (context) {
                final args = ModalRoute.of(context)!.settings.arguments as int?;
                if (args == null) {
                  throw ArgumentError(
                    'Ticket ID is required for SupportChatPage',
                  );
                }
                return SupportChatPage(ticketId: args);
              },
              GlobalChatPage.routeName: (_) => const GlobalChatPage(),
              GasStationsMapPage.routeName: (_) => const GasStationsMapPage(),
            },
          );
        },
      ),
    );
  }
}
