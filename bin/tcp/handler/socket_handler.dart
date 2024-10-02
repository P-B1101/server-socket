import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../model/tcp_data.dart';
import '../../utils/logger.dart';
import '../../utils/constants.dart';
import '../../client/client_type.dart';

final class SocketHandler {
  final String id;
  final Future<void> Function(String, TCPData, bool) onReceived;
  final void Function(String id) onDisconnect;
  SocketHandler({
    required this.id,
    required this.onReceived,
    required this.onDisconnect,
  });

  Socket? _socket;
  final _bytes = List<int>.empty(growable: true);
  final _messages = List<int>.empty(growable: true);
  bool _isFile = false;
  int _fileLength = 0;
  StreamSubscription? _sub;
  ClientType _clientType = ClientType.unknown;
  String? _fileName;

  void listen(Socket socket) {
    _socket = socket;
    print('client ip: ${socket.remoteAddress.address}:${socket.remotePort}');
    _listenToSocket();
  }

  bool get isAndroidCamera => _clientType == ClientType.androidCamera;

  String? get ipAddress => _socket?.remoteAddress.address;

  Future<void> disconnect() async {
    try {
      await _socket?.close();
      _socket = null;
      _sub?.cancel();
      _sub = null;
    } on Exception catch (error) {
      Logger.instance.log(error);
    }
    onDisconnect(id);
    Logger.instance.log('Socket disconnected.');
  }

  void _listenToSocket() {
    assert(_socket != null, 'call `listen` first');
    _sub = _socket!.listen(_mapper)..onDone(() => onDisconnect(id));
  }

  Future<void> sendMessage(String message) async {
    assert(_socket != null, 'call `listen` first');
    _socket!.add(utf8.encode('$message${Constants.kEndOfMessage}'));
    Logger.instance.log('message $message sent');
  }

  Future<void> sendFile(File file) async {
    assert(_socket != null, 'call `listen` first');
    final size = await file.length();
    if (size == 0) return;
    final fileName = file.path.fileName;
    await sendMessage('SEND_FILE:$size:$fileName');
    await Future.delayed(const Duration(seconds: 1));
    await _socket!.addStream(file.openRead());
  }

  void _mapper(Uint8List bytes) {
    Logger.instance.log('New packet received');
    if (_handleBytes(bytes)) return;
    final commands = _compileIncommingMessage(bytes);
    if (commands == null) return;
    for (var command in commands) {
      if (_handleSendFileCommand(command)) continue;
      if (_handleClientTypeCommand(command)) continue;
      if (_handleStringCommand(command)) continue;
    }
  }

  bool _handleBytes(List<int> bytes) {
    if (!_isFile) return false;
    _bytes.addAll(bytes);
    if (_bytes.length >= _fileLength) {
      final request = TCPData.file(Uint8List.fromList(_bytes.toList()), _fileName, _clientType);
      _bytes.clear();
      _fileLength = 0;
      _isFile = false;
      _fileName = null;
      Logger.instance.log('File fully received.');
      onReceived(id, request, false);
    }
    return true;
  }

  List<String>? _compileIncommingMessage(List<int> bytes) {
    try {
      _messages.addAll(bytes);
      var data = utf8.decode(_messages.toList());
      if (!data.endsWith(Constants.kEndOfMessage)) return null;
      data = data.replaceRange(data.length - Constants.kEndOfMessage.length, data.length, '');
      final temp = data.split(Constants.kEndOfMessage);
      if (temp.isEmpty) return null;
      final commands = List<String>.empty(growable: true);
      for (var command in temp) {
        commands.add(command);
      }
      _messages.clear();
      Logger.instance.log('Command received: $data');
      return commands;
    } catch (error) {
      Logger.instance.log(error);
      return null;
    }
  }

  bool _handleSendFileCommand(String message) {
    if (!message.startsWith('SEND_FILE')) return false;
    final temp = message.split(':');
    if (temp.length < 2) {
      Logger.instance.log('Send File command config is not right. Invalid Messagin protocol');
      return false;
    }
    final length = int.tryParse(temp[1]);
    if (length == null) {
      Logger.instance.log('Send File command config is not right. Invalid file length');
      return false;
    }
    _fileLength = length;
    _isFile = true;
    if (temp.length >= 3) _fileName = temp[2];
    return true;
  }

  bool _handleStringCommand(String message) {
    final request = TCPData.command(message, _clientType);
    onReceived(id, request, false);
    return true;
  }

  bool _handleClientTypeCommand(String message) {
    if (_clientType != ClientType.unknown) return false;
    _clientType = ClientType.fromString(message);
    if (_clientType == ClientType.unknown) {
      Logger.instance.log('client must introduce itself first');
      return true;
    }
    final request = TCPData.clientType(_clientType);
    onReceived(id, request, true);
    return true;
  }
}

extension StringExt on String {
  String get fileName => substring(lastIndexOf(Platform.pathSeparator));

  String get fileExtension => substring(lastIndexOf('.'));
}
