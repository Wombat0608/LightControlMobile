// Модель для реле (ключа)
class Relay {
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
}
