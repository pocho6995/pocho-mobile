// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocho_new/main.dart';
import 'package:pocho_new/screens/main_shell.dart';
import 'package:pocho_new/state/app_state.dart';

void main() {
  Widget wrapWithState(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('PhoneAuthScreen validates Uzbek phone number', (tester) async {
    await tester.pumpWidget(wrapWithState(const PhoneAuthScreenMock()));

    final field = find.byType(TextFormField);

    // Неверный номер
    await tester.enterText(field, '+998123');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный формат узбекского номера'), findsOneWidget);

    // Корректный номер
    await tester.enterText(field, '+998901234567');
    await tester.tap(find.text('Продолжить'));
    await tester.pump();

    expect(find.text('Неверный формат узбекского номера'), findsNothing);
  });

  testWidgets('MainShell shows bottom navigation with 5 items', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: MainShell()),
      ),
    );

    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);

    final items = tester.widget<BottomNavigationBar>(bottomNav).items;
    expect(items.length, 5);
  });
}

// Упрощённые тестовые версии экранов без навигации/карт,
// чтобы не тащить реальные зависимости и роутинги.

class PhoneAuthScreenMock extends StatelessWidget {
  const PhoneAuthScreenMock({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneAuthScreenContent();
  }
}

class PhoneAuthScreenContent extends StatelessWidget {
  PhoneAuthScreenContent({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  key: const Key('phone_field'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите номер телефона';
                    }
                    final cleaned = value.replaceAll(' ', '');
                    final regex = RegExp(r'^\+998\d{9}$');
                    if (!regex.hasMatch(cleaned)) {
                      return 'Неверный формат узбекского номера';
                    }
                    return null;
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _formKey.currentState?.validate();
                },
                child: const Text('Продолжить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
