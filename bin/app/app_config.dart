import 'dart:async';
import 'dart:typed_data';

import '../client/client.dart';

abstract interface class AppConfig {
  void start();

  void brodcastServerIp();

  void listenForClientConnection();

  Future<void> saveNewClient(Client client);

  Future<void> deleteClient(String id);

  Future<void> onReceiveResponseOfAskTime(int epoch);

  Future<void> askForTime();

  Future<void> onReceiveStartCameraFromInterface(String body);

  Future<void> onReceiveStopCameraFromInterface(String id);

  Future<void> onReceiveStartCameraFromAndroidCamera(String id);

  Future<void> onReceiveStopCameraFromAndroidCamera(String id);

  Future<void> onReceiveCameraPositionFromAndroidCamera(
    String id,
    String data,
  );

  Future<void> checkForCameraStatus(bool startRecording);

  Future<void> onReceiveFileFromAndroidCamera(
    Uint8List bytes,
    String? filename,
  );

  Future<void> onReceiveGenerateTokenFromAndroidCamera(String id);
  
  Future<void> onReceiveIPAddressFromAndroidCamera(String id);

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
