import 'tcp_command.dart';

class TCPRequest {
  final TCPCommand command;
  final Object? body;

  const TCPRequest({
    required this.body,
    required this.command,
  });

  factory TCPRequest.create(TCPCommand command) =>
      TCPRequest(body: null, command: command);
}
