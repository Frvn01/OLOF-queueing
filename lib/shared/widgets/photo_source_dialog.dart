import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

/// Shows a dialog / bottom sheet allowing the user to choose
/// between Camera and Album / Gallery for photo capture.
Future<ImageSource?> showPhotoSourceDialog(
  BuildContext context, {
  bool isDark = false,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTabletOrDesktop = screenWidth > 600;

  if (isTabletOrDesktop) {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => _PhotoSourceContent(isDark: isDark, isDialog: true),
    );
  }

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PhotoSourceContent(isDark: isDark, isDialog: false),
  );
}

class _PhotoSourceContent extends StatelessWidget {
  final bool isDark;
  final bool isDialog;

  const _PhotoSourceContent({
    required this.isDark,
    required this.isDialog,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar (for bottom sheet)
        if (!isDialog) ...[
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],

        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(20, isDialog ? 20 : 4, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Profile Photo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      'Choose a photo source',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDialog)
                IconButton(
                  icon: Icon(Icons.close_rounded, color: subtitleColor, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cancel',
                ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Option 1: Camera
              _buildOption(
                context,
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Take a new photo directly using device camera',
                gradient: AppColors.primaryGradient,
                source: ImageSource.camera,
              ),

              const SizedBox(height: 12),

              // Option 2: Album / Gallery
              _buildOption(
                context,
                icon: Icons.photo_library_rounded,
                title: 'Album / Gallery',
                subtitle: 'Select an existing photo from your device album',
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                source: ImageSource.gallery,
              ),
            ],
          ),
        ),

        if (!isDialog)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),
      ],
    );

    if (isDialog) {
      return Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: content,
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required ImageSource source,
  }) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.5) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(source),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (gradient as LinearGradient)
                          .colors
                          .first
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
