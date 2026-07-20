import 'package:flutter/material.dart';
import 'package:light_control/core/client/device_adapter.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/core/models/device_settings.dart';
import 'package:light_control/core/persistence/device_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'device_page.dart';
import 'device_networks_page.dart';
import 'dart:async';

class DeviceList extends StatefulWidget {
  final void Function(Device? device)? onDeviceSelected;
  const DeviceList({super.key, this.onDeviceSelected});

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class DeviceSettingsCache {
  final DeviceSettings? deviceSettings;
  final DateTime lastUpdated;
  bool loaded;

  DeviceSettingsCache({
    this.deviceSettings,
    required this.lastUpdated,
    this.loaded = true,
  });
}

class _DeviceListState extends State<DeviceList> {
  String? _selectedDeviceId;
  final Map<String, DeviceSettingsCache> _deviceSettings = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeviceRepository.instance.loadDevices();
    });

    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 4), (timer) {
      _refreshAllDevices();
    });
  }

  Future<void> _refreshAllDevices() async {
    final devices = await DeviceRepository.instance.devicesStream.first;
    for (var device in devices) {
      _refreshDeviceData(device.id, device.host);
    }
  }

  Future<void> _refreshDeviceData(String deviceId, String deviceHost) async {
    try {
      final settings = await Future.wait([
        getDeviceSettings(host: deviceHost),
      ]).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _deviceSettings[deviceId] = DeviceSettingsCache(
            deviceSettings: settings[0],
            lastUpdated: DateTime.now(),
          );
        });
      }
    } catch (e) {
      print('Ошибка обновления устройства $deviceId: $e');

      if (mounted) {
        setState(() {
          _deviceSettings[deviceId] = DeviceSettingsCache(
            lastUpdated: DateTime.now(),
            loaded: false,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Device>>(
      stream: DeviceRepository.instance.devicesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final devices = snapshot.data!;

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            final isSelected = _selectedDeviceId == device.id;
            return _buildDeviceTile(device, isSelected);
          },
        );
      },
    );
  }

  Widget _buildDeviceTile(Device device, bool isSelected) {
    // Проверяем кэш
    final cachedData = _deviceSettings[device.id];
    final needsRefresh =
        cachedData == null ||
        !cachedData.loaded ||
        DateTime.now().difference(cachedData.lastUpdated) >
            const Duration(minutes: 2);

    if (needsRefresh) {
      // Запускаем обновление в фоне, не блокируя отрисовку
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshDeviceData(device.id, device.host);
      });
    }

    final bool settingsInit =
        _deviceSettings[device.id] != null &&
        _deviceSettings[device.id]?.loaded == true;

    return ListTile(
      leading: Stack(
        children: [
          SvgPicture.asset('assets/icons/light.svg'),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildStatusIndicator(device, cachedData),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(child: Text(device.name)),
          if (cachedData?.deviceSettings != null)
            Icon(Icons.settings_applications, size: 16, color: Colors.grey),
        ],
      ),
      subtitle: Text(device.host),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.2),
      onTap: () {
        setState(() {
          if (_selectedDeviceId == device.id) {
            _selectedDeviceId = null;
            widget.onDeviceSelected?.call(null);
          } else {
            _selectedDeviceId = device.id;
            widget.onDeviceSelected?.call(device);
          }
        });
      },
      trailing: PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => _handleMenu(context, device, value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
          const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          PopupMenuItem(
            value: 'network',
            enabled: settingsInit,
            child: Text('Настроить Wi-Fi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Device device, DeviceSettingsCache? cachedData) {
    if (cachedData == null) {
      // Нет данных - показываем загрузку только при первом запросе
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Используем кэшированные данные
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cachedData.loaded ? Colors.green : Colors.grey,
      ),
    );
  }

  // Остальные методы (_handleMenu, _showDeleteDialog) остаются без изменений

  void _handleMenu(BuildContext context, Device device, String value) {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DevicePage(device: device)),
        );
        break;
      case 'delete':
        _showDeleteDialog(context, device);
        break;
      case 'network':
        if (_deviceSettings[device.id]?.deviceSettings != null) {
          final settings = _deviceSettings[device.id]!.deviceSettings;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DeviceNetworksPage(device: device, deviceSettings: settings),
            ),
          );
        }
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить устройство'),
        content: Text('Удалить "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              DeviceRepository.instance.removeDevice(device.id);
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
