import 'package:flutter_test/flutter_test.dart';
import 'package:pocho_new/utils/websocket_uri.dart';

void main() {
  group('WebSocketUriBuilder', () {
    test('builds wss uri without explicit port', () {
      final uri = WebSocketUriBuilder.build(
        baseUrl: 'wss://olmatech.uz',
        path: '/api/v1/global-chat/ws',
        queryParameters: {'token': 'abc'},
      );
      expect(uri.scheme, 'wss');
      expect(uri.host, 'olmatech.uz');
      expect(uri.path, '/api/v1/global-chat/ws');
      expect(uri.queryParameters['token'], 'abc');
      expect(uri.hasPort, isFalse);
    });

    test('converts https base to wss', () {
      final uri = WebSocketUriBuilder.build(
        baseUrl: 'https://olmatech.uz/',
        path: 'api/v1/global-chat/ws',
        queryParameters: {'token': 'x'},
      );
      expect(uri.scheme, 'wss');
      expect(uri.toString(), startsWith('wss://olmatech.uz/api/v1/global-chat/ws'));
    });

    test('detects permanent upgrade failures', () {
      expect(
        WebSocketUriBuilder.isPermanentFailure(
          Exception('Connection to \'https://olmatech.uz/...\' was not upgraded to websocket'),
        ),
        isTrue,
      );
    });
  });
}
