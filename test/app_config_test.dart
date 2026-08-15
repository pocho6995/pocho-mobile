import 'package:flutter_test/flutter_test.dart';
import 'package:pocho_new/config/app_config.dart';

void main() {
  tearDown(AppConfig.resetDebugOverrides);

  group('AppConfig.resolveApiBaseUrl', () {
    test('defaults to production when env empty', () {
      final url = AppConfig.resolveApiBaseUrl(
        envUrl: null,
        compileUrl: '',
        isAndroid: false,
        isIOS: false,
        isDebugMode: true,
      );
      expect(url, AppConfig.productionApiBaseUrl);
    });

    test('uses production env as-is', () {
      final url = AppConfig.resolveApiBaseUrl(
        envUrl: 'https://olmatech.uz/',
        compileUrl: '',
        isAndroid: false,
        isIOS: false,
        isDebugMode: true,
      );
      expect(url, 'https://olmatech.uz');
    });

    test('iOS ignores localhost and uses production', () {
      final url = AppConfig.resolveApiBaseUrl(
        envUrl: 'http://127.0.0.1:8000',
        compileUrl: '',
        isAndroid: false,
        isIOS: true,
        isDebugMode: true,
      );
      expect(url, AppConfig.productionApiBaseUrl);
    });

    test('release ignores localhost', () {
      final url = AppConfig.resolveApiBaseUrl(
        envUrl: 'http://localhost:8000',
        compileUrl: '',
        isAndroid: true,
        isIOS: false,
        isDebugMode: false,
      );
      expect(url, AppConfig.productionApiBaseUrl);
    });

    test('Android debug maps localhost to 10.0.2.2', () {
      final url = AppConfig.resolveApiBaseUrl(
        envUrl: 'http://127.0.0.1:8000',
        compileUrl: '',
        isAndroid: true,
        isIOS: false,
        isDebugMode: true,
      );
      expect(url, 'http://10.0.2.2:8000');
    });

    test('keeps LAN IP for real devices', () {
      final url = AppConfig.resolveApiBaseUrl(
        envUrl: 'http://192.168.1.10:8000',
        compileUrl: '',
        isAndroid: false,
        isIOS: true,
        isDebugMode: true,
      );
      expect(url, 'http://192.168.1.10:8000');
    });
  });

  group('AppConfig.resolveWsBaseUrl', () {
    test('derives wss from https api', () {
      final ws = AppConfig.resolveWsBaseUrl(
        envUrl: null,
        compileUrl: '',
        apiBaseUrl: 'https://olmatech.uz',
        isAndroid: false,
      );
      expect(ws, 'wss://olmatech.uz');
    });

    test('ignores loopback ws env and falls back to api', () {
      final ws = AppConfig.resolveWsBaseUrl(
        envUrl: 'ws://localhost:8000',
        compileUrl: '',
        apiBaseUrl: 'https://olmatech.uz',
        isAndroid: false,
      );
      expect(ws, 'wss://olmatech.uz');
    });

    test('converts https env to wss', () {
      final ws = AppConfig.resolveWsBaseUrl(
        envUrl: 'https://olmatech.uz',
        compileUrl: '',
        apiBaseUrl: 'https://example.com',
        isAndroid: false,
      );
      expect(ws, 'wss://olmatech.uz');
    });
  });
}
