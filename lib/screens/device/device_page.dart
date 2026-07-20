import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/screens/qr_scanner/qr_scanner.dart';

import 'package:light_control/core/client/device_adapter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:light_control/core/persistence/device_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:lumi_qr_scanner/lumi_qr_scanner.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';
import 'package:app_settings/app_settings.dart';

enum RequiredPermissions {
  camera('‣ Доступ к камере для сканирования QR', Permission.camera),
  location('‣ Для поиска Wi-Fi сетей', Permission.location),
  nearbyWifi(
    '‣ Для подключения к IoT-устройствам',
    Permission.nearbyWifiDevices,
  );

  final String comment;
  final Permission permission;
  const RequiredPermissions(this.comment, this.permission);
}

class DevicePage extends StatefulWidget {
  final Device? device;

  const DevicePage({super.key, this.device});

  @override
  State<StatefulWidget> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  static const _defaultIPAddress = '192.168.4.1';
  late final TextEditingController ipController;
  late final TextEditingController nameController;

  /*
    Переменная для сохранения WiFi SSID сети, в которой ?находится? телефон ДО подключения к точке доступа IoT  
  */
  String? _previousWifiSSID;

  late final _ipMaskFormatter;
  Device? device;

  bool _check = false;
  bool _handshaked = false;
  late String _errorMessage;

  void _onIpChanged() {
    print('IP изменился: ${ipController.text}');
  }

  @override
  void initState() {
    super.initState();
    final initialIP = widget.device?.host ?? _defaultIPAddress;
    final initialName = widget.device?.name ?? 'Unknown';
    _handshaked = widget.device != null;
    device = widget.device;

    ipController = TextEditingController(text: initialIP);
    nameController = TextEditingController(text: initialName);
    _ipMaskFormatter = MaskTextInputFormatter(
      mask: '###.###.###.###',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
    ipController.addListener(_onIpChanged);
  }

  @override
  void dispose() {
    ipController.removeListener(_onIpChanged);
    ipController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = widget.device == null
        ? "Новое устройство"
        : widget.device!.name;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(pageTitle),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(),
            onSelected: (String result) {
              if (result == 'reconnect') {
                _manualReconnect();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'remove',
                child: Text('Удалить устройство'),
              ),
              const PopupMenuItem<String>(
                value: 'scan',
                child: Text('Сканировать QR'),
              ),
              const PopupMenuDivider(),
              if (_handshaked)
                const PopupMenuItem<String>(
                  value: 'reconnect',
                  child: Text('Переподключиться'),
                ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Настройки'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                readOnly: !_handshaked,
                enabled: _handshaked,
                decoration: const InputDecoration(
                  labelText: "Имя устройства",
                  hintText: "Введите имя устройства",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ipMaskFormatter],
                      decoration: InputDecoration(
                        labelText: 'IP-адрес устройства',
                        hintText: '___.___.___.___',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _handshaked = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _scanQR,
                    tooltip: "Сканировать QR на устройстве",
                    icon: Icon(Icons.qr_code),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Visibility(
                visible: !_handshaked,
                child: _check
                    ? const LinearProgressIndicator()
                    : SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          onPressed: _handshakeDevice,
                          child: const Text('Подключить'),
                        ),
                      ),
              ),

              Visibility(
                visible: _handshaked,
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        onPressed: _saveDevice,
                        child: const Text('Сохранить'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _manualReconnect,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Обновить подключение'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Visibility(
                visible: !_handshaked,
                child: Expanded(
                  child: Text(
                    'Если устройство было подключено к сети Wi-Fi, то необходимо определить его IP-адрес. '
                    'Для этого можно перейти в системное меню устройства: "Сопряжение" - затем распознать QR-код, представленный на экране'
                    ' устройства, нажав выше кнопку "Сканировать QR-код на устройстве". Либо перейти в системное '
                    'меню устройства "Wi-Fi Сеть"→"IP Адрес" и ввести значение IP-адреса в поле приложения выше вручную.\n'
                    'Если устройство работает в режиме точки доступа Wi-Fi и телефон подключен к соответствующей сети, то в поле '
                    '"IP-адрес устройства" введено актуальное значение по умолчанию. Вы можете просто нажать кнопку "Подключить"',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 11),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidIP(String ip) {
    final regex = RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$');
    return regex.hasMatch(ip);
  }

  ///
  /// Открывает диалог QR-сканнера
  ///
  Future<void> _scanQR() async {
    final hasCameraPermission = await _checkAndRequestPermission([
      RequiredPermissions.camera,
    ]);
    if (!hasCameraPermission || !mounted) return;

    final Barcode? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScannerPage()),
    );
    if (barcode == null) {
      return;
    }

    // Простая задержка выполнения для окончательной инициализации QR-сканера
    await Future.delayed(const Duration(milliseconds: 300));

    // Если распознанный QR является plain text
    if (barcode.valueType?.type == BarcodeValueTypeKind.text) {
      String value = barcode.rawValue ?? _defaultIPAddress;
      if (!_isValidIP(value)) {
        _showError("Содержимое QR не соответствует формату IP-адреса");
        return;
      }
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ipController.text != value) {
            setState(() {
              ipController.text = value;
            });
            _handshakeDevice();
          }
        });
      }
      /*
     Если распознанный QR является WiFi Connection String
     Устройство находится в режиме IoT и предоставляет свою собственную точку доступа
    */
    } else if (barcode.valueType?.type == BarcodeValueTypeKind.wifi) {
      final wifiData = barcode.valueType?.data;
      if (wifiData == null) {
        _showError("Не удалось извлечь данные Wi-Fi из QR-кода");
        return;
      }

      final String ssid = wifiData["ssid"] ?? '';
      final String password = wifiData["password"] ?? '';

      if (ssid.isEmpty) {
        _showError("QR-код не содержит SSID сети");
        return;
      }

      final hasPermissions = await _checkAndRequestPermission([
        RequiredPermissions.location,
        RequiredPermissions.nearbyWifi,
      ]);

      if (!hasPermissions) {
        _showError("Необходимые разрешения не предоставлены");
        return;
      }
      final success = await _connectToWifiNetwork(ssid, password);
      if (success && mounted) {
        setState(() => _check = true);
        await _handshakeDevice();
        setState(() => _check = false);
      }
    }
  }

