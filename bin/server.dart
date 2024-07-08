import 'dart:convert';
import 'dart:io';

import './tcp_request.dart';
import './command.dart';
import 'body_type.dart';
import 'method.dart';

const _udpPort = 1101;
const _tcpPort = 1102;
const _headers = 'headers';
const _body = 'body';
const _maxClientSize = 1;
var _sockets = List<Socket>.empty(growable: true);

void main(List<String> args) async {
  final ip = await findMyIp() ?? InternetAddress.loopbackIPv4;
  _brodcastServerIp(ip);
  _startListen(ip);
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

void _startListen(InternetAddress ip) async {
  final socket = await ServerSocket.bind(ip, _tcpPort);
  socket.listen((event) => _listen(event, ip));
  print('listening on $ip:$_tcpPort');
}

bool _isAllClientConnected() => _sockets.length >= _maxClientSize;

void _listen(Socket socket, InternetAddress ip) {
  if (ip.address != socket.remoteAddress.address) {
    _sockets.add(socket);
    socket.listen((event) {
      final message = utf8.decode(event);
      print('Message recieved: $message');
      final jsonValue = json.decode(message);
      print('Json Message recieved: $jsonValue');
      final body = jsonValue[_body];
      final headers = jsonValue[_headers];
      print('body type is ${body.runtimeType}');
      final request = TCPRequest(
        body: body is Map<String, dynamic>
            ? body
            : body is List
                ? body.map((e) => e as int).toList()
                : null,
        headers: headers,
      );
      _handleMessage(request);
    });
    if (_isAllClientConnected()) {
      Future.delayed(const Duration(seconds: 2)).then((_) {
        final message = {
          'headers': {
            'method': Method.command.stringValue,
            'bodyType': BodyType.json.stringValue,
          },
          'body': {
            'commandType': Command.startRecording.stringValue,
          },
        };
        _sendToAllMessage(json.encode(message));
      });
    }
  }
  // if (_sockets.any((e) =>
  //     '${e.address.address}:${e.port}' ==
  //     '${socket.address.address}:${socket.port}')) {

  //     }
  print('client ip: ${socket.remoteAddress.address}:${socket.remotePort}');
}

void _handleMessage(TCPRequest request) {
  final method = request.method;
  final bodyType = request.bodyType;
  switch (method) {
    case Method.command:
      switch (bodyType) {
        case BodyType.file:
          break;
        case BodyType.json:
          final command = Command.fromJson(
              (request.body as Map<String, dynamic>)['commandType']);
          _handleCommand(command);
          break;
        case BodyType.unknown:
          break;
      }
      break;
    case Method.sendFile:
      final file =
          File('${Directory.current.path}/${request.headers['fileName']}');
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      file.writeAsBytesSync(request.body as List<int>);
      print(file.path);
      break;
    case Method.authentication:
      break;
    case Method.unknown:
      break;
  }
}

void _handleCommand(Command command) {
  switch (command) {
    case Command.startRecording:
      Future.delayed(const Duration(seconds: 5)).then((value) {
        final message = {
          'headers': {
            'method': Method.command.stringValue,
            'bodyType': BodyType.json.stringValue,
          },
          'body': {
            'commandType': Command.stopRecording.stringValue,
          },
        };
        _sendToAllMessage(json.encode(message));
      });
      break;
    case Command.stopRecording:
      break;
    case Command.sendVideo:
      break;
    case Command.unknown:
      break;
  }
}

// void _handleAuthentication(dynamic body, Socket socket) async {
//   _isBrodcastReceived = true;
//   await Future.delayed(const Duration(seconds: 5));
//   final headers = {
//     'method': 'COMMAND',
//   };
//   final body = {
//     'commandType': 'START_RECORD',
//   };
//   final message = json.encode({
//     'headers': headers,
//     'body': body,
//   });
//   _sendMessage(socket, message);
//   print('send start record command');
// }

// void _handleAck(dynamic body, Socket socket) async {
//   final commandType = body['commandType'];
//   if (commandType == 'START_RECORD') {
//     await Future.delayed(const Duration(seconds: 5));
//     final headers = {
//       'method': 'COMMAND',
//     };
//     final body = {
//       'commandType': 'STOP_RECORD',
//     };
//     final message = json.encode({
//       'headers': headers,
//       'body': body,
//     });
//     _sendMessage(socket, message);
//     print('send stop record command');
//   }
// }

// void _sendMessage(Socket socket, String message) {
//   final data = utf8.encode(message);
//   socket.add(data);
// }

void _sendToAllMessage(String message) {
  final data = utf8.encode(message);
  for (var socket in _sockets) {
    socket.add(data);
  }
}
