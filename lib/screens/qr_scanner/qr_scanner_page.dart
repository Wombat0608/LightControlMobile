import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  bool _isProcessing = false;
  MobileScannerController? _controller;
  bool _hasPermission = false;
  bool _isRestarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
    _checkAndRequestPermission();
  }

  void _initController() {
    _controller = MobileScannerController(
      cameraResolution: const Size(1920, 1080),
      invertImage: true,
      detectionSpeed: DetectionSpeed.unrestricted,
      autoZoom: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _fullReset();
    }
  }

  Future<void> _fullReset() async {
    if (_isRestarting) return;
    _isRestarting = true;

    if (!_hasPermission || !mounted) {
      _isRestarting = false;
      return;
    }

    // Полный сброс: пересоздаём контроллер
    await _controller?.dispose();
    _initController();
    _isProcessing = false;

    if (mounted) {
      setState(() {});
    }

    _isRestarting = false;
  }

  ///
  ///
  ///
  Future<void> _checkAndRequestPermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final isAndroid13OrAbove =
        androidInfo.version.sdkInt >= 33; // API 33 = Android 13

    // Собираем список разрешений для запроса
    List<Permission> permissionsToRequest = [Permission.camera];

    if (isAndroid13OrAbove) {
      // На Android 13+ используем новое разрешение для Wi-Fi
      permissionsToRequest.add(Permission.nearbyWifiDevices);
    } else {
      // На старых версиях Android используем геолокацию
      permissionsToRequest.add(Permission.location);
    }

    // Запрашиваем разрешения
    Map<Permission, PermissionStatus> statuses = await permissionsToRequest
        .request();

    // Проверяем результат
    bool hasCamera = statuses[Permission.camera]?.isGranted ?? false;
    bool hasWifiPermission = isAndroid13OrAbove
        ? (statuses[Permission.nearbyWifiDevices]?.isGranted ?? false)
        : (statuses[Permission.location]?.isGranted ?? false);

    if (hasCamera && hasWifiPermission) {
      if (mounted) setState(() => _hasPermission = true);
    } else {
      // Обработка отказа пользователя
      if (mounted) _showRequestDeniedDialog();
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуются разрешения'),
        content: Text(
          'Для сканирования Wi-Fi QR-кодов приложению необходим доступ:\n'
          '• К камере\n'
          '• К определению местоположения\n\n'
          'Доступ к $permissionName заблокирован навсегда. '
          'Пожалуйста, включите его в настройках приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _showRequestDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Необходимы разрешения'),
        content: const Text(
          'Для сканирования Wi-Fi QR-кодов и подключения к сети приложению необходим доступ:\n'
          '• К камере — для сканирования QR-кода\n'
          '• К геопозиции — требуется Android для работы с Wi-Fi\n\n'
          'Это требования безопасности Android для работы с локальными сетями.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Вернуться'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestPermission();
            },
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер QR-кода'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _hasPermission && _controller != null
          ? _buildScanner()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildScanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowSize = constraints.maxWidth * 0.7;
        final scanWindow = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: windowSize,
          height: windowSize,
        );
        return Stack(
          children: [
            MobileScanner(
              key: ValueKey(
                _controller,
              ), // Принудительная перестройка при новом контроллере
              controller: _controller,
              fit: BoxFit.cover,
              scanWindow: scanWindow,
              onDetect: onDetectBarcode,
            ),
            CustomPaint(painter: ScannerOverlayPainter(scanWindow)),
          ],
        );
      },
    );
  }

  Map<String, String>? _parseWifiString(String rawValue) {
    try {
      if (!rawValue.startsWith('WIFI:')) return null;

      String ssid = '';
      String password = '';
      String encryption = 'WPA';

      String content = rawValue.substring(5);
      if (content.endsWith(';;')) {
        content = content.substring(0, content.length - 2);
      }

      List<String> parts = content.split(';');
      for (String part in parts) {
        if (part.startsWith('S:')) {
          ssid = part.substring(2);
        } else if (part.startsWith('P:')) {
          password = part.substring(2);
        } else if (part.startsWith('T:')) {
          encryption = part.substring(2);
        }
      }

      if (ssid.isNotEmpty) {
        return {'ssid': ssid, 'password': password, 'encryption': encryption};
      }
      return null;
    } catch (e) {
      print('Ошибка парсинга: $e');
      return null;
    }
  }

  void _showConnectionDialog(String ssid, String password, String security) {
    _controller?.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Подключение к Wi-Fi'),
        content: Text('Сеть: $ssid\nПароль: $password'),
        actions: [
          TextButton(
            onPressed: () async {
              _isProcessing = false;
              // Полный перезапуск после закрытия диалога
              await _fullReset();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _connectToWifi(ssid, password);
              _isProcessing = false;
              // Полный перезапуск после подключения
              await _fullReset();
              if (mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Подключиться'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToWifi(String ssid, String password) async {
    try {
      // 1. Подключаемся к сети (ваш старый код)
      bool connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        withInternet: false, // Критично важно для сетей без интернета
        timeoutInSeconds: 45,
      );

      if (!connected) {
        print('Ошибка: WiFiForIoTPlugin.connect вернул false');
        _showSnackBar('Не удалось подключиться к сети $ssid');
        return;
      }

      print('Подключение к $ssid установлено');

      // 2. *** ЭТО САМОЕ ВАЖНОЕ ***
      // Принудительно направляем ВЕСЬ трафик приложения через это Wi-Fi соединение
      bool forceResult = await WiFiForIoTPlugin.forceWifiUsage(true);

      if (forceResult) {
        print('Трафик принудительно направлен через Wi-Fi');
        _showSnackBar('Подключено к $ssid. Трафик идёт через устройство.');
      } else {
        print('Не удалось принудительно направить трафик через Wi-Fi');
        _showSnackBar('Подключено, но трафик может идти через мобильную сеть.');
      }
    } catch (e) {
      print('Ошибка в процессе подключения: $e');
      _showSnackBar('Ошибка подключения: ${e.toString()}');
    }
  }

  // Вспомогательный метод для показа уведомлений
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void onDetectBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue == null || barcode.rawValue!.isEmpty) {
        _isProcessing = false;
        return;
      }

      print('Тип: ${barcode.type}, значение: ${barcode.rawValue}');

      final rawValue = barcode.rawValue!;

      if (barcode.type == BarcodeType.wifi) {
        final wifi = barcode.wifi;
        if (wifi != null) {
          _showConnectionDialog(
            wifi.ssid ?? '',
            wifi.password ?? '',
            wifi.encryptionType.name,
          );
        } else {
          _isProcessing = false;
        }
      } else if (rawValue.startsWith('WIFI:')) {
        print('Распознано как текст, пробуем распарсить WiFi');
        final wifiData = _parseWifiString(rawValue);
        if (wifiData != null) {
          _showConnectionDialog(
            wifiData['ssid'] ?? '',
            wifiData['password'] ?? '',
            wifiData['encryption'] ?? 'WPA',
          );
        } else {
          Navigator.of(context).pop(rawValue);
          _isProcessing = false;
        }
      } else {
        Navigator.of(context).pop(rawValue);
        _isProcessing = false;
      }
    } catch (e) {
      print('Ошибка: $e');
      _isProcessing = false;
    }
  }
}
