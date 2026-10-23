import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: compact ? 76 : 96,
          height: compact ? 76 : 96,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orange, width: 3),
          ),
          child: const Icon(Icons.shield_moon_outlined, color: AppColors.green, size: 48),
        ),
        const SizedBox(height: 6),
        const Text(
          'RESQ-MITRA',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
        const Text(
          'HELP  •  PROTECT  •  SUPPORT  •  TOGETHER',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.navy, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
