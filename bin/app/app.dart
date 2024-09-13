import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mime/mime.dart';

import '../client/client_type.dart';
import '../client/camera_position.dart';
import '../client/client.dart';
import '../tcp/model/tcp_data.dart';
import '../utils/logger.dart';
import '../tcp/command/command_type.dart';
import '../cow/cow_id.dart';

import '../database/database.dart';
import '../tcp/handler/socket_handler.dart';
import 'app_config.dart';

abstract class App implements AppConfig {
  final InternetAddress myIP;
  final _handlers = <String, SocketHandler>{};
  final int tcpPort;
  final int udpPort;
  final Map<ClientType, int> expectedClients;
  bool _isBrodcasting = false;

  App({
    required this.myIP,
    required this.tcpPort,
    required this.expectedClients,
    required this.udpPort,
  });

  @override
  void start() async {
    brodcastServerIp();
    listenForClientConnection();
  }

  @override
  void brodcastServerIp() async {
    if (_isBrodcasting) return;
    if (await isAllClientConnected) return;
    RawDatagramSocket.bind(myIP, 0).then((udpSocket) async {
      udpSocket.broadcastEnabled = true;
      final message = '||${myIP.address}:$tcpPort||';
      final data = utf8.encode(message);
      while (!(await isAllClientConnected)) {
        _isBrodcasting = true;
        udpSocket.send(data, InternetAddress('255.255.255.255'), udpPort);
        Logger.instance.log('Broadcasting: $message');
        await Future.delayed(const Duration(seconds: 1));
      }
      _isBrodcasting = false;
    });
  }

  @override
  void listenForClientConnection() async {
    final socket = await ServerSocket.bind(myIP, tcpPort);
    socket.listen((event) {
      final id = '${event.remoteAddress.address}:${event.remotePort}';
      final handler = SocketHandler(
        id: id,
        onReceived: _handleMessage,
        onDisconnect: handleDisconnect,
      )..listen(event);
      _handlers[id] = handler;
    });
    Logger.instance.log('Listening on ${myIP.address}:$tcpPort');
  }

  Future<void> _handleMessage(
    String id,
    TCPData request,
    bool clientTypeMessage,
  ) async {
    if (clientTypeMessage) {
      await saveNewClient(Client(id: id, type: request.clientType));
      await checkForInterfaceStandby();
      await checkAndSendConfigToAndroidCamera();
      if (request.clientType == ClientType.androidInterface) {
        Future.delayed(const Duration(seconds: 2)).then((_) {
          askForTime();
        });
      }
    }
    final body = request.body;
    if (body is String) {
      await handleStringMessage(body: body, id: id, type: request.clientType);
      return;
    }
    if (body is Uint8List) {
      await onReceiveFileFromAndroidCamera(body, request.fileName);
      return;
    }
  }

  Future<void> handleStringMessage({
    required String id,
    required String body,
    required ClientType type,
  }) async {
    final clientCommand = CommandType.fromString(body);
    switch (clientCommand) {
      case CommandType.startRecording:
        switch (type) {
          case ClientType.androidCamera:
            await onReceiveStartCameraFromAndroidCamera(id);
            break;
          case ClientType.androidInterface:
            await onReceiveStartCameraFromInterface(body);
            await _addCowId(body);
            break;
          case ClientType.unknown:
            break;
          case ClientType.raspberrypi3DCamera:
            break;
        }
        break;
      case CommandType.stopRecording:
        switch (type) {
          case ClientType.androidCamera:
            await onReceiveStopCameraFromAndroidCamera(id);
            break;
          case ClientType.androidInterface:
            await onReceiveStopCameraFromInterface(id);
            break;
          case ClientType.unknown:
            break;
          case ClientType.raspberrypi3DCamera:
            break;
        }
        break;
      case CommandType.standby:
      case CommandType.unknown:
      case CommandType.rfId:
      case CommandType.config:
        break;
      case CommandType.token:
        await onReceiveGeneratedTokenFromAndroidCamera(id, body.split(':')[1]);
        break;
      case CommandType.dateTime:
        await onReceiveResponseOfAskTime(int.parse(body.split(':')[1]) * 1000);
        break;
      case CommandType.sendLocation:
        await onReceiveCameraPositionFromAndroidCamera(id, body);
        break;
      case CommandType.ipAddress:
        await onReceiveIPAddressFromAndroidCamera(id);
        break;
      case CommandType.visitId:
        await onReceiveVisitIdFromInterface(id, body);
        break;
      case CommandType.version:
        await onReceiveVersionInfo(id, body);
        break;
    }
  }

