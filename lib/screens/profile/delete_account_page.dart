import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../di/injection_container.dart' as di;
import '../../services/profile_service.dart';
import '../../services/token_storage.dart';
import '../../state/app_state.dart';
import '../../widgets/modern_dialog.dart';
import '../auth/phone_auth_screen.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  static const String routeName = '/profile/delete-account';

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirmController = TextEditingController();
  late final ProfileService _profileService;
  late final TokenStorage _tokenStorage;

  bool _understood = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _profileService = di.getIt<ProfileService>();
    _tokenStorage = di.getIt<TokenStorage>();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  String get _requiredWord {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.t('delete_account_confirm_word');
  }

  bool get _wordMatches {
    return _confirmController.text.trim().toUpperCase() ==
        _requiredWord.toUpperCase();
  }

  bool get _canSubmit => _understood && _wordMatches && !_isDeleting;

  Future<void> _startDeleteFlow() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final first = await ModernDialog.show<bool>(
      context: context,
      title: appState.t('delete_account_dialog1_title'),
      content: appState.t('delete_account_dialog1_body'),
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      primaryAction: DialogAction(
        label: appState.t('continue'),
        onPressed: () {},
        returnValue: true,
      ),
      secondaryAction: DialogAction(
        label: appState.t('cancel'),
        onPressed: () {},
        returnValue: false,
      ),
    );
    if (first != true || !mounted) return;

    final second = await ModernDialog.show<bool>(
      context: context,
      title: appState.t('delete_account_dialog2_title'),
      content: appState.t('delete_account_dialog2_body'),
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(
        label: appState.t('delete_account_confirm_button'),
        onPressed: () {},
        isDestructive: true,
        returnValue: true,
      ),
      secondaryAction: DialogAction(
        label: appState.t('cancel'),
        onPressed: () {},
        returnValue: false,
      ),
    );
    if (second != true || !mounted) return;

    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      await _profileService.deleteAccount();
    } catch (_) {
      // Даже при ошибке API выходим на авторизацию.
    }

    try {
      await _tokenStorage.clearToken();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      PhoneAuthScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final word = appState.t('delete_account_confirm_word');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          appState.t('delete_account_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appState.t('delete_account_warning_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appState.t('delete_account_warning_body'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 20),
              _Bullet(text: appState.t('delete_account_point_profile')),
              _Bullet(text: appState.t('delete_account_point_orders')),
              _Bullet(text: appState.t('delete_account_point_chat')),
              _Bullet(text: appState.t('delete_account_point_irreversible')),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _understood,
                onChanged: _isDeleting
                    ? null
                    : (value) => setState(() => _understood = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.red,
                title: Text(
                  appState.t('delete_account_checkbox'),
                  style: const TextStyle(fontSize: 14, height: 1.35),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appState.t('delete_account_type_hint').replaceAll('{word}', word),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                enabled: !_isDeleting,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: word,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _startDeleteFlow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.shade100,
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          appState.t('delete_account_button'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
