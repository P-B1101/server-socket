import 'dart:async';
import 'dart:typed_data';

import '../client/client.dart';
import '../tcp/command/command_type.dart';

abstract interface class AppConfig {
  void start();

  void brodcastServerIp();

  void listenForClientConnection();

  Future<void> saveNewClient(Client client);

  Future<void> deleteClient(String id);

  Future<void> onReceiveResponseOfAskTime(int epoch);

  Future<void> askForTime();

  Future<void> checkAndSendConfigToAndroidCamera();

  Future<void> onReceiveStartCameraFromInterface(String body);

  Future<void> onReceiveStopCameraFromInterface(String id);

  Future<void> onReceiveCancelCameraFromInterface(String id);

  Future<void> onReceiveStartCameraFromAndroidCamera(String id);

  Future<void> onReceiveStopCameraFromAndroidCamera(String id);

  Future<void> onReceiveCancelCameraFromAndroidCamera(String id);

  Future<void> onReceiveCameraPositionFromAndroidCamera(
    String id,
    String data,
  );

  Future<void> checkForCameraStatus(CommandType recordingType);

  Future<void> onReceiveFileFromAndroidCamera(
    Uint8List bytes,
    String? filename,
  );

  Future<void> onReceiveGeneratedTokenFromAndroidCamera(
    String id,
    String token,
  );

  Future<void> onReceiveIPAddressFromAndroidCamera(String id);

  Future<void> onReceiveVisitIdFromInterface(String id, String data);

  Future<void> onReceiveVersionInfo(String id, String data);

  Future<void> checkForInterfaceStandby();

  Future<void> addCow({
    required String? id,
    required String? rfid,
  });

  Future<void> sendRFIDToInterface(String rfid);

  void handleDisconnect(String id);

  Future<bool> get isAllClientConnected;

  Future<bool> get isAllCameraClientConnected;
}
