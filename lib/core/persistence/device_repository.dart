import 'dart:async';
import '../models/device.dart';
import 'device_storage_service.dart';

class DeviceRepository {
  late final DeviceStorageService _storage;
  final _controller = StreamController<List<Device>>.broadcast();
  Stream<List<Device>> get devicesStream => _controller.stream;
  DeviceRepository._();
  static final DeviceRepository _instance = DeviceRepository._();
  static DeviceRepository get instance => _instance;
  List<Device> _cachedDevices = [];

  List<Device> get currentDevices => _cachedDevices;

  Future<void> _loadDevicesInternal() async {
    final devices = _storage.getAllDevices();
    _cachedDevices = devices;

    // Отправляем в стрим только если есть подписчики
    if (_controller.hasListener) {
      _controller.add(devices);
    }
  }

  // Загрузить все устройства
  Future<List<Device>> loadDevices() async {
    await _loadDevicesInternal();
    return _cachedDevices;
  }

  // Добавить новое устройство
  Future<void> addDevice(Device device) async {
    await _storage.saveDevice(device);
    await _loadDevicesInternal(); // Обновляем поток
  }

  // Обновить статус устройства
  Future<void> updateDevice(Device modified) async {
    final device = _storage.getDevice(modified.id);
    if (device != null) {
      await _storage.updateDevice(modified);
      await _loadDevicesInternal();
    }
  }

  // Удалить устройство
  Future<void> removeDevice(String id) async {
    await _storage.deleteDevice(id);
    await _loadDevicesInternal();
  }

  void dispose() {
    _controller.close();
  }

  // Метод инициализации (вызвать один раз при старте)
  static Future<void> initialize() async {
    final storage = DeviceStorageService();
    await storage.init();
    _instance._storage = storage;
    await _instance._loadDevicesInternal(); // Загружаем при инициализации
  }
}
