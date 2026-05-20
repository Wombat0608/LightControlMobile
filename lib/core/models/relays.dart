import 'package:equatable/equatable.dart';

// Модель для реле (ключа)
class Relay extends Equatable {
  final String id; // уникальный идентификатор
  String name; // имя реле (например, "Свет", "Розетка")
  bool state; // состояние: true = включено, false = выключено
  final int index;

  Relay({
    required this.id,
    required this.name,
    this.index = 0,
    this.state = false,
  });

  @override
  List<Object?> get props => [id, name, state, index];

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'state': state, 'index': index};
  }

  // Создание из Map
  factory Relay.fromMap(Map<String, dynamic> map) {
    return Relay(
      id: map['id'],
      name: map['name'],
      state: map['state'],
      index: map['index'],
    );
  }
}
