import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/whatsapp_launcher.dart';

/// Standard WhatsApp Action Button designed for candidate and applicant cards.
class HkWhatsAppButton extends StatelessWidget {
  const HkWhatsAppButton({
    required this.phone,
    this.candidateName,
    this.contextDescription,
    this.customMessage,
    this.label = 'Chat WA',
    this.compact = false,
    super.key,
  });

  final String phone;
  final String? candidateName;
  final String? contextDescription;
  final String? customMessage;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!WhatsAppLauncher.isValidPhone(phone)) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;

    return OutlinedButton.icon(
      onPressed: () => WhatsAppLauncher.launchWhatsApp(
        context: context,
        phone: phone,
        candidateName: candidateName,
        contextDescription: contextDescription,
        customMessage: customMessage,
      ),
      icon: Icon(
        Icons.chat_outlined,
        size: compact ? 16 : 18,
        color: colors.success,
      ),
      label: Text(
        label,
        style: TextStyle(color: colors.success, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.success,
        backgroundColor: colors.successMuted.withValues(alpha: 0.35),
        side: BorderSide(color: colors.success.withValues(alpha: 0.55)),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Compact WhatsApp Icon Button with tooltip and minimum 48dp touch target.
class HkWhatsAppIconButton extends StatelessWidget {
  const HkWhatsAppIconButton({
    required this.phone,
    this.candidateName,
    this.contextDescription,
    this.customMessage,
    this.tooltip = 'Chat WhatsApp',
    super.key,
  });

  final String phone;
  final String? candidateName;
  final String? contextDescription;
  final String? customMessage;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (!WhatsAppLauncher.isValidPhone(phone)) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.successMuted.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.success.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => WhatsAppLauncher.launchWhatsApp(
            context: context,
            phone: phone,
            candidateName: candidateName,
            contextDescription: contextDescription,
            customMessage: customMessage,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.chat_outlined, size: 18, color: colors.success),
            ),
          ),
        ),
      ),
    );
  }
}
