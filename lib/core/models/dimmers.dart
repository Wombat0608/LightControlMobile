// Модель для диммера
class Dimmer {
  final String id; // уникальный идентификатор
  final String name; // имя диммера (например, "Люстра")
  int brightness; // яркость от 0 до 100
  final int index;
  Dimmer({
    required this.id,
    required this.name,
    this.brightness = 0,
    this.index = 0,
  });
}
