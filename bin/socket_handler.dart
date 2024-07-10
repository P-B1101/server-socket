import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'request/tcp_request.dart';
import 'request/tcp_command.dart';

final class SocketHandler {
  final String id;
  final Future<void> Function(TCPRequest) onReceived;
  final void Function(String id) onDisconnect;
  SocketHandler({
    required this.id,
    required this.onReceived,
    required this.onDisconnect,
  });

  Socket? _socket;
  TCPCommand? _command;
  final _bytes = List<int>.empty(growable: true);
  bool _isFile = false;
  StreamSubscription? _sub;

  void listen(Socket socket) {
    _socket = socket;
    print('client ip: ${socket.remoteAddress.address}:${socket.remotePort}');
    _listenToSocket();
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
      _socket = null;
      _sub?.cancel();
      _sub = null;
    } on Exception catch (error) {
      print(error);
    }
    onDisconnect(id);
    print('Socket disconnected.');
  }

  void _listenToSocket() {
    assert(_socket != null, 'call `listen` first');
    _sub = _socket!.listen(_mapper)..onDone(() => onDisconnect(id));
  }

  Future<void> sendMessage(String message) async {
    assert(_socket != null, 'call `listen` first');
    await _socket!.addStream(_createMessageStream(message));
  }

  Future<void> sendFile(File file) async {
    assert(_socket != null, 'call `listen` first');
    await _socket!.addStream(_createFileStream(file));
  }

  Stream<Uint8List> _createMessageStream(String message) async* {
    yield utf8.encode(TCPCommand.sendMessage.stringValue);
    yield utf8.encode(message);
    yield utf8.encode(TCPCommand.eom.stringValue);
  }

  Stream<List<int>> _createFileStream(File file) async* {
    yield utf8.encode(TCPCommand.sendFile.stringValue);
    yield* file.openRead();
    yield utf8.encode(TCPCommand.eom.stringValue);
  }

  void _mapper(Uint8List bytes) {
    try {
      final data = utf8.decode(bytes);
      final temp = TCPCommand.fromString(data);
      if (temp == TCPCommand.unknown) return;
      _command = temp;
    } catch (error) {
      print(error);
    }
    switch (_command) {
      case null:
        break;
      case TCPCommand.sendMessage:
        _isFile = false;
        _bytes.addAll(bytes);
        break;
      case TCPCommand.sendFile:
        _isFile = true;
        _bytes.addAll(bytes);
        break;
      case TCPCommand.authentication:
        _isFile = false;
        break;
      case TCPCommand.eom:
        _handleEOM();
        break;
      case TCPCommand.unknown:
        throw UnimplementedError();
    }
  }

  void _handleEOM() async {
    final TCPRequest request;
    if (_isFile) {
      request = TCPRequest(body: _bytes, command: TCPCommand.sendFile);
    } else {
      request = TCPRequest(
        body: utf8.decode(_bytes),
        command: TCPCommand.sendMessage,
      );
    }
    await onReceived(request);
    _bytes.clear();
    _command = null;
  }
}