  ///
  /// Выполняет первичный обмен с новым добавленным устройством и получает с него текущие настройки
  ///
  Future<void> _handshakeDevice() async {
    setState(() {
      _check = true;
    });
    try {
      // TODO Необходимо в DeviceDefinition включить 
      device = await getDeviceDefinition(host: ipController.text);
      var deviceSettings = await getDeviceSettings(host: ipController.text);
      if (!mounted) {
        return;
      }
      nameController.text = device!.name;



      // Перерисовка формы после получения данных с устройства IoT.
      setState(() {
        _check = false;
        _handshaked = true;
      });

      

    } catch (cause) {
      if (!mounted) return;
      setState(() {
        _check = false;
        _showError(ErrorHandler.getFriendlyErrorMessage(cause));
      });
    }
  }

  Future<void> _saveDevice() async {
    final Device deviceToSave = Device(
      id: device?.id ?? Uuid().v4(),
      name: nameController.text,
      host: ipController.text,
    );
    if (widget.device == null) {
      await DeviceRepository.instance.addDevice(deviceToSave);
    } else {
      await DeviceRepository.instance.updateDevice(deviceToSave);
    }
    Navigator.pop(context, true);
  }

  Future<void> _manualReconnect() async {
    setState(() {
      _handshaked = false;
      _check = false;
    });
    await _handshakeDevice();
  }

