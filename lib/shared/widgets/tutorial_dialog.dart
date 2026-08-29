import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'olof_logo.dart';

class TutorialItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class TutorialDialog extends StatefulWidget {
  final String title;
  final List<TutorialItem> steps;

  const TutorialDialog({
    super.key,
    required this.title,
    required this.steps,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<TutorialItem> steps,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TutorialDialog(title: title, steps: steps),
    );
  }

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentIndex];
    final isLast = _currentIndex == widget.steps.length - 1;

    return Dialog(
      backgroundColor: AppColors.surfaceMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close
              Row(
                children: [
                  const OlofLogo(size: 28, showBorder: true),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'QUICK TUTORIAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated Icon & Step Circle
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: step.color, width: 2),
                ),
                child: Icon(step.icon, color: step.color, size: 44),
              ),
              const SizedBox(height: 20),

              // Step Title
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Step Description
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Step Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.steps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      },
                      child: Text(isLast ? 'Got it, Let\'s Start!' : 'Next Step'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
