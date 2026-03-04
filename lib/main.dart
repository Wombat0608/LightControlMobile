import 'package:flutter/material.dart';
import 'screens/home/home_page.dart';
import 'package:light_control/core/persistence/device_repository.dart';

void main() async {
  await DeviceRepository.initialize();
  runApp(const LightControlApp());
}

class LightControlApp extends StatelessWidget {
  const LightControlApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Light Control App',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 125, 220, 116)),
      ),
      home: const HomePage(title: 'Light Control'),
    );
  }
}
