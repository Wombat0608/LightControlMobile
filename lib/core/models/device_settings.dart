extension IntFormatting on int {
  String toDigits(int width) {
    final isNegative = this < 0;
    final absoluteValue = abs();
    final formatted = absoluteValue.toString().padLeft(width - (isNegative ? 1 : 0), '0');
    return isNegative ? '-$formatted' : formatted;
  }
}

({int nextPosition, int result}) cutInt(String input, int start, int length) {
  int end = start + length;
  if (end > input.length) {
    return (nextPosition: -1, result: -1);
  }
  return (nextPosition: end, result: int.parse(input.substring(start, end)));
}

({int nextPosition, String substr}) cutSubstr(
  String input,
  int start,
  int length,
) {
  final result = cutInt(input, start, length);
  if (result.nextPosition < 0) {
    return (nextPosition: -1, substr: "");
  }
  int end = result.nextPosition + result.result;
  if (end > input.length) {
    return (nextPosition: -1, substr: "");
  }
  return (nextPosition: end, substr: input.substring(result.nextPosition, end));
}

({int nextPosition, List<int> address}) cutAddress(String input, int start) {
  final List<int> address = [-1, -1, -1, -1];
  int pos = start;
  for (int i = 0; i < 4; i++) {
    final result = cutInt(input, pos, 3);
    if (result.nextPosition == -1) {
      return (nextPosition: -1, address: address);
    }
    pos = result.nextPosition;
    address[i] = result.result;
  }
  return (nextPosition: pos, address: address);
}

class DeviceSettings {
  WiFi wifi = WiFi();
  NTP ntp = NTP(ntpHost: "ru.pool.ntp.org");

  @override
  String toString() {
    return wifi.toString() + ntp.toString();
  }

  int parse(String input, int start) {
    int pos = start;
    pos = wifi.parse(input, pos);
    if (pos == -1) {
      return -1;
    }
    return ntp.parse(input, pos);
  }
}

class WiFi {
  Network client = Network(ssid: "", password: "", dhcp: true);
  Network apm = Network(ssid: "", password: "", dhcp: true);
  @override
  String toString() {
    return client.toString() + apm.toString();
  }

  int parse(String input, int start) {
    int pos = start;
    pos = client.parse(input, pos);
    if (pos == -1) {
      return pos;
    }
    return apm.parse(input, pos);
  }

}

class Network {
  String ssid;
  bool dhcp = true;
  String password;
  List<int>? address = [-1, -1, -1, -1];
  List<int>? gateway = [-1, -1, -1, -1];
  List<int>? subnet = [-1, -1, -1, -1];
  Network({
    required this.ssid,
    required this.password,
    this.dhcp = true,
    this.address,
    this.gateway,
    this.subnet,
  });

  void skipAddress() {
    address = [-1, -1, -1, -1];
  }

  void skipGateway() {
    gateway = [-1, -1, -1, -1];
  }

  void skipSubnet() {
    subnet = [-1, -1, -1, -1];
  }

  List<int> _parseIPAddress(String ipAddress) {
    List<String> octets = ipAddress.split("\\.");
    return octets.map((e) => int.tryParse(e) ?? -1).toList();
  }

  void setAddress(String address) {
    this.address = _parseIPAddress(address);
  }

  void setGateway(String gateway) {
    this.gateway = _parseIPAddress(gateway);
  }

  void setSubnet(String subnet) {
    this.subnet = _parseIPAddress(subnet);
  }

  @override
  String toString() {
    return '${address![0].toDigits(3)}${address![1].toDigits(3)}${address![2].toDigits(3)}${address![3].toDigits(3)}'
        '${gateway![0].toDigits(3)}${gateway![1].toDigits(3)}${gateway![2].toDigits(3)}${gateway![3].toDigits(3)}'
        '${subnet![0].toDigits(3)}${subnet![1].toDigits(3)}${subnet![2].toDigits(3)}${subnet![3].toDigits(3)}'
        '${dhcp ? '1' : '0'}'
        '${ssid.length.toDigits(2)}$ssid${password.length.toDigits(2)}$password';
  }

  int parse(String input, int start) {
    int pos = start;
    var result = cutAddress(input, pos);
    if (result.nextPosition < 0) {
      return -1;
    }
    pos = result.nextPosition;
    address = result.address;
    result = cutAddress(input, pos);
    if (result.nextPosition < 0) {
      return -1;
    }
    pos = result.nextPosition;
    gateway = result.address;
    result = cutAddress(input, pos);
    if (result.nextPosition < 0) {
      return -1;
    }
    pos = result.nextPosition;
    subnet = result.address;
    var result3 = cutInt(input, pos, 1);
    if (result3.nextPosition < 0) {
      return -1;
    }
    pos = result3.nextPosition;
    dhcp = result3.result == 1 ? true : false;

    var result4 = cutSubstr(input, pos, 2);
    if (result4.nextPosition < 0) {
      return -1;
    }
    pos = result4.nextPosition;
    ssid = result4.substr;

    result4 = cutSubstr(input, pos, 2);
    if (result4.nextPosition < 0) {
      return -1;
    }
    pos = result4.nextPosition;
    password = result4.substr;
    return pos;
  }
}

class NTP {
  int gmtOffsetHr = 3;
  int gmtOffsetMn = 0;
  List<int>? ntpAddress = [-1, -1, -1, -1];
  String ntpHost;
  int? ntpPort;

  NTP({
    this.ntpHost = "",
    this.ntpAddress,
    this.ntpPort,
    this.gmtOffsetMn = 0,
    this.gmtOffsetHr = 3,
  });

  @override
  String toString() {
    return '${ntpAddress![0].toDigits(3)}${ntpAddress![1].toDigits(3)}${ntpAddress![2].toDigits(3)}${ntpAddress![3].toDigits(3)}'
        '${ntpPort!.toDigits(4)}${gmtOffsetMn.toDigits(4)}${gmtOffsetHr.toDigits(3)}${ntpHost.length.toDigits(2)}$ntpHost';
  }

  int parse(String input, int start) {
    int pos = start;
    final result = cutAddress(input, pos);
    if (result.nextPosition < 0) {
      return -1;
    }
    pos = result.nextPosition;
    ntpAddress = result.address;

    var result1 = cutInt(input, pos, 4);
    if (result1.nextPosition < 0) {
      return -1;
    }
    pos = result1.nextPosition;
    ntpPort = result1.result;

    result1 = cutInt(input, pos, 4);
    if (result1.nextPosition < 0) {
      return -1;
    }
    pos = result1.nextPosition;
    gmtOffsetMn = result1.result;

    result1 = cutInt(input, pos, 3);
    if (result1.nextPosition < 0) {
      return -1;
    }
    pos = result1.nextPosition;
    gmtOffsetHr = result1.result;

    var result2 = cutSubstr(input, pos, 2);
    if (result2.nextPosition < 0) {
      return -1;
    }
    pos = result2.nextPosition;
    ntpHost = result2.substr;
    return pos;
  }
}
