import 'package:http/http.dart' as http;
import 'package:light_control/core/models/device.dart';
import 'package:light_control/core/models/wi_fi_info.dart';
import 'package:light_control/core/models/device_info.dart';
import 'package:light_control/core/models/device_settings.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'dart:convert';

const int _defaultHTTPTimeout = 10; // Sec

class ErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return '⏱️ Превышено время ожидания. Проверьте подключение.';
    }
    if (error is SocketException) {
      return '🌐 Не удалось подключиться к устройству. Проверьте IP-адрес.';
    }
    if (error is HttpException) {
      if (error.message.contains('404')) return '❌ Устройство не найдено (404)';
      if (error.message.contains('403')) return '🔒 Доступ запрещен (403)';
      if (error.message.contains('500')) {
        return '⚠️ Внутренняя ошибка сервера (500)';
      }
      return '❌ Ошибка HTTP: ${error.message}';
    }
    if (error is FormatException) {
      return '📦 Неверный формат ответа от устройства';
    }
    return '😕 Произошла ошибка: ${error.toString()}';
  }
}

Stream<List<WiFiInfo>> getAvailableNetworksStream({
  String host = '192.168.4.1',
  int port = 80,
}) {
  final controller = StreamController<List<WiFiInfo>>();
  getAvailableNetworks(host: host, port: port)
      .then((networks) {
        controller.add(networks);
        controller.close();
      })
      .catchError((cause) {
        controller.addError(cause);
        controller.close();
      });
  return controller.stream;
}

Future<List<WiFiInfo>> getAvailableNetworks({
  String host = '192.168.4.1',
  int port = 80,
}) async {
  final Uri uri = Uri.parse(
    sprintf('http://%s:%d/networks', [host, port]).toString(),
  );
  final response = await http
      .get(uri)
      .timeout(
        const Duration(seconds: _defaultHTTPTimeout), // Тайм-аут 10 секунд
        onTimeout: () {
          throw TimeoutException('Запрос занял слишком много времени');
        },
      );
  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    List<WiFiInfo> rs = jsonList.map((json) => WiFiInfo.fromMap(json)).toList();
    Map<String, WiFiInfo> index = {};
    for (WiFiInfo n in rs) {
      WiFiInfo? e = index[n.ssid];
      if (e != null && n.rssi > e.rssi) {
        index[n.ssid] = n;
      } else {
        index[n.ssid] = n;
      }
    }
    return index.values.toList();
  } else if (response.statusCode == 404) {
    return [];
  } else {
    throw Exception('Невозможно подключиться к устройству.');
  }
}

Future<Device> getDeviceDefinition({
  String host = '192.168.4.1',
  int port = 80,
}) async {
  final Uri uri = Uri.parse(
    sprintf('http://%s:%d/info', [host, port]).toString(),
  );
  final response = await http
      .get(uri)
      .timeout(
        const Duration(seconds: _defaultHTTPTimeout), // Тайм-аут 10 секунд
        onTimeout: () {
          throw TimeoutException('Запрос занял слишком много времени');
        },
      );
  if (response.statusCode == 200) {
    dynamic json = jsonDecode(response.body);
    DeviceInfo deviceInfo  = DeviceInfo.fromMap(json);
    final Device d = Device(
      id: const Uuid().v4(),
      name: deviceInfo.deviceName,
      host: host,
    );
    d.wifiMode = deviceInfo.wifiMode;
    return d;
  } else {
    throw Exception('Невозможно подключиться к устройству.');
  }
}

Future<void> postDeviceSettings({
  String host = '192.168.4.1',
  int port = 80,
  required DeviceSettings deviceSettings,
}) async {
  try {
    final Uri uri = Uri.parse('http://$host:$port/settings');
    String requestBody = deviceSettings.toString();
    final response = await http
        .post(uri, body: requestBody)
        .timeout(
          const Duration(seconds: _defaultHTTPTimeout), // Тайм-аут 10 секунд
        );
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: ${response.statusCode} - ${response.body}',
      );
    }
  } on TimeoutException catch (_) {
    throw Exception('Превышено время ожидания ответа от устройства');
  } on SocketException catch (_) {
    throw Exception('Устройство недоступно в сети');
  } catch (e) {
    throw Exception('Ошибка при отправке настроек: $e');
  }
}

Future<DeviceSettings> getDeviceSettings({
  String host = '192.168.4.1',
  int port = 80,
}) async {
  final Uri uri = Uri.parse('http://$host:$port/settings');
  final response = await http
      .get(uri)
      .timeout(
        const Duration(seconds: _defaultHTTPTimeout), // Тайм-аут 10 секунд
        onTimeout: () {
          throw TimeoutException('Запрос занял слишком много времени');
        },
      );
  if (response.statusCode == 200) {
    DeviceSettings settings = DeviceSettings();
    if (settings.parse(response.body, 0) == -1) {
      throw Exception('Формат настроек некорректен.');
    }
    return settings;
  } else {
    throw Exception('Невозможно подключиться к устройству.');
  }
}
