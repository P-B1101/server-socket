import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'socket_handler.dart';
import 'request/tcp_request.dart';
import 'request/client_command.dart';

const _udpPort = 1101;
const _tcpPort = 1102;
const _maxClientSize = 1;
var _handlers = <String, SocketHandler>{};
late InternetAddress _myId;

void main(List<String> args) async {
  _myId = await findMyIp() ?? InternetAddress.loopbackIPv4;
  _brodcastServerIp(_myId);
  _bind(_myId);
}

Future<InternetAddress?> findMyIp() async {
  final interfaces = await NetworkInterface.list();
  if (interfaces.isEmpty) return null;
  for (var interface in interfaces) {
    if (interface.addresses.isEmpty) continue;
    for (var address in interface.addresses) {
      if (address.address.startsWith('192.168.1')) return address;
    }
  }
  return null;
}

void _brodcastServerIp(InternetAddress ip) {
  RawDatagramSocket.bind(ip, _udpPort).then((udpSocket) async {
    udpSocket.broadcastEnabled = true;
    final message = '${ip.address}:$_tcpPort';
    final data = utf8.encode(message);
    while (!_isAllClientConnected()) {
      udpSocket.send(data, InternetAddress('255.255.255.255'), _udpPort);
      print('$message sent');
      await Future.delayed(const Duration(seconds: 1));
    }
  });
}

void _bind(InternetAddress ip) async {
  final socket = await ServerSocket.bind(ip, _tcpPort);
  socket.listen((event) {
    if (_isAllClientConnected()) return;
    final id = '${event.remoteAddress.address}:${event.remotePort}';
    final handler = SocketHandler(
      id: id,
      onReceived: _handleMessage,
      onDisconnect: _handleDisconnect,
    )..listen(event);
    _handlers[id] = handler;
    _handleStartTestProcess();
  });
  print('listening on ${ip.address}:$_tcpPort');
}

bool _isAllClientConnected() => _handlers.length >= _maxClientSize;

void _handleStartTestProcess() {
  if (_isAllClientConnected()) {
    Future.delayed(const Duration(seconds: 2)).then((_) async {
      await _sendToAllMessage(ClientCommand.startRecording.stringValue);
    });
  }
}

void _handleMessage(TCPRequest request) {
  final body = request.body;
  if (body is String) {
    _handleStringMessage(body);
    return;
  }
  if (body is Uint8List) {
    _handleFileMessage(body);
    return;
  }
}

void _handleStringMessage(String body) {
  final clientCommand = ClientCommand.fromString(body);
  switch (clientCommand) {
    case ClientCommand.startRecording:
      Future.delayed(const Duration(seconds: 5)).then((value) async {
        await _sendToAllMessage(ClientCommand.startRecording.stringValue);
      });
      break;
    case ClientCommand.stopRecording:
      Future.delayed(const Duration(seconds: 2)).then((value) async {
        await _sendToAllMessage(ClientCommand.sendVideo.stringValue);
      });
      break;
    case ClientCommand.sendVideo:
      break;
    case ClientCommand.unknown:
      throw UnimplementedError();
  }
}

void _handleFileMessage(Uint8List body) {
  if (body.isEmpty) return;
  final name = '${DateTime.now().millisecondsSinceEpoch.toString()}.mp4';
  final path = Directory.current.path;
  final file = File('$path/$name');
  if (file.existsSync()) file.deleteSync();
  file.createSync();
  file.writeAsBytesSync(body);
}

Future<void> _sendToAllMessage(Object message) async {
  for (var handler in _handlers.values) {
    if (message is File) {
      await handler.sendFile(message);
      continue;
    }
    if (message is String) {
      await handler.sendMessage(message);
      continue;
    }
    throw UnimplementedError('body must be string or file');
  }
}

void _handleDisconnect(String id) {
  _handlers.remove(id);
  _brodcastServerIp(_myId);
}
