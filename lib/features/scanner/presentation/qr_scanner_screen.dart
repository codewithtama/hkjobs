import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    _handlePayload(rawValue);
  }

  void _handlePayload(String payload) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = sheetContext.colors;

        String title = 'QR Code Terdeteksi';
        String typeLabel = 'Tautan Umum';
        IconData icon = Icons.qr_code_2_rounded;
        VoidCallback? onAction;
        String actionLabel = 'Buka';

        final uri = Uri.tryParse(payload);
        final idAdvert = uri?.queryParameters['idAdvert'];
        final idSchedule = uri?.queryParameters['id'];

        if (idAdvert != null && idAdvert.isNotEmpty) {
          title = 'QR Lowongan Kerja';
          typeLabel = 'Lowongan #$idAdvert';
          icon = Icons.work_outline;
          actionLabel = 'Lihat Pelamar Lowongan';
          onAction = () {
            Navigator.of(sheetContext).pop();
            context.go('/recruitment?vacancyId=$idAdvert');
          };
        } else if (payload.contains('ADVERT-')) {
          final match = RegExp(r'ADVERT-(\d+)').firstMatch(payload);
          final id = match?.group(1);
          title = 'QR Lowongan Kerja';
          typeLabel = 'Lowongan #${id ?? ''}';
          icon = Icons.work_outline;
          actionLabel = 'Lihat Pelamar Lowongan';
          onAction = () {
            Navigator.of(sheetContext).pop();
            context.go('/recruitment?vacancyId=$id');
          };
        } else if (payload.contains('TRAINING-')) {
          final match = RegExp(r'TRAINING-(\d+)').firstMatch(payload);
          final id = match?.group(1);
          title = 'QR Jadwal Training';
          typeLabel = 'Training #${id ?? ''}';
          icon = Icons.school_outlined;
          actionLabel = 'Buka Peserta Training';
          if (id != null) {
            onAction = () {
              Navigator.of(sheetContext).pop();
              context.push('/training/participants/$id');
            };
          }
        } else if (idSchedule != null && idSchedule.isNotEmpty) {
          title = 'QR Jadwal Interview';
          typeLabel = 'Jadwal #$idSchedule';
          icon = Icons.people_outline;
          actionLabel = 'Buka Jadwal Interview';
          onAction = () {
            Navigator.of(sheetContext).pop();
            context.go('/interview');
          };
        } else if (payload.contains('SCHEDULE-')) {
          title = 'QR Jadwal Interview';
          typeLabel = 'Jadwal Interview';
          icon = Icons.people_outline;
          actionLabel = 'Buka Jadwal Interview';
          onAction = () {
            Navigator.of(sheetContext).pop();
            context.go('/interview');
          };
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: colors.accent, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: sheetContext.textStyles.titleMedium),
                          Text(
                            typeLabel,
                            style: sheetContext.textStyles.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: SelectableText(
                    payload,
                    style: sheetContext.textStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: payload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Teks QR disalin ke clipboard.'),
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Salin'),
                    ),
                    const SizedBox(width: 10),
                    if (onAction != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAction,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(actionLabel),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Lampu Kilat',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Ganti Kamera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Viewfinder overlay
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(colors.accent),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Arahkan kamera ke QR Code lowongan atau jadwal',
                style: context.textStyles.bodySmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter(this.accentColor);

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.72;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    // Dim background
    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(120)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Border corners
    final cornerPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 24.0;
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top + 16), cornerPaint);
    canvas.drawLine(Offset(left + 16, top), Offset(left + cornerLength, top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(left + scanSize - cornerLength, top), Offset(left + scanSize - 16, top), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top + 16), Offset(left + scanSize, top + cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, top + scanSize - cornerLength), Offset(left, top + scanSize - 16), cornerPaint);
    canvas.drawLine(Offset(left + 16, top + scanSize), Offset(left + cornerLength, top + scanSize), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + scanSize - cornerLength, top + scanSize), Offset(left + scanSize - 16, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top + scanSize - 16), Offset(left + scanSize, top + scanSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
