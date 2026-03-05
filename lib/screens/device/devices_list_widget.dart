import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/core/persistence/device_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'device_page.dart';
import 'device_networks_page.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeviceRepository.instance.loadDevices();
    });
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

            return ListTile(
              leading: SvgPicture.asset('assets/icons/light.svg'),
              title: Text(device.name),
              subtitle: Text(device.host),
              selected: isSelected,
              selectedTileColor: Theme.of(
                context,
              ).primaryColor.withOpacity(0.2),
              onTap: () {
                setState(() {
                  if (_selectedDeviceId == device.id) {
                    _selectedDeviceId = null; // снять выделение
                  } else {
                    _selectedDeviceId = device.id; // выделить новое
                  }
                });
              },
              // Добавляем trailing меню
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_vert),
                onSelected: (value) => _handleMenu(context, device, value),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  PopupMenuItem(value: 'delete', child: Text('Удалить')),
                  PopupMenuItem(
                    value: 'network',
                    child: Text('Настроить Wi-Fi'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeviceNetworksPage(device: device)),
        );
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