  Future<void> _addCowId(String message) async {
    final temp = message.split(':');
    await addCow(
      id: temp[1] == 'NULL' ? null : temp[1],
      rfid: temp[2] == 'NULL' ? null : temp[2],
    );
  }

  @override
  void handleDisconnect(String id) async {
    _handlers.remove(id);
    await deleteClient(id);
    await checkForInterfaceStandby();
    brodcastServerIp();
  }
}

class TestSCenarioImpl extends App {
  final Database database;
  final _cowIds = <CowId>[];
  var _time = 0;
  Timer? _timer;
  final _cameraStatus = <String, bool>{};

  TestSCenarioImpl({
    required super.tcpPort,
    required super.udpPort,
    required super.expectedClients,
    required super.myIP,
    required this.database,
  });

  @override
  Future<void> addCow({
    required String? id,
    required String? rfid,
  }) async {
    final cowId = CowId(id: id, rfId: rfid);
    if (cowId.serialize == null) return;
    _cowIds.add(cowId);
  }

  @override
  Future<void> onReceiveFileFromAndroidCamera(
    Uint8List bytes,
    String? filename,
  ) async {
    if (bytes.isEmpty) {
      Logger.instance.log('file is empty.');
      return;
    }
    if (filename == null) {
      var mime = lookupMimeType('', headerBytes: bytes);
      var extension = extensionFromMime(mime ?? '');
      filename =
          '${DateTime.now().toLocal().millisecondsSinceEpoch.toString()}.$extension';
    }
    final path = Directory.current.path;
    final file = File('$path/$filename');
    Logger.instance.log('File name $filename.');
    if (file.existsSync()) file.deleteSync();
    file.createSync();
    file.writeAsBytesSync(bytes);
    Logger.instance.log('file saved.');
  }

  @override
  Future<void> askForTime() async {
    for (var handler in _handlers.values) {
      if (handler.isAndroidCamera) continue;
      await _sendMessageToHandler(handler, CommandType.dateTime.stringValue);
    }
  }

  @override
  Future<void> checkForInterfaceStandby() async {
    final status = await isAllCameraClientConnected;
    Future.delayed(const Duration(seconds: 1)).then((value) {
      _sendMessageToInterface('${CommandType.standby.stringValue}:$status');
    });
  }

  @override
  Future<void> onReceiveGeneratedTokenFromAndroidCamera(
    String id,
    String token,
  ) async {
    /// Handle token in the way you want.
    Logger.instance.log('Received token from $id: $token');
  }

