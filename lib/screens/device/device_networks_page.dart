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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.device.name),
      ),
      body: Center(child: NetworksList(device: widget.device)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        tooltip: 'Refresh list...',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
