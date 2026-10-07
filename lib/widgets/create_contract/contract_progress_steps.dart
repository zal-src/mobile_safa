import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ContractProgressSteps extends StatelessWidget {
  final int currentStep;

  const ContractProgressSteps({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['ข้อมูลของคุณ', 'รายละเอียดเงินกู้', 'ตรวจสอบ'];

    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = index == currentStep;
        final isComplete = index < currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive || isComplete
                      ? AppColors.primary
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive || isComplete
                        ? AppColors.primary
                        : const Color(0xffd7dee5),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive || isComplete
                        ? Colors.white
                        : const Color(0xff8c98a7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  labels[index],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive || isComplete
                        ? AppColors.primary
                        : const Color(0xff778392),
                    fontWeight: isActive || isComplete
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    color: const Color(0xffd7dee5),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
