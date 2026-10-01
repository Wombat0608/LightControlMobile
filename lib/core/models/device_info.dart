class DeviceInfo {
  final String deviceName;
  final int wifiMode;

  DeviceInfo({required this.deviceName, required this.wifiMode});

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(deviceName: map["deviceName"], wifiMode: map["wifiMode"]);
  }
}