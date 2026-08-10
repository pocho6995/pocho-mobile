import 'package:flutter/material.dart';

import 'tabs/home_tab.dart';

class StationsPage extends StatelessWidget {
  const StationsPage({super.key});

  static const String routeName = '/stations';

  @override
  Widget build(BuildContext context) {
    return const HomeTab();
  }
}