  @override
  Future<void> onReceiveResponseOfAskTime(int epoch) async {
    _time = epoch;
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(milliseconds: 1), (timer) => _time++);
  }

  @override
  Future<void> onReceiveStartCameraFromAndroidCamera(String id) async {
    _cameraStatus[id] = true;
    await checkForCameraStatus(true);
  }

  @override
  Future<void> onReceiveStartCameraFromInterface(String body) async {
    final time = _getDateTime;
    var fileName = '';
    if (time != null) {
      String formattedDate = DateFormat('yyyyMMddHHmmss').format(time);
      fileName = formattedDate;
    } else {
      fileName = 'NULL';
    }
    final visitId = await database.getVisigId();
    fileName = '${fileName}__${visitId ?? 'NULL'}';
    final temp = body.split(':');
    final cow = CowId(
      id: temp[1] == 'NULL' ? null : temp[1],
      rfId: temp[2] == 'NULL' ? null : temp[2],
    );
    final cowInfo = cow.fileNameFormatted;
    fileName = '${fileName}__$cowInfo';
    await _sendMessageToAllCamera('$body:$fileName');
  }

  @override
  Future<void> onReceiveStopCameraFromAndroidCamera(String id) async {
    _cameraStatus[id] = false;
    await checkForCameraStatus(false);
    Future.delayed(const Duration(seconds: 2)).then((_) {
      sendRFIDToInterface(
        '${DateTime.now().toLocal().millisecondsSinceEpoch ~/ 1000}',
      );
    });
  }

  @override
  Future<void> onReceiveStopCameraFromInterface(String id) async {
    await _sendMessageToAllCamera(CommandType.stopRecording.stringValue);
  }

  @override
  Future<void> sendRFIDToInterface(String rfid) async {
    await _sendMessageToInterface('${CommandType.rfId.stringValue}:$rfid');
  }

  @override
  Future<bool> get isAllClientConnected async {
    final data = await database.getAllClients();
    if (data.isEmpty) return false;
    final temp = <ClientType, int>{};
    for (var i = 0; i < data.length; i++) {
      final count = temp[data[i].type];
      temp[data[i].type] = count == null ? 1 : count + 1;
    }
    final notZeroClients = Map<ClientType, int>.from(expectedClients);
    notZeroClients.removeWhere((key, value) => value <= 0);
    for (var key in notZeroClients.keys) {
      if (notZeroClients[key] != temp[key]) return false;
    }
    return true;
  }

  @override
  Future<bool> get isAllCameraClientConnected async {
    final data = await database.getAllClients();
    if (data.isEmpty) return false;
    final temp = <ClientType, int>{};
    for (var i = 0; i < data.length; i++) {
      final count = temp[data[i].type];
      temp[data[i].type] = count == null ? 1 : count + 1;
    }
    return expectedClients[ClientType.androidCamera] ==
        temp[ClientType.androidCamera];
  }

  @override
  Future<void> saveNewClient(Client client) async {
    await database.addClient(client);
    Logger.instance.log('Client added successfuly');
  }

  @override
  Future<void> deleteClient(String id) async {
    await database.deleteClient(id);
    Logger.instance.log('Client deleted successfuly');
  }

  Future<void> _sendMessageToAllCamera(String message) async {
    for (var handler in _handlers.values) {
      if (!handler.isAndroidCamera) continue;
      Logger.instance.log('DateTime: $_getDateTime');
      await handler.sendMessage(message);
    }
  }

  DateTime? get _getDateTime =>
      _time == 0 ? null : DateTime.fromMillisecondsSinceEpoch(_time);

  Future<void> _sendMessageToInterface(String message) async {
    for (var handler in _handlers.values) {
      if (handler.isAndroidCamera) continue;
      await _sendMessageToHandler(handler, message);
    }
  }

  Future<void> _sendMessageToHandler(
      SocketHandler handler, String message) async {
    Logger.instance.log('$_getDateTime');
    await handler.sendMessage(message);
  }

  @override
  Future<void> checkForCameraStatus(bool startRecording) async {
    final clients = await database.getAllClients();
    final androidCameraClients = clients
        .where((element) => element.type == ClientType.androidCamera)
        .toList();
    for (var i = 0; i < androidCameraClients.length; i++) {
      if (_cameraStatus[androidCameraClients[i].id] != startRecording) return;
    }
    final command =
        startRecording ? CommandType.startRecording : CommandType.stopRecording;
    await _sendMessageToInterface(command.stringValue);
  }

  @override
  Future<void> onReceiveCameraPositionFromAndroidCamera(
    String id,
    String data,
  ) async {
    final temp = data.split(':');
    if (temp.length != 2) return;
    final location = CameraLocation.fromString(temp[1]);

    /// do something with it :)
    Logger.instance
        .log('Camera position for client $id is ${location.stringValue}');
  }

  @override
  Future<void> onReceiveIPAddressFromAndroidCamera(String id) async {
    final handler = _handlers[id];
    if (handler == null) {
      Logger.instance.log('Handler not found with id: $id');
      return;
    }
    await _sendMessageToHandler(
      handler,
      '${CommandType.ipAddress.stringValue}:${handler.ipAddress ?? 'NULL'}',
    );
  }

  @override
  Future<void> onReceiveVisitIdFromInterface(String id, String data) async {
    final temp = data.split(':');
    if (temp.length != 2) return;
    await database.setVisitId(temp[1]);
  }

  @override
  Future<void> checkAndSendConfigToAndroidCamera() async {
    final status = await isAllCameraClientConnected;
    if (!status) return;
    Future.delayed(const Duration(seconds: 1)).then((value) {
      final config = <String, String>{
        'fps': '30',
        'videoBitrate': '3000000',
      };
      _sendMessageToAllCamera(
          '${CommandType.config.stringValue}:${config.values.length}:${config.entries.map(
                (e) => '${e.key}:${e.value}',
              ).join(':')}');
    });
  }

  @override
  Future<void> onReceiveVersionInfo(String id, String data) async {
    final temp = data.split(':');
    final name = temp[1];
    final version = temp[2];
    Logger.instance.log('name: $name, version: $version');
  }
}





// class AppImpl implements App {
//   final int port;
//   final List<ClientType> expectedClients;

//   const AppImpl({
//     required this.port,
//     required this.expectedClients,
//   });
// }