import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/core/models/wi_fi_info.dart';
import '../../core/client/device_adapter.dart';

class NetworksList extends StatefulWidget {
  final Device device;
  NetworksList({super.key, required this.device});

  @override
  State<NetworksList> createState() => _NetworksListState();
}

class _NetworksListState extends State<NetworksList> {
  String? _selectedNetwork;
  late Stream<List<WiFiInfo>> _networksStream;
  bool _isLoading = true;
  String? _error;

  void _initStream() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Сохраняем стрим в переменную
      _networksStream = getAvailableNetworksStream(
        host: widget.device.host,
        port: widget.device.port,
      );
    } catch (cause) {
      setState(() {
        _error = cause.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initStream();
  }

@override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildError();
    }

    return StreamBuilder<List<WiFiInfo>>(
      stream: _networksStream,
      builder: (context, snapshot) {
        // Обработка ошибок стрима
        if (snapshot.hasError) {
          return _buildErrorWithRetry(snapshot.error);
        }

        // Показываем загрузку пока нет данных
        if (!snapshot.hasData) {
          return _buildLoading();
        }

        // Если данные есть - показываем список
        final networks = snapshot.data!;
        
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
            onPressed: () {
              setState(() {
                _initStream();
              });
            },
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
            onPressed: () {
              setState(() {
                _initStream();
              });
            },
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
    return ListView.builder(
      itemCount: networks.length,
      itemBuilder: (context, index) {
        final network = networks[index];
        final isSelected = _selectedNetwork == network.ssid;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            leading: _buildSignalIcon(network.rssi, isSelected),
            title: Text(
              network.ssid,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            subtitle: Text('Сигнал: ${network.rssi} dBm'),
            trailing: _buildSecurityIcon(network.encType),
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isSelected
                  ? BorderSide(color: Theme.of(context).primaryColor)
                  : BorderSide.none,
            ),
            onTap: () {
              setState(() {
                if (_selectedNetwork == network.ssid) {
                  _selectedNetwork = null;
                } else {
                  _selectedNetwork = network.ssid;
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSignalIcon(int rssi, bool isSelected) {
    int bars = _getSignalBars(rssi);
    Color color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

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
        return Icons.signal_wifi_4_bar;
      default:
        return Icons.signal_wifi_0_bar;
    }
  }

  int _getSignalBars(int rssi) {
    if (rssi >= 100) return 4;
    if (rssi >= 80) return 1;
    if (rssi >= 70) return 2;
    if (rssi >= 60) return 3;
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
        icon = Icons.lock;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 18);
  }
}