  void _showError(String message) {
    setState(() {
      _check = false;
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  ///
  ///  Выполняет контроль доступности необходимых систеных разрешений
  ///
  Future<bool> _checkAndRequestPermission(
    List<RequiredPermissions> requiredPermissions,
  ) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;

    List<Permission> permissionsToRequest = [];
    List<RequiredPermissions> missingPermissions = [];

    for (var e in requiredPermissions) {
      if (e.permission == Permission.location && isAndroid13OrAbove) {
        continue;
      }
      if (e.permission == Permission.nearbyWifiDevices && !isAndroid13OrAbove) {
        continue;
      }

      final status = await e.permission.status;
      if (status.isGranted) {
        continue;
      }

      if (status.isPermanentlyDenied) {
        final shouldOpenSettings = await _showOpenSettingsDialog(e.comment);
        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return false;
      }

      permissionsToRequest.add(e.permission);
      missingPermissions.add(e);
    }

    if (permissionsToRequest.isEmpty) {
      return true;
    }

    final statuses = await permissionsToRequest.request();

    bool allGranted = true;
    for (var e in missingPermissions) {
      if (!(statuses[e.permission]?.isGranted ?? false)) {
        allGranted = false;
        break;
      }
    }

    if (!allGranted) {
      final shouldRetry = await _showRequestDeniedDialog(missingPermissions);
      if (shouldRetry) {
        return _checkAndRequestPermission(requiredPermissions);
      }
      return false;
    }

    return true;
  }

  ///
  /// Отображает диалог для открытия доступа к необходимым системным разрешениям
  /// для работы с камерой телефона (QR-сканером)
  ///
  Future<bool> _showOpenSettingsDialog(String permissionComment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разрешение заблокировано'),
        content: Text(
          '$permissionComment было навсегда заблокировано.\n\n'
          'Пожалуйста, включите его в настройках приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  ///
  /// Отображает диалог с информацией о необходимых системных разрешениях для
  /// работы с QR-сканнером (камерой телефона)
  ///
  Future<bool> _showRequestDeniedDialog(
    List<RequiredPermissions> requiredPermissions,
  ) async {
    final contentText = requiredPermissions.map((e) => e.comment).join("\n");
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Необходимы разрешения'),
          content: Text(contentText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Вернуться'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Попробовать снова'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  ///
  /// Выполняет подключение к точке доступа WiFi, предоставленное IoT устройством
  ///
  Future<bool> _connectToWifiNetwork(String ssid, String password) async {
    if (!mounted) return false;
    setState(() => _check = true);

    /*
      Фиксируем текущее WiFi соединение
    */
    _previousWifiSSID = await WiFiForIoTPlugin.getSSID();

    try {
      final connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        withInternet: false,
        timeoutInSeconds: 30,
      );

      if (!connected) {
        _showError("Не удалось подключиться к сети $ssid");
        return false;
      }

      await WiFiForIoTPlugin.forceWifiUsage(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Подключено к Wi-Fi сети'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      if (mounted) _showError("Ошибка подключения: $e");
      return false;
    } finally {
      if (mounted) setState(() => _check = false);
    }
  }

  ///
  /// Выполняет подключение к предыдущей Wi-Fi сети, после отключения от Wi-Fi IoT
  ///
  Future<void> _restorePreviousWifi() async {
    // Если была предыдущая сеть — подключаемся к ней
    if (_previousWifiSSID != null && _previousWifiSSID!.isNotEmpty) {
      // Пробуем подключиться к предыдущей сети
      final connected = await WiFiForIoTPlugin.connect(
        _previousWifiSSID!,
        password: '', // Пустой пароль — система использует сохранённые данные
        withInternet: true,
        timeoutInSeconds: 30,
      );
      if (connected && mounted) {
        return;
      }
    }

    // Если не удалось вернуться к предыдущей сети — предлагаем выбрать вручную
    if (mounted) {
      final shouldSelectManually =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Подключение к Wi-Fi'),
              content: const Text(
                'Не удалось автоматически вернуться к предыдущей сети.\n'
                'Хотите выбрать сеть вручную?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Позже'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Выбрать...'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldSelectManually) {
        // Открываем системные настройки Wi-await 
        AppSettings.openAppSettings(type: AppSettingsType.wifi);
      }
    }
  }
}
