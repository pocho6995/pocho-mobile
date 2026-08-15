import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocho_new/state/app_state.dart';
import 'package:pocho_new/utils/phone_number_utils.dart';

void main() {
  testWidgets('phone form validates Uzbek number format', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: _PhoneFormHarness(),
          ),
        ),
      ),
    );

    final field = find.byKey(const Key('phone_field'));

    await tester.enterText(field, '90123');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Неверный формат'), findsOneWidget);

    await tester.enterText(field, '901234567');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Неверный формат'), findsNothing);
    expect(find.text('OK'), findsOneWidget);
  });
}

class _PhoneFormHarness extends StatefulWidget {
  @override
  State<_PhoneFormHarness> createState() => _PhoneFormHarnessState();
}

class _PhoneFormHarnessState extends State<_PhoneFormHarness> {
  final _formKey = GlobalKey<FormState>();
  String? _ok;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('phone_field'),
            validator: (value) {
              if (!PhoneNumberUtils.isValidUzbek(value)) {
                return 'Неверный формат';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () {
              final valid = _formKey.currentState?.validate() ?? false;
              setState(() => _ok = valid ? 'OK' : null);
            },
            child: const Text('Продолжить'),
          ),
          if (_ok != null) Text(_ok!),
        ],
      ),
    );
  }
}
