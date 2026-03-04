class WiFiInfo {
  final String ssid;
  final int encType;
  final int rssi;

  WiFiInfo({required this.ssid, required this.encType, required this.rssi});
  factory WiFiInfo.fromMap(Map<String, dynamic> map) {
    return WiFiInfo(
      ssid: map['ssid'],
      encType: map['encType'],
      rssi: map['rssi'],
    );
  }
}
