import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'package:light_control/core/persistence/device_repository.dart';
import 'device_tile.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Device>>(
      stream: DeviceRepository.instance.devicesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoading();
        if (snapshot.hasError) return _buildError(snapshot.error);
        if (snapshot.data!.isEmpty) return _buildEmpty();
        
        return _buildList(snapshot.data!);
      },
    );
  }

  Widget _buildLoading() => Center(child: CircularProgressIndicator());
  
  Widget _buildError(dynamic error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 48),
        SizedBox(height: 16),
        Text('Ошибка: $error'),
        ElevatedButton(
          onPressed: () => DeviceRepository.instance.loadDevices(),
          child: Text('Повторить'),
        ),
      ],
    ),
  );
  
  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.devices_other, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Нет устройств'),
      ],
    ),
  );
  
  Widget _buildList(List<Device> devices) => ListView.builder(
    itemCount: devices.length,
    itemBuilder: (context, index) => DeviceTile(device: devices[index]),
  );
}