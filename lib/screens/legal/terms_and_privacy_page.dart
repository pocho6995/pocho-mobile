import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/theme_utils.dart';

class TermsAndPrivacyPage extends StatelessWidget {
  static const String routeName = '/terms-and-privacy';

  const TermsAndPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          appState.t('terms_and_privacy'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Публичная оферта
            _buildSection(
              context,
              appState.t('public_offer'),
              _getPublicOfferContent(appState, context),
            ),
            const SizedBox(height: 40),
            // Политика конфиденциальности
            _buildSection(
              context,
              appState.t('privacy_policy'),
              _getPrivacyPolicyContent(appState, context),
            ),
            const SizedBox(height: 40),
            // Контактная информация
            _buildSection(
              context,
              appState.t('contact_info'),
              _getContactInfoContent(appState, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> content,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...content,
      ],
    );
  }

  Widget _buildParagraph(String text, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: isDark ? Colors.grey[300] : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSubtitle(String text, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  List<Widget> _getPublicOfferContent(AppState appState, BuildContext context) {
    return [
      _buildParagraph(appState.t('offer_intro'), context),
      _buildSubtitle(appState.t('offer_terms'), context),
      _buildParagraph(appState.t('offer_terms_content'), context),
      _buildSubtitle(appState.t('offer_acceptance'), context),
      _buildParagraph(appState.t('offer_acceptance_content'), context),
      _buildSubtitle(appState.t('offer_services'), context),
      _buildParagraph(appState.t('offer_services_content'), context),
      _buildSubtitle(appState.t('offer_responsibility'), context),
      _buildParagraph(appState.t('offer_responsibility_content'), context),
      _buildSubtitle(appState.t('offer_changes'), context),
      _buildParagraph(appState.t('offer_changes_content'), context),
    ];
  }

  List<Widget> _getPrivacyPolicyContent(
    AppState appState,
    BuildContext context,
  ) {
    return [
      _buildParagraph(appState.t('privacy_intro'), context),
      _buildSubtitle(appState.t('privacy_data_collection'), context),
      _buildParagraph(appState.t('privacy_data_collection_content'), context),
      _buildSubtitle(appState.t('privacy_data_usage'), context),
      _buildParagraph(appState.t('privacy_data_usage_content'), context),
      _buildSubtitle(appState.t('privacy_data_protection'), context),
      _buildParagraph(appState.t('privacy_data_protection_content'), context),
      _buildSubtitle(appState.t('privacy_user_rights'), context),
      _buildParagraph(appState.t('privacy_user_rights_content'), context),
      _buildSubtitle(appState.t('privacy_cookies'), context),
      _buildParagraph(appState.t('privacy_cookies_content'), context),
    ];
  }

  List<Widget> _getContactInfoContent(AppState appState, BuildContext context) {
    return [
      _buildParagraph(appState.t('contact_intro'), context),
      _buildSubtitle(appState.t('contact_email'), context),
      _buildParagraph('support@pocho.uz', context),
      _buildSubtitle(appState.t('contact_phone'), context),
      _buildParagraph('+998 90 123 45 67', context),
      _buildSubtitle(appState.t('contact_address'), context),
      _buildParagraph(appState.t('contact_address_content'), context),
    ];
  }
}
