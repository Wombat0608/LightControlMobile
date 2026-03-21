import 'package:flutter/material.dart';
import 'package:light_control/screens/device/device_page.dart';
import 'package:light_control/screens/device/devices_list_widget.dart';
import 'package:light_control/screens/device/device_control_page.dart'; // новый экран

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: DeviceList(
        onDeviceSelected: (device) {
          // Переходим на экран управления устройством
          if (device != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceControlPage(device: device),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DevicePage()),
          );
        },
        tooltip: 'Добавить устройство',
        child: const Icon(Icons.add),
      ),
    );
  }
}