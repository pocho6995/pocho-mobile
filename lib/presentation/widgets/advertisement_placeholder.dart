import 'package:flutter/material.dart';

/// Placeholder виджет для рекламы, когда реклама отсутствует
class AdvertisementPlaceholder extends StatelessWidget {
  const AdvertisementPlaceholder({
    super.key,
    this.height,
    this.borderRadius,
  });

  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? 20.0;
    final height = this.height ?? 120.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ads_click_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Место для вашей рекламы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Свяжитесь с нами для размещения',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

