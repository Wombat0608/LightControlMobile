import 'package:flutter/material.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  QRScannerController? _controller;

  @override
  void initState() {
    super.initState();

    // Создаём конфигурацию и передаём её в контроллер
    final config =
        ScannerConfig(autoFocus: true); // можно настроить параметры при необходимости
    _controller = QRScannerController(config: config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Сканнер'),
        actions: [
          // Add buttons
        ],
      ),
      body: QRScannerView(
        onScannerCreated: (controller) {
          _controller = controller;
          // Теперь можно управлять камерой
        },
        onBarcodeScanned: (barcode) {
          Navigator.pop(context, barcode);
        },
        // Настройка внешнего вида (опционально)
        overlayConfig: ScannerOverlayConfig(
          borderColor: Colors.green,
          scanLineColor: Colors.green,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
