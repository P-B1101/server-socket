import 'client/client_type.dart';
import 'database/database.dart';
import 'app/app.dart';
import 'utils/utils.dart';

void main(List<String> args) async {
  final App app = TestSCenarioImpl(
    myIP: await Utils.findMyIp(),
    database: DatabaseImpl(),
    expectedClients: {
      ClientType.androidCamera: 1,
      ClientType.androidInterface: 0,
      ClientType.raspberrypi3DCamera: 0,
    },
    tcpPort: 1102,
    udpPort: 1101,
  );
  app.start();
}
