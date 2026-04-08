import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../components/app_dialogs.dart';
import '../../services/device/device_code_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );
  bool _isScanned = false;
  bool _flashOn = false;
  bool _uploadingImage = false;

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() {
      _flashOn = !_flashOn;
    });
  }

  String? _tryDecodeRawBytes(Barcode barcode) {
    final bytes = barcode.rawBytes;
    if (bytes == null) {
      return null;
    }

    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Iterable<String> _candidateDeviceCodes(Iterable<Barcode> barcodes) sync* {
    final seen = <String>{};

    for (final barcode in barcodes) {
      final rawCandidates = <String?>[
        barcode.rawValue,
        barcode.displayValue,
        if (barcode.url?.url != null) barcode.url!.url,
        _tryDecodeRawBytes(barcode),
      ];

      for (final raw in rawCandidates) {
        if (raw == null || raw.trim().isEmpty) {
          continue;
        }

        for (final candidate in DeviceCodeParser.extractCandidates(raw)) {
          final normalized = candidate.trim();
          if (normalized.isNotEmpty && seen.add(normalized)) {
            yield normalized;
          }
        }
      }
    }
  }

  String? _resolveDeviceCode(Iterable<Barcode> barcodes) {
    FormatException? lastError;

    for (final candidate in _candidateDeviceCodes(barcodes)) {
      try {
        return DeviceCodeParser.normalize(candidate);
      } on FormatException catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return null;
  }

  Future<BarcodeCapture?> _analyzeWithFallback(String imagePath) async {
    final analyzer = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    try {
      final capture = await analyzer.analyzeImage(imagePath);
      return capture;
    } finally {
      await analyzer.dispose();
    }
  }

  Future<void> _confirmAndReturnCode({
    required String code,
    required String sourceLabel,
  }) async {
    if (!mounted) {
      return;
    }

    final useCode = await showAppConfirmationDialog(
      context,
      title: 'Detected Device Code',
      message:
          '$sourceLabel found this device code:\n\n$code\n\nUse this code for registration?',
      cancelLabel: 'Try Again',
      confirmLabel: 'Use Code',
    );

    if (!mounted) {
      return;
    }

    if (useCode) {
      Navigator.pop(context, code);
      return;
    }

    _isScanned = false;
    await _controller.start();
  }

  Future<void> _pickImageAndScan() async {
    if (_uploadingImage || _isScanned) {
      return;
    }

    final ImagePicker picker = ImagePicker();

    setState(() {
      _uploadingImage = true;
    });

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 100,
        requestFullMetadata: false,
      );

      if (image == null) {
        return;
      }

      try {
        final barcodeCapture = await _analyzeWithFallback(image.path);

        if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
          final code = _resolveDeviceCode(barcodeCapture.barcodes);

          if (code == null) {
            if (!mounted) return;
            _showError(
              'QR was detected, but no readable device code was found in the image.',
            );
            return;
          }

          _isScanned = true;
          if (!mounted) return;
          Navigator.pop(context, code);
          return;
        }

        if (!mounted) return;
        _showError('No QR code found in image.');
      } on FormatException catch (e) {
        if (!mounted) return;
        _showError(e.message);
      } catch (e) {
        if (!mounted) return;
        _showError(
          'Unable to analyze this image. Please try another QR photo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });

        if (!_isScanned) {
          await _controller.start();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          iconSize: 20,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Scan a QR",
          style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) async {
                    if (_isScanned) return;
                    try {
                      final code = _resolveDeviceCode(capture.barcodes);

                      if (code == null) {
                        return;
                      }

                      _isScanned = true;
                      await _controller.stop();
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _confirmAndReturnCode(
                        code: code,
                        sourceLabel: 'Scanner',
                      );
                    } on FormatException catch (e) {
                      _showError(e.message);
                    }
                  },
                ),

                /// Scanner overlay box
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// BOTTOM CONTROL PANEL
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: theme.scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// FLASH BUTTON
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _flashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 55),

                  /// UPLOAD IMAGE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _uploadingImage ? null : _pickImageAndScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _uploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Upload an Image"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
