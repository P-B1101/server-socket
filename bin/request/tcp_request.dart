import 'tcp_command.dart';
import 'client_type.dart';

class TCPRequest {
  final TCPCommand command;
  final Object? body;
  final String? fileName;
  final ClientType clientType;

  const TCPRequest({
    required this.body,
    required this.command,
    required this.fileName,
    required this.clientType,
  });

  factory TCPRequest.command(String command, ClientType clientType) =>
      TCPRequest(
        body: command,
        command: TCPCommand.sendMessage,
        fileName: null,
        clientType: clientType,
      );

  factory TCPRequest.clientType(ClientType clientType) => TCPRequest(
        body: null,
        command: TCPCommand.sendMessage,
        fileName: null,
        clientType: clientType,
      );

  factory TCPRequest.file(
          List<int> bytes, String? fileName, ClientType clientType) =>
      TCPRequest(
        body: bytes,
        command: TCPCommand.sendFile,
        fileName: fileName,
        clientType: clientType,
      );

  @override
  String toString() {
    switch (command) {
      case TCPCommand.sendMessage:
        return body.toString();
      case TCPCommand.sendFile:
      case TCPCommand.unknown:
        return command.stringValue;
    }
  }
}
