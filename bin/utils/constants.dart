import 'dart:io';

class Constants {
  const Constants._();

  /// find my ip from network interfaces where ip start with
  /// 192.168[subnet]
  /// default value for [subnet] is .1.
  /// if find no address return [InternetAddress.loopbackIPv4]
  static Future<InternetAddress> findMyIp([String subnet = '.1.']) async {
    final interfaces = await NetworkInterface.list();
    if (interfaces.isEmpty) return InternetAddress.loopbackIPv4;
    for (var interface in interfaces) {
      if (interface.addresses.isEmpty) continue;
      for (var address in interface.addresses) {
        if (address.address.startsWith('192.168$subnet')) return address;
      }
    }
    return InternetAddress.loopbackIPv4;
  }

  static const kEndOfMessage = 'message:end';
}
