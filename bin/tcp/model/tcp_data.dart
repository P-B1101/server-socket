import 'dart:typed_data';

import '../../client/client_type.dart';

class TCPData {
  final Object? body;
  final String? fileName;
  final ClientType clientType;

  const TCPData({
    required this.body,
    required this.fileName,
    required this.clientType,
  });

  factory TCPData.command(String command, ClientType clientType) => TCPData(
        body: command,
        fileName: null,
        clientType: clientType,
      );

  factory TCPData.clientType(ClientType clientType) => TCPData(
        body: null,
        fileName: null,
        clientType: clientType,
      );

  factory TCPData.file(
    Uint8List bytes,
    String? fileName,
    ClientType clientType,
  ) =>
      TCPData(
        body: bytes,
        fileName: fileName,
        clientType: clientType,
      );

  @override
  String toString() {
    return body is String ? body.toString() : clientType.stringValue;
  }
}
