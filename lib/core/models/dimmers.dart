import 'package:equatable/equatable.dart';

// Модель для диммера
class Dimmer extends Equatable {
  final String id; // уникальный идентификатор
  String name; // имя диммера (например, "Люстра")
  int brightness; // яркость от 0 до 100
  final int index;
  Dimmer({
    required this.id,
    required this.name,
    this.brightness = 0,
    this.index = 0,
  });

  @override
  List<Object?> get props => [id, name, brightness, index];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'brightness': brightness, 'index': index};
  }

  // Создание из Map
  factory Dimmer.fromMap(Map<String, dynamic> map) {
    return Dimmer(
      id: map['id'],
      name: map['name'],
      brightness: map['brightness'],
      index: map['index'],
    );
  }
}
