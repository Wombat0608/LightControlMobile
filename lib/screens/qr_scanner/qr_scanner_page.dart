import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanWindow)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, backgroundPaint);
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(scanWindow, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isProcessing = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер QR-кода'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.pop(context), // Просто закрыть без результата
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Создаем адаптивное окно сканирования
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width:
                constraints.maxWidth *
                (constraints.maxHeight > constraints.maxWidth ? 0.3 : 0.15),
            height:
                constraints.maxHeight *
                (constraints.maxHeight > constraints.maxWidth ? 0.17 : 0.4),
          );

          return Stack(
            children: [
              MobileScanner(
                fit: BoxFit.cover,
                
                scanWindow: scanWindow,
                onDetect: onDetectBarcode,
              ),
              // Оверлей с рамкой
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: ScannerOverlayPainter(scanWindow),
              ),
            ],
          );
        },
      ),
    );
  }

  void onDetectBarcode(BarcodeCapture capture) {
    if (!mounted || _isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      _isProcessing = true;
      final String? scannedValue = barcodes.first.rawValue;
      Navigator.of(context).pop(scannedValue);
    }
  }
}
