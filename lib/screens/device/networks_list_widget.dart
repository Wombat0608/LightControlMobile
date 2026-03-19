import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/core/models/wi_fi_info.dart';
import '../../core/client/device_adapter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:light_control/core/models/device_settings.dart';

class NetworksList extends StatefulWidget {
  final Device device;
  final DeviceSettings? deviceSettings;

  NetworksList({super.key, required this.device, this.deviceSettings}) {}

  @override
  State<NetworksList> createState() => _NetworksListState();

  void refresh() {
    final state = _NetworksListState._instance;
    state?._refreshNetworks();
  }
}

class _NetworksListState extends State<NetworksList> {
  static _NetworksListState? _instance;
  String? _selectedNetwork;
  Stream<List<WiFiInfo>>? _networksStream;
  bool _isLoading = false;
  String? _error;
  late final _ipMaskFormatter;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _initStream();

    _ipMaskFormatter = MaskTextInputFormatter(
      mask: '###.###.###.###',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  @override
  void didUpdateWidget(NetworksList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если изменился host или port, обновляем стрим
    if (oldWidget.device.host != widget.device.host ||
        oldWidget.device.port != widget.device.port) {
      _refreshNetworks();
    }
  }

  void _initStream() {
    _refreshNetworks();
  }

  Future<void> _refreshNetworks() async {
    // Предотвращаем множественные вызовы
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Создаем новый стрим
      _networksStream = getAvailableNetworksStream(
        host: widget.device.host,
        port: widget.device.port,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (cause) {
      if (mounted) {
        setState(() {
          _error = cause.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если есть ошибка - показываем сообщение об ошибке
    if (_error != null) {
      return _buildError();
    }

    // Если стрим еще не создан или идет загрузка
    if (_networksStream == null || _isLoading) {
      return _buildLoading();
    }

    return StreamBuilder<List<WiFiInfo>>(
      stream: _networksStream,
      builder: (context, snapshot) {
        // Обработка ошибок стрима
        if (snapshot.hasError) {
          return _buildErrorWithRetry(snapshot.error);
        }

        // Показываем загрузку пока нет данных
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        // Если данные есть - показываем список
        final networks = snapshot.data ?? [];

        if (networks.isEmpty) {
          return _buildEmpty();
        }

        return _buildList(networks);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Поиск WiFi сетей...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Ошибка инициализации'),
          const SizedBox(height: 8),
          Text(_error ?? 'Неизвестная ошибка'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshNetworks,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWithRetry(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Не удалось получить список сетей'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshNetworks,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Сети не найдены',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<WiFiInfo> networks) {
    return RefreshIndicator(
      onRefresh: _refreshNetworks,
      child: ListView.builder(
        itemCount: networks.length,
        itemBuilder: (context, index) {
          final network = networks[index];
          final isSelected = _selectedNetwork == network.ssid;
          return ListTile(
            leading: _buildSignalIcon(
              network.rssi,
              isSelected,
              networks[index].connected,
            ),
            title: Text(
              network.ssid,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: networks[index].connected
                    ? Colors.blue
                    : (isSelected ? Theme.of(context).primaryColor : null),
              ),
            ),
            subtitle: Text(
              '${networks[index].connected ? "Подключено, " : ""}Сигнал: ${network.rssi} dBm',
            ),
            trailing: _buildSecurityIcon(network.encType),
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.2),
            onTap: () {
              setState(() {
                if (_selectedNetwork == network.ssid) {
                  _selectedNetwork = null;
                } else {
                  _selectedNetwork = network.ssid;
                }
                _showPasswordSheet(network);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSignalIcon(int rssi, bool isSelected, bool connected) {
    int bars = _getSignalBars(rssi);
    Color color = connected
        ? Colors.blue
        : (isSelected ? Theme.of(context).primaryColor : Colors.grey);
    return Icon(_getSignalIcon(bars), color: color);
  }

  IconData _getSignalIcon(int bars) {
    switch (bars) {
      case 1:
        return Icons.wifi_1_bar;
      case 2:
        return Icons.wifi_2_bar;
      case 3:
      case 4:
        return Icons.wifi;
      default:
        return Icons.wifi_off;
    }
  }

  int _getSignalBars(int rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Widget _buildSecurityIcon(int encType) {
    IconData icon;
    Color color;

    switch (encType) {
      case 0:
        icon = Icons.lock_open;
        color = Colors.green;
        break;
      case 1:
      case 2:
      case 3:
      case 4:
        icon = Icons.lock;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 18);
  }

  Future<void> _showPasswordSheet(WiFiInfo network) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Эти переменные должны быть внутри билдера или захвачены из замыкания
    String ipType = 'dhcp';
    final ipController = TextEditingController();
    final gatewayController = TextEditingController();
    final subnetController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Используем StatefulBuilder для внутреннего состояния
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Заголовок
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Подключение к сети',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Название сети
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildSignalIcon(
                              network.rssi,
                              false,
                              network.connected,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    network.ssid,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: network.connected
                                          ? Colors.blue
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        network.encType == 0
                                            ? Icons.lock_open
                                            : Icons.lock,
                                        size: 14,
                                        color: network.encType == 0
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        network.encType == 0
                                            ? 'Открытая сеть'
                                            : 'Защищенная сеть',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: network.encType == 0
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Поле ввода пароля (только для защищенных сетей)
                      if (network.encType != 0) ...[
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            hintText: 'Введите пароль сети',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.key),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите пароль';
                            }
                            if (value.length < 8) {
                              return 'Пароль должен быть не менее 8 символов';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Используем value вместо initialValue
                      DropdownButtonFormField<String>(
                        initialValue: ipType,
                        decoration: InputDecoration(
                          labelText: 'Настройки IP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.settings_ethernet),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'dhcp',
                            child: Row(
                              children: [
                                SizedBox(width: 8),
                                Text('DHCP (автоматически)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'static',
                            child: Row(
                              children: [
                                SizedBox(width: 8),
                                Text('Статический IP (вручную)'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              ipType = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Поля для статического IP
                      if (ipType == 'static') ...[
                        TextFormField(
                          inputFormatters: [_ipMaskFormatter],
                          controller: ipController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          decoration: InputDecoration(
                            labelText: 'IP-адрес',
                            hintText: '192.168.1.100',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (ipType == 'static') {
                              if (value == null || value.isEmpty) {
                                return 'Введите IP-адрес';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          inputFormatters: [_ipMaskFormatter],
                          controller: gatewayController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Шлюз',
                            hintText: '192.168.1.1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (ipType == 'static') {
                              if (value == null || value.isEmpty) {
                                return 'Введите адрес шлюза';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          inputFormatters: [_ipMaskFormatter],
                          controller: subnetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Маска подсети',
                            hintText: '255.255.255.0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (ipType == 'static') {
                              if (value == null || value.isEmpty) {
                                return 'Введите маску подсети';
                              }
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Кнопка подключения
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              // Собираем все данные в Map
                              final connectionData = <String, dynamic>{
                                'password': network.encType == 0
                                    ? ''
                                    : passwordController.text,
                                'ipType': ipType,
                              };

                              if (ipType == 'static') {
                                connectionData['ip'] = ipController.text;
                                connectionData['gateway'] =
                                    gatewayController.text;
                                connectionData['subnet'] =
                                    subnetController.text;
                              }

                              Navigator.pop(context, connectionData);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            network.encType == 0
                                ? 'Подключиться'
                                : 'Подключиться с паролем',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Обработка результата
    if (result != null) {
      final password = result['password'] as String;
      final ipType = result['ipType'] as String;

      if (ipType == 'dhcp') {
        _showConnectionConfirmDialog(
          network.ssid,
          () => _connectToNetwork(network, password),
        );
      } else {
        final ip = result['ip'] as String;
        final gateway = result['gateway'] as String;
        final subnet = result['subnet'] as String;
        _showConnectionConfirmDialog(
          network.ssid,
          () => _connectToNetworkStatic(network, password, ip, gateway, subnet),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showConnectionConfirmDialog(
    String ssid,
    Future<void> Function() connect,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Подключение к Wi-Fi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Устройство будет подключено к сети "$ssid"',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'После изменения настроек устройство перезагрузится и появится в сети.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Закрываем диалог подтверждения
                Navigator.pop(dialogContext);

                if (context.mounted) {
                  Navigator.pop(context); // Закрываем BottomSheet

                  // Выполняем подключение
                  try {
                    await connect();
                   //Navigator.pop(context); // Закрываем страницу сетей
                  } catch (cause) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка подключения: $cause'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Просто закрываем диалог
                Navigator.pop(dialogContext);
              },
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectToNetwork(WiFiInfo network, String password) async {
    if (widget.deviceSettings != null) {
      widget.deviceSettings!.wifi.client.ssid = network.ssid;
      widget.deviceSettings!.wifi.client.password = password;
      widget.deviceSettings!.wifi.client.skipAddress();
      widget.deviceSettings!.wifi.client.skipGateway();
      widget.deviceSettings!.wifi.client.skipSubnet();
      widget.deviceSettings!.wifi.client.dhcp = true;

      return postDeviceSettings(
        host: widget.device.host,
        deviceSettings: widget.deviceSettings!,
      );
    }
  }

  Future<void> _connectToNetworkStatic(
    WiFiInfo network,
    String password,
    String ip,
    String gateway,
    String subnet,
  ) async {
    if (widget.deviceSettings != null) {
      widget.deviceSettings!.wifi.client.ssid = network.ssid;
      widget.deviceSettings!.wifi.client.password = password;
      widget.deviceSettings!.wifi.client.setAddress(ip);
      widget.deviceSettings!.wifi.client.setGateway(gateway);
      widget.deviceSettings!.wifi.client.setSubnet(subnet);
      widget.deviceSettings!.wifi.client.dhcp = false;

      return postDeviceSettings(
        host: widget.device.host,
        deviceSettings: widget.deviceSettings!,
      );
    }
  }
}
