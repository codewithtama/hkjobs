import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Helper utility for normalizing Indonesian phone numbers and launching WhatsApp.
class WhatsAppLauncher {
  const WhatsAppLauncher._();

  /// Normalizes an Indonesian phone number to international format (without +).
  /// Examples:
  /// - '089503091346' -> '6289503091346'
  /// - '83120980567' -> '6283120980567'
  /// - '+628123456789' -> '628123456789'
  /// - '628123456789' -> '628123456789'
  /// - '0812-3456-7890' -> '6281234567890'
  static String? normalizeIndonesianPhone(String? rawPhone) {
    if (rawPhone == null) return null;
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;

    if (digits.startsWith('0')) {
      return '62${digits.substring(1)}';
    } else if (digits.startsWith('62')) {
      return digits;
    } else if (digits.startsWith('8')) {
      return '62$digits';
    }
    return digits;
  }

  /// Returns true if [rawPhone] can be normalized into a valid WhatsApp recipient number.
  static bool isValidPhone(String? rawPhone) {
    return normalizeIndonesianPhone(rawPhone) != null;
  }

  /// Builds a standard WhatsApp URL using wa.me or deep link.
  static Uri? buildWhatsAppUri({required String phone, String? message}) {
    final normalized = normalizeIndonesianPhone(phone);
    if (normalized == null) return null;

    final queryParams = <String, String>{};
    if (message != null && message.trim().isNotEmpty) {
      queryParams['text'] = message.trim();
    }

    return Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$normalized',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Opens WhatsApp directly using native deep-link first, then falling back to wa.me web URL.
  static Future<bool> launchWhatsApp({
    required BuildContext context,
    required String phone,
    String? candidateName,
    String? contextDescription,
    String? customMessage,
  }) async {
    final normalized = normalizeIndonesianPhone(phone);
    if (normalized == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Nomor WhatsApp pelamar tidak valid atau belum terdaftar.',
            ),
            backgroundColor: context.colors.danger,
          ),
        );
      }
      return false;
    }

    final String message;
    if (customMessage != null && customMessage.trim().isNotEmpty) {
      message = customMessage.trim();
    } else {
      final name = (candidateName != null && candidateName.trim().isNotEmpty)
          ? candidateName.trim()
          : 'Kandidat';
      final extra =
          (contextDescription != null && contextDescription.trim().isNotEmpty)
          ? ' terkait $contextDescription'
          : '';
      message =
          'Halo $name, kami dari Tim Rekrutmen Hygiene Kleen (HKJobs)$extra. Apakah Anda bersedia untuk kami hubungi?';
    }

    // 1. Try native whatsapp:// deep-link first to avoid browser bounce
    final nativeUri = Uri.parse(
      'whatsapp://send?phone=$normalized&text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (_) {
      // Fall through to https://wa.me fallback
    }

    // 2. Fallback to standard https://wa.me web URL
    final webUri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );
    try {
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      // Error handled below
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tidak dapat membuka aplikasi WhatsApp. Pastikan aplikasi WhatsApp terpasang di perangkat Anda.',
          ),
          backgroundColor: context.colors.danger,
        ),
      );
    }
    return false;
  }
}
