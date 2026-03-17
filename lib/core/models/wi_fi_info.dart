class WiFiInfo {
  final String ssid;
  final int encType;
  final int rssi;
  final bool connected;

  WiFiInfo({
    required this.ssid,
    required this.encType,
    required this.rssi,
    this.connected = false,
  });
  factory WiFiInfo.fromMap(Map<String, dynamic> map) {
    return WiFiInfo(
      ssid: map['ssid'],
      encType: map['encType'],
      rssi: map['rssi'],
      connected: map['connected'],
    );
  }
}
