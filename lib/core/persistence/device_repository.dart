import 'dart:async';
import '../models/device.dart';
import 'device_storage_service.dart';

class DeviceRepository {
  late final DeviceStorageService _storage;
  final _controller = StreamController<List<Device>>.broadcast();
  Stream<List<Device>> get devicesStream => _controller.stream;
  DeviceRepository._();
  static DeviceRepository _instance = DeviceRepository._();

  static DeviceRepository get instance => _instance;

  // Загрузить все устройства
  Future<List<Device>> loadDevices() async {
    final devices = _storage.getAllDevices();
    _controller.add(devices);
    return devices;
  }

  // Добавить новое устройство
  Future<void> addDevice(Device device) async {
    await _storage.saveDevice(device);
    await loadDevices(); // Обновляем поток
  }

  // Обновить статус устройства
  Future<void> updateDevice(Device modified) async {
    final device = _storage.getDevice(modified.id);
    if (device != null) {
      await _storage.updateDevice(modified);
      await loadDevices();
    }
  }

  // Удалить устройство
  Future<void> removeDevice(String id) async {
    await _storage.deleteDevice(id);
    await loadDevices();
  }

  void dispose() {
    _controller.close();
  }

  // Метод инициализации (вызвать один раз при старте)
  static Future<void> initialize() async {
    final storage = DeviceStorageService();
    await storage.init();
    _instance._storage = storage;
    await _instance.loadDevices();
  }
}
