import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() {
      _flashOn = !_flashOn;
    });
  }

  Future<void> _pickImageAndScan() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final barcodeCapture = await _controller.analyzeImage(image.path);

    if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
      final String? code = barcodeCapture.barcodes.first.rawValue;

      if (code != null) {
        if (mounted) {
          Navigator.pop(context, code.trim());
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code found in image")),
        );
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
      appBar: AppBar(title: const Text("Scan a QR"), centerTitle: true),
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

                    final barcode = capture.barcodes.first;
                    final String? code = barcode.rawValue;

                    if (code != null) {
                      _isScanned = true;
                      await _controller.stop();
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        Navigator.pop(context, code.trim());
                      }
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
                            color: theme.colorScheme.primary.withOpacity(0.1),
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
                      onPressed: _pickImageAndScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Upload an Image"),
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
