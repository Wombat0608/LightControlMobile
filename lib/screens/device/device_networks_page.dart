import 'package:flutter/material.dart';
import '../../core/models/device.dart';
import 'networks_list_widget.dart';

class DeviceNetworksPage extends StatefulWidget {
  final Device device;

  const DeviceNetworksPage({super.key, required this.device});

  @override
  State<StatefulWidget> createState() => _DeviceNetworksPageState();
}

class _DeviceNetworksPageState extends State<DeviceNetworksPage> {
  late NetworksList _networksList;

  @override
  void initState() {
    super.initState();
    // Создаем виджет ОДИН РАЗ в initState
    _networksList = NetworksList(device: widget.device);
  }

  @override
  void didUpdateWidget(DeviceNetworksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если устройство изменилось, обновляем список
    if (oldWidget.device.host != widget.device.host ||
        oldWidget.device.port != widget.device.port) {
      _networksList = NetworksList(device: widget.device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.device.name),
      ),
      body: Center(child: _networksList),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _networksList.refresh();
        },
        tooltip: 'Refresh list...',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
