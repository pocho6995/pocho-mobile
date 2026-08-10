import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../widgets/modern_bottom_sheet.dart';
import '../../state/app_state.dart';

Future<String?> showBottomCategoryMenu(
  BuildContext context,
  List<Map<String, dynamic>> categories,
  String selectedName,
) {
  final media = MediaQuery.of(context);
  final height = media.size.height;
  final isSmallHeight = height < 700;
  final maxHeight = height * (isSmallHeight ? 0.55 : 0.6);
  final appState = Provider.of<AppState>(context, listen: false);

  return ModernBottomSheet.show<String>(
    context: context,
    title: appState.t('categories'),
    showCloseButton: true,
    isScrollControlled: true,
    maxHeight: maxHeight,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Text(
            appState.t('select_what_you_need_now'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: categories.length,
            itemBuilder: (ctx, index) {
              final category = categories[index];
              final isSelected = category['name'] == selectedName;
              final color = Color(category['color'] as int);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.pop(
                                context,
                                category['name'] as String,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? color.withOpacity(0.35)
                                      : Colors.grey.shade100,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  if (!isSelected)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      category['icon'] as IconData,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      category['name'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? color
                                            : const Color(0xFF111827),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: isSelected
                                        ? color.withOpacity(0.8)
                                        : Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 280.ms, delay: (index * 50).ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 280.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOutCubic,
                        ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
