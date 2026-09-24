import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/api_config.dart';

/// Universal image helper for the OLOF Hybrid System.
///
/// Seamlessly resolves and handles:
/// - Cloud Supabase Storage public URLs (`https://...supabase.co/storage/...`)
/// - Local streaming server files on Clinic PC (`http://192.168.100.17:8080/files/...`)
/// - Base64 Data URIs (`data:image/png;base64,...`)
/// - Local file paths on the current operating system (`FileImage`)
class AppImageHelper {
  AppImageHelper._();

  /// Resolves any path, data URI, or URL into an [ImageProvider].
  /// Returns `null` if the input is null or blank.
  static ImageProvider? buildImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = pathOrUrl.trim();

    // 1. Base64 Data URI
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Part = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Part.trim());
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('AppImageHelper: error decoding base64 data URI: $e');
        return null;
      }
    }

    // 2. Full HTTP / HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // 3. Local Streaming Server relative path
    if (trimmed.startsWith('/files/') || trimmed.startsWith('files/')) {
      return NetworkImage(ApiConfig.resolveFileUrl(trimmed));
    }

    // 4. Local OS filesystem path (Desktop / Mobile only)
    if (!kIsWeb) {
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }

    // 5. Fallback: try resolving via ApiConfig streaming URL
    final resolved = ApiConfig.resolveFileUrl(trimmed);
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return NetworkImage(resolved);
    }

    return null;
  }

  /// Builds a [CircleAvatar] that safely displays patient or staff photos.
  /// Gracefully falls back to initials or an icon if the image is missing or invalid.
  static Widget buildAvatar({
    required String? photoUrl,
    required double radius,
    String? name,
    IconData fallbackIcon = Icons.person_rounded,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final provider = buildImageProvider(photoUrl);

    String initials = '';
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
        initials = parts.first[0].toUpperCase();
      }
    }

    final bg = backgroundColor ?? const Color(0xFF0D9488).withValues(alpha: 0.15);
    final fg = foregroundColor ?? const Color(0xFF0D9488);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: provider,
      onBackgroundImageError: provider != null
          ? (exception, stackTrace) {
              debugPrint('Notice: avatar image load error: $exception');
            }
          : null,
      child: provider != null
          ? null
          : (initials.isNotEmpty
              ? Text(
                  initials,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.75,
                  ),
                )
              : Icon(
                  fallbackIcon,
                  color: fg,
                  size: radius * 1.1,
                )),
    );
  }

  /// Builds an image widget for clinical diagrams or webcam captures.
  static Widget buildDiagramImage(
    String? imageUrl, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final defaultPlaceholder = Center(
      child: Icon(Icons.draw_rounded, color: Colors.grey.shade400, size: 36),
    );

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return placeholder ?? defaultPlaceholder;
    }

    final provider = buildImageProvider(imageUrl);
    if (provider == null) {
      return errorWidget ?? Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 36),
      );
    }

    return Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 36),
        );
      },
    );
  }
}
