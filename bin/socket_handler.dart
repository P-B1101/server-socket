import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'request/tcp_request.dart';
import 'request/tcp_command.dart';
import 'request/client_type.dart';

const tokenIdentifier = 'TOKEN:';

final class SocketHandler {
  final String id;
  final Future<void> Function(String, TCPRequest) onReceived;
  final void Function(String id) onDisconnect;
  SocketHandler({
    required this.id,
    required this.onReceived,
    required this.onDisconnect,
  });

  Socket? _socket;
  // TCPCommand? _command;
  final _bytes = List<int>.empty(growable: true);
  bool _isFile = false;
  int _fileLength = 0;
  StreamSubscription? _sub;
  ClientType _clientType = ClientType.unknown;
  String? _fileName;
  static const _dividerString = '||';
  // static final _divider = utf8.encode(_dividerString);

  void listen(Socket socket) {
    _socket = socket;
    print('client ip: ${socket.remoteAddress.address}:${socket.remotePort}');
    _listenToSocket();
  }

  bool get isAndroidCamera => _clientType == ClientType.androidCamera;

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
    _socket!.add(utf8.encode('$_dividerString$message$_dividerString'));
    print('message $message sent');
  }

  Future<void> sendFile(File file) async {
    assert(_socket != null, 'call `listen` first');
    final size = await file.length();
    if (size == 0) return;
    final fileName = file.path.fileName;
    await sendMessage('${TCPCommand.sendFile}:$size:$fileName');
    await Future.delayed(const Duration(seconds: 1));
    await _socket!.addStream(file.openRead());
  }

  void _mapper(Uint8List bytes) {
    print('New packet received');
    if (_handleBytes(bytes)) return;
    final command = _compileIncommingMessage(bytes);
    if (command == null) return;
    if (_handleSendFileCommand(command)) return;
    if (_handleClientTypeCommand(command)) return;
    if (_handleStringCommand(command)) return;
  }

  bool _handleBytes(List<int> bytes) {
    if (!_isFile) return false;
    _bytes.addAll(bytes);
    if (_bytes.length >= _fileLength) {
      final request = TCPRequest.file(_bytes.toList(), _fileName, _clientType);
      _bytes.clear();
      _fileLength = 0;
      _isFile = false;
      _fileName = null;
      onReceived(id, request);
    }
    return true;
  }

  String? _compileIncommingMessage(List<int> bytes) {
    try {
      final data = utf8.decode(bytes);
      if (!data.startsWith(_dividerString) || !data.endsWith(_dividerString)) {
        print('Not A Command');
        return null;
      }
      final result = data.substring(2, data.length - 2);
      print('String Data received: $result');
      return result;
    } catch (error) {
      print(error);
      return null;
    }
  }

  bool _handleSendFileCommand(String message) {
    if (!message.startsWith(TCPCommand.sendFile.stringValue)) return false;
    final temp = message.split(':');
    if (temp.length < 2) {
      print('Send File command config is not right. Invalid Messagin protocol');
      return false;
    }
    final length = int.tryParse(temp[1]);
    if (length == null) {
      print('Send File command config is not right. Invalid file length');
      return false;
    }
    _fileLength = length;
    _isFile = true;
    if (temp.length >= 3) _fileName = temp[2];
    return true;
  }

  bool _handleStringCommand(String message) {
    final request = TCPRequest.command(message, _clientType);
    onReceived(id, request);
    return true;
  }

  bool _handleClientTypeCommand(String message) {
    if (_clientType != ClientType.unknown) return false;
    _clientType = ClientType.fromString(message);
    if (_clientType == ClientType.unknown) {
      print('client must introduce itself first');
      return true;
    }
    final request = TCPRequest.clientType(_clientType);
    onReceived(id, request);
    return true;
  }

  // void _mapper(Uint8List bytes) async {
  //   print('new packet received');
  //   final isString = await _handleStringMessage(bytes);
  //   if (!isString) _bytes.addAll(bytes);
  // }

  // Future<bool> _handleStringMessage(Uint8List bytes) async {
  //   try {
  //     final data = utf8.decode(bytes);
  //     print('Data received: $data');
  //     if (_clientType == ClientType.unknown) {
  //       _clientType = ClientType.fromString(data.substring(2, data.length - 2));
  //       if (_clientType == ClientType.unknown) {
  //         print('client must introduce itself first');
  //         return true;
  //       }
  //       final request = TCPRequest(
  //         body: null,
  //         command: TCPCommand.introduction,
  //         clientType: _clientType,
  //       );
  //       await onReceived(id, request);
  //       return true;
  //     }
  //     if (data.contains(tokenIdentifier)) {
  //       final body = data.substring(2, data.length - 2);
  //       final request = TCPRequest(
  //         body: body.replaceAll(tokenIdentifier, ''),
  //         command: TCPCommand.authentication,
  //         clientType: _clientType,
  //       );
  //       await onReceived(id, request);
  //       return true;
  //     }
  //     if (!data.startsWith(_dividerString) || !data.endsWith(_dividerString)) {
  //       throw Exception('Not A Command');
  //     }
  //     final body = data.substring(2, data.length - 2);
  //     final TCPRequest request;
  //     if (body == TCPCommand.eom.stringValue) {
  //       request = TCPRequest(
  //         body: _bytes.toList(),
  //         command: TCPCommand.sendFile,
  //         clientType: _clientType,
  //       );
  //       _handleEOM();
  //     } else {
  //       request = TCPRequest(
  //         body: body,
  //         command: TCPCommand.sendMessage,
  //         clientType: _clientType,
  //       );
  //     }
  //     await onReceived(id, request);
  //     return true;
  //   } catch (error) {
  //     // print(error);
  //     return false;
  //   }
  // }

  // void _handleEOM() async {
  //   // final TCPRequest request;
  //   // if (_isFile) {
  //   //   request = TCPRequest(body: _bytes, command: TCPCommand.sendFile);
  //   // } else {
  //   //   request = TCPRequest(
  //   //     body: utf8.decode(_bytes),
  //   //     command: TCPCommand.sendMessage,
  //   //   );
  //   // }
  //   // await onReceived(request);
  //   _bytes.clear();
  //   // _command = null;
  // }
}

extension StringExt on String {
  String get fileName => substring(lastIndexOf(Platform.pathSeparator));

  String get fileExtension => substring(lastIndexOf('.'));
}
