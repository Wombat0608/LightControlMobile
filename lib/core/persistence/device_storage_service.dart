import 'package:hive_flutter/hive_flutter.dart';
import '../models/device.dart';

class DeviceStorageService {
  static const String _boxName = 'devices_box';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // Сохранить устройство
  Future<void> saveDevice(Device device) async {
    await _box.put(device.id, device.toMap());
  }

  // Получить все устройства
  List<Device> getAllDevices() {
    return _box.values.map((item) {
      return Device.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  // Получить конкретное устройство
  Device? getDevice(String id) {
    final data = _box.get(id);
    return data != null
        ? Device.fromMap(Map<String, dynamic>.from(data))
        : null;
  }

  // Удалить устройство
  Future<void> deleteDevice(String id) async {
    await _box.delete(id);
  }

  // Обновить устройство
  Future<void> updateDevice(Device device) async {
    await _box.put(device.id, device.toMap());
  }
}
