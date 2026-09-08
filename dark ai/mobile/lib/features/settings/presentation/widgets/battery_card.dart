import 'package:flutter/material.dart';
import '../../../../core/theme/dark_theme.dart';

class BatteryCard extends StatelessWidget {
  final bool isIgnored;
  final VoidCallback onRequestTap;

  const BatteryCard({
    Key? key,
    required this.isIgnored,
    required this.onRequestTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarkTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isIgnored ? DarkTheme.accentNeon.withOpacity(0.3) : DarkTheme.warningOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIgnored ? DarkTheme.accentNeon : DarkTheme.warningOrange).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.battery_charging_full,
                  color: isIgnored ? DarkTheme.accentNeon : DarkTheme.warningOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Battery Optimization',
                          style: TextStyle(
                            color: DarkTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isIgnored ? DarkTheme.accentNeon : DarkTheme.warningOrange).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isIgnored ? 'UNRESTRICTED' : 'RESTRICTED',
                            style: TextStyle(
                              color: isIgnored ? DarkTheme.accentNeon : DarkTheme.warningOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isIgnored
                          ? 'DARK AI can listen reliably while your screen is off and locked.'
                          : 'Android may pause listening during screen-off unless exempted.',
                      style: const TextStyle(color: DarkTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isIgnored) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRequestTap,
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('ALLOW UNRESTRICTED BACKGROUND'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkTheme.warningOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
