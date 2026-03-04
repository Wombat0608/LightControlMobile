import 'package:flutter/material.dart';
import 'package:light_control/screens/device/device_page.dart';
import 'package:light_control/screens/device/devices_list_widget.dart';

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
      body: Center(
        child: DeviceList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DevicePage()),
          );
        },
        tooltip: 'Add new device...',
        child: const Icon(Icons.add),
      ),
    );
  }
}
