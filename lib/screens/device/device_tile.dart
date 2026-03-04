import 'package:flutter/material.dart';
import 'package:light_control/core/models/device.dart';
import 'device_page.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceTile({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.wifi),
      title: Text(device.name),
      subtitle: Text(device.host),
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DevicePage(device: device)),
            );
          },
    );
  }
}
