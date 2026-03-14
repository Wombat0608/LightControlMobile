import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/screens/qr_scanner/qr_scanner_page.dart';
import 'package:light_control/core/client/device_adapter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:light_control/core/persistence/device_repository.dart';
import 'package:uuid/uuid.dart';

class DevicePage extends StatefulWidget {
  final Device? device;

  const DevicePage({super.key, this.device});

  @override
  State<StatefulWidget> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late final TextEditingController ipController;
  late final TextEditingController nameController;

  late final _ipMaskFormatter;
  Device? device;

  bool _check = false;
  bool _handshaked = false;
  late String _errorMessage;

  void _onIpChanged() {
    print('IP изменился: ${ipController.text}');
    // Здесь можно делать валидацию или другие действия
  }

  @override
  void initState() {
    super.initState();
    final initialIP = widget.device?.host ?? '192.168.4.1';
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
    // Можно добавить listener если нужно
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
            icon: Icon(Icons.more_vert), // вертикальное троеточие
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(),
            onSelected: (String result) {
              // обработка
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
              // Поле для имени
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

              // Поле для IP-адреса
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
                  const SizedBox(width: 8), // Отступ между полем и кнопкой

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
                child: SizedBox(
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

  Future<void> _scanQR() async {
    final String? ipAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QrScannerPage()),
    );
    if (ipAddress == null) {
      return;
    }
    if (!_isValidIP(ipAddress)) {
      _showError("Содержимое QR не соответствует формату IP-адреса");
      return;
    }
    if (mounted) {
      setState(() {
        ipController.text = ipAddress;
      });
    }
  }

  Future<void> _handshakeDevice() async {
    setState(() {
      _check = true;
    });
    try {
      device = await getDeviceDefinition(host: ipController.text);
      var deviceSettings = await getDeviceSettings(host: ipController.text);
      
      if (!mounted) return;
      nameController.text = device!.name;
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
      id: device?.id ?? Uuid().v4(), // Генерируем ID для нового устройства
      name: nameController.text,
      host: ipController.text,
    );
    if (widget.device == null) {
      // Режим создания: добавляем новое устройство
      await DeviceRepository.instance.addDevice(deviceToSave);
    } else {
      // Режим редактирования: обновляем существующее
      await DeviceRepository.instance.updateDevice(deviceToSave);
    }
    Navigator.pop(context, true);
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
}
