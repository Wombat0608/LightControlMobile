import 'package:equatable/equatable.dart';
import './relays.dart';
import './dimmers.dart';

class Device extends Equatable {
  final String id;
  final String name;
  final String host;
  final int port;

  late int wifiMode;

  final List<Relay> relays = [
    Relay(id: '_relay0', name: 'Реле 0', index: 0, state: false),
    Relay(id: '_relay1', name: 'Реле 1', index: 1, state: true),
    Relay(id: '_relay2', name: 'Реле 2', index: 2, state: false),
    Relay(id: '_relay3', name: 'Реле 3', index: 3, state: false),
    Relay(id: '_relay4', name: 'Реле 4', index: 4, state: true),
    Relay(id: '_relay5', name: 'Реле 5', index: 5, state: false),
    Relay(id: '_relay6', name: 'Реле 6', index: 6, state: false),
    Relay(id: '_relay7', name: 'Реле 7', index: 7, state: true),
  ];
  final List<Dimmer> dimmers = [
    Dimmer(id: '_dimmer0', name: 'Диммер 0', index: 0, brightness: 45),
  ];

  Device({
    required this.id,
    required this.name,
    required this.host,
    this.port = 80,
  });

  @override
  List<Object> get props => [id, name, host, port];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'host': host, 'port': port};
  }

  // Создание из Map
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'],
      name: map['name'],
      host: map['host'],
      port: map['port'],
    );
  }
}
