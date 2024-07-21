import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import 'socket_handler.dart';
import 'request/tcp_request.dart';
import 'request/client_type.dart';
import 'request/client_command.dart';
import 'cow_id.dart';

const _udpPort = 1101;
const _tcpPort = 1102;
const _maxClientSize = 2;
const _maxCameraClientSize = 1;
var _handlers = <String, SocketHandler>{};
var _cowIds = <String, CowId>{};
late InternetAddress _myId;

var _time = 0;

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
  if (_isAllClientConnected()) return;
  RawDatagramSocket.bind(ip, _udpPort).then((udpSocket) async {
    udpSocket.broadcastEnabled = true;
    final message = '||${ip.address}:$_tcpPort||';
    final data = utf8.encode(message);
    while (!_isAllClientConnected()) {
      udpSocket.send(data, InternetAddress('255.255.255.255'), _udpPort);
      print('broadcast on port $_udpPort: $message');
      await Future.delayed(const Duration(seconds: 1));
    }
  });
}

void _bind(InternetAddress ip) async {
  final socket = await ServerSocket.bind(ip, _tcpPort);
  socket.listen((event) {
    final id = '${event.remoteAddress.address}:${event.remotePort}';
    final handler = SocketHandler(
      id: id,
      onReceived: _handleMessage,
      onDisconnect: _handleDisconnect,
    )..listen(event);
    _handlers[id] = handler;
    _sendMessageToInterface(
        '${ClientCommand.standby.stringValue}:${_isAllCameraClientConnected()}');
  });
  print('listening on ${ip.address}:$_tcpPort');
}

bool _isAllClientConnected() => _handlers.length >= _maxClientSize;

bool _isAllCameraClientConnected() =>
    _handlers.values.where((element) => element.isAndroidCamera).length >=
    _maxCameraClientSize;

Future<void> _handleMessage(String id, TCPRequest request) async {
  final body = request.body;
  if (body is String) {
    await _handleStringMessage(body: body, id: id, type: request.clientType);
    return;
  }
  if (body is List<int>) {
    await _handleFileMessage(body, request.fileName);
    return;
  }
}

Future<void> _handleStringMessage({
  required String id,
  required String body,
  required ClientType type,
}) async {
  final clientCommand = ClientCommand.fromString(body);
  switch (clientCommand) {
    case ClientCommand.startRecording:
      switch (type) {
        case ClientType.androidCamera:
          await _sendMessageToInterface(
            ClientCommand.startRecording.stringValue,
          );
          break;
        case ClientType.androidInterface:
          await _sendMessageToAllCamera(
              ClientCommand.startRecording.stringValue);
          _addCowId(body);
          break;
        case ClientType.unknown:
          break;
      }
      break;
    case ClientCommand.stopRecording:
      switch (type) {
        case ClientType.androidCamera:
          await _sendMessageToInterface(
            ClientCommand.stopRecording.stringValue,
          );
          Future.delayed(const Duration(seconds: 2)).then((_) {
            _sendMessageToInterface(
              '${ClientCommand.rfId.stringValue}:'
              '${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000}',
            );
          });
          break;
        case ClientType.androidInterface:
          await _sendMessageToAllCamera(
              ClientCommand.stopRecording.stringValue);
          break;
        case ClientType.unknown:
          break;
      }
      break;
    case ClientCommand.standby:
    case ClientCommand.unknown:
    case ClientCommand.rfId:
      break;
    case ClientCommand.token:
      _generateTokenAndSend(id);
      break;
    case ClientCommand.dateTime:
      _startTimer(int.parse(body.split(':')[1]) * 1000);
      break;
  }
}

void _generateTokenAndSend(String id) async {
  final token = DateTime.now().millisecondsSinceEpoch.toString();
  await _sendMessage(id, '${ClientCommand.token.stringValue}:$token');
}

Future<void> _handleFileMessage(List<int> body, String? fileName) async {
  if (body.isEmpty) return;
  if (fileName == null) {
    var mime = lookupMimeType('', headerBytes: body);
    var extension = extensionFromMime(mime ?? '');
    fileName = '${DateTime.now().millisecondsSinceEpoch.toString()}.$extension';
  }
  final path = Directory.current.path;
  final file = File('$path/$fileName');
  if (file.existsSync()) file.deleteSync();
  file.createSync();
  file.writeAsBytesSync(body);
  print('file saved.');
}

Future<void> _sendMessageToAllCamera(Object message) async {
  for (var handler in _handlers.values) {
    if (!handler.isAndroidCamera) continue;
    if (message is File) {
      await handler.sendFile(message);
      continue;
    }
    if (message is String) {
      print('DateTime: $_getDateTime');
      await handler.sendMessage(message);
      continue;
    }
    throw UnimplementedError('body must be string or file');
  }
}

Future<void> _sendMessage(String id, Object message) async {
  final handler = _handlers[id];
  if (handler == null) {
    print('Handler not found with id: $id');
    return;
  }
  if (message is File) {
    await handler.sendFile(message);
    return;
  }
  if (message is String) {
    print('DateTime: $_getDateTime');
    await handler.sendMessage(message);
    return;
  }
}

Future<void> _sendMessageToInterface(String message) async {
  for (var handler in _handlers.values) {
    if (handler.isAndroidCamera) continue;
    print('DateTime: $_getDateTime');
    await handler.sendMessage(message);
  }
}

void _handleDisconnect(String id) {
  _handlers.remove(id);
  _sendMessageToInterface(
      '${ClientCommand.standby.stringValue}:${_isAllCameraClientConnected()}');
  _brodcastServerIp(_myId);
}

void _addCowId(String message) {
  final temp = message.split(':');
  final cowId = CowId(
    id: temp[1] == 'NULL' ? null : temp[1],
    rfId: temp[2] == 'NULL' ? null : temp[2],
  );
  if (cowId.serialize == null) return;
  if (_cowIds[cowId.serialize!] == null) _cowIds[cowId.serialize!] = cowId;
}

void _startTimer(int time) {
  _time = time;
  Timer.periodic(const Duration(milliseconds: 1), (timer) => _time++);
}

DateTime? get _getDateTime =>
    _time == 0 ? null : DateTime.fromMillisecondsSinceEpoch(_time);
