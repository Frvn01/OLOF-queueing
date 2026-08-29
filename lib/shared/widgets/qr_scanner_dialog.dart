import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';

/// QR Scanner dialog that works on mobile/tablet cameras and provides manual entry fallback for web/desktop
class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const QrScannerDialog(),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  bool _hasScanned = false;
  bool _showManual = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _hasScanned = true;
        Navigator.of(context).pop(barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Scan Patient QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _showManual
                    ? _buildManualInput()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            MobileScanner(
                              controller: _controller,
                              onDetect: _onDetect,
                              errorBuilder: (context, error) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.videocam_off_rounded,
                                          color: AppColors.urgent,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Camera unavailable on this device.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => setState(() => _showManual = true),
                                          child: const Text('Enter Code Manually'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Target viewfinder overlay
                            Center(
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.cyanCalm, width: 3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showManual = !_showManual;
                      });
                    },
                    icon: Icon(_showManual ? Icons.camera_alt_rounded : Icons.keyboard_rounded),
                    label: Text(_showManual ? 'Use Camera' : 'Manual Code Entry'),
                  ),
                  const Spacer(),
                  if (!_showManual)
                    IconButton(
                      icon: const Icon(Icons.flash_on_rounded),
                      onPressed: () => _controller.toggleTorch(),
                      tooltip: 'Toggle Flashlight',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _manualController,
            decoration: const InputDecoration(
              labelText: 'Patient ID or QR Number',
              hintText: 'e.g. OLOF-2026-XXXX',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            autofocus: true,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                Navigator.of(context).pop(val.trim());
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_manualController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(_manualController.text.trim());
              }
            },
            child: const Text('Look Up Patient'),
          ),
        ],
      ),
    );
  }
}
