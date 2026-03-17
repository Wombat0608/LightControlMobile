import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final String id;
  final String name;
  final String host;
  final int port;

  const Device({
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
