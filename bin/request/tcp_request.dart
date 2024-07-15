import 'tcp_command.dart';
import 'client_type.dart';

class TCPRequest {
  final TCPCommand command;
  final ClientType clientType;
  final Object? body;

  const TCPRequest({
    required this.body,
    required this.command,
    required this.clientType,
  });

  factory TCPRequest.create(TCPCommand command) =>
      TCPRequest(body: null, command: command, clientType: ClientType.unknown);

  TCPRequest updateClientType(ClientType clientType) => TCPRequest(
        body: body,
        command: command,
        clientType: clientType,
      );

  bool get isAuthentication => command == TCPCommand.authentication;
}
