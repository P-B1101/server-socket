import 'client_type.dart';
import '../database/client_database_info.dart';

class Client {
  final ClientType type;
  final String id;

  const Client({
    required this.id,
    required this.type,
  });

  factory Client.fromMap(Map<String, dynamic> data) => Client(
        id: data[ClientInfo.id],
        type: ClientType.fromString(data[ClientInfo.clientType]),
      );

  Map<String, dynamic> get toMap => {
        ClientInfo.id: id,
        ClientInfo.clientType: type.stringValue,
      };
}
