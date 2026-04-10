import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../services/api/api_client.dart';
import '../../services/api/devices_api.dart';
import '../../services/device/device_setup_service.dart';
import '../../services/device/device_code_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.deviceName});

  final String? deviceName;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );
  late final DeviceSetupService _setupService;
  bool _isScanned = false;
  bool _flashOn = false;
  bool _uploadingImage = false;
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _setupService = DeviceSetupService(DevicesApi(apiClient));
  }

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

  String? _resolveQrPayload(Iterable<Barcode> barcodes) {
    FormatException? lastError;

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

        try {
          return DeviceCodeParser.normalizeQrPayload(raw);
        } on FormatException catch (error) {
          lastError = error;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return null;
  }

  Future<BarcodeCapture?> _analyzeWithFallback(String imagePath) async {
    try {
      return await _controller.analyzeImage(imagePath);
    } catch (_) {
      final analyzer = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: [BarcodeFormat.qrCode],
      );

      try {
        return await analyzer.analyzeImage(imagePath);
      } finally {
        await analyzer.dispose();
      }
    }
  }

  Future<void> _registerAndReturn(String qrPayload) async {
    if (!mounted) {
      return;
    }

    _registering = true;

    try {
      debugPrint('Registering QR device: $qrPayload');

      final registered = await _setupService.registerQrDevice(
        qrPayload: qrPayload,
        name: widget.deviceName,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, registered.id);
      return;
    } on FormatException catch (e) {
      _showError(e.message);

      if (!mounted) {
        return;
      }

      _isScanned = false;
      _registering = false;
      await _controller.start();
    } catch (e) {
      _showError('Failed to register device: $e');

      if (!mounted) {
        return;
      }

      _isScanned = false;
      _registering = false;
      await _controller.start();
    }
  }

  Future<void> _processSelectedImage(XFile image) async {
    debugPrint('Selected image path: ${image.path}');

    final barcodeCapture = await _analyzeWithFallback(image.path);
    debugPrint(
      'Analyze result: ${barcodeCapture == null ? "null" : "not null"}',
    );

    if (barcodeCapture == null) {
      if (mounted) {
        _showError('Unable to analyze this image.');
      }
      return;
    }

    debugPrint('Barcode count: ${barcodeCapture.barcodes.length}');

    if (barcodeCapture.barcodes.isEmpty) {
      if (mounted) {
        _showError('No QR code found in image.');
      }
      return;
    }

    final qrPayload = _resolveQrPayload(barcodeCapture.barcodes);
    debugPrint('Resolved QR payload: $qrPayload');

    if (qrPayload == null || qrPayload.trim().isEmpty) {
      if (mounted) {
        _showError('QR detected, but no valid device code was found.');
      }
      return;
    }

    _isScanned = true;
    await _registerAndReturn(qrPayload);
  }

  Future<void> _pickImageAndScan() async {
    if (_uploadingImage || _isScanned || _registering) {
      debugPrint(
        'Upload blocked: uploading=$_uploadingImage scanned=$_isScanned registering=$_registering',
      );
      return;
    }

    final picker = ImagePicker();

    if (mounted) {
      setState(() {
        _uploadingImage = true;
      });
    }

    XFile? image;

    try {
      debugPrint('Stopping live scanner before gallery pick...');
      await _controller.stop();

      debugPrint('Opening gallery...');
      image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 100,
        requestFullMetadata: false,
      );

      debugPrint('pickImage finished');
      debugPrint('mounted after picker: $mounted');
      debugPrint('image is null: ${image == null}');

      if (image == null) {
        if (mounted) {
          _showError('No image selected.');
        }
        return;
      }

      await _processSelectedImage(image);
    } on FormatException catch (e, st) {
      debugPrint('FormatException during gallery scan: ${e.message}');
      debugPrintStack(stackTrace: st);

      _isScanned = false;

      if (mounted) {
        _showError(e.message);
      }
    } catch (e, st) {
      debugPrint('Unexpected gallery scan error: $e');
      debugPrintStack(stackTrace: st);

      _isScanned = false;

      if (mounted) {
        _showError(
          'Unable to analyze this image. Please try another QR photo.',
        );
      }
    } finally {
      debugPrint(
        'finally reached; mounted=$mounted isScanned=$_isScanned registering=$_registering',
      );

      if (mounted && !_isScanned && !_registering) {
        setState(() {
          _uploadingImage = false;
        });

        debugPrint('Restarting live scanner...');
        await _controller.start();
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
                    if (_isScanned || _registering) return;
                    try {
                      final qrPayload = _resolveQrPayload(capture.barcodes);

                      if (qrPayload == null) {
                        return;
                      }

                      _isScanned = true;
                      await _controller.stop();
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _registerAndReturn(qrPayload);
                    } on FormatException catch (e) {
                      _showError(e.message);
                    }
                  },
                ),
                if (_registering)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
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
                      onPressed: _uploadingImage || _registering
                          ? null
                          : _pickImageAndScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _uploadingImage || _registering
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
