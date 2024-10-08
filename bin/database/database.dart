import 'client_database_info.dart';
import 'farm_database_info.dart';
import '../client/client.dart';

abstract class Database {
  Future<void> addClient(Client client);

  Future<List<Client>> getAllClients();

  Future<void> deleteClient(String id);

  Future<void> setVisitId(String visitId);

  Future<String?> getVisigId();
}

final class DatabaseImpl implements Database {
  late MockDatabase _db;

  DatabaseImpl() {
    _db = MockDatabase()
      ..createTable(ClientInfo.client)
      ..createTable(FarmInfo.farm);
  }

  @override
  Future<void> addClient(Client client) async {
    await _db.insert(ClientInfo.client, client.toMap);
  }

  @override
  Future<void> deleteClient(String id) async {
    await _db.delete(ClientInfo.client, ClientInfo.id, id);
  }

  @override
  Future<List<Client>> getAllClients() async {
    return (await _db.select(ClientInfo.client))
        .map((value) => Client.fromMap(value))
        .toList();
  }

  @override
  Future<String?> getVisigId() async {
    final data = await _db.select(FarmInfo.farm);
    return data.lastOrNull?[FarmInfo.id];
  }

  @override
  Future<void> setVisitId(String visitId) async {
    await _db.insert(FarmInfo.farm, {FarmInfo.id: visitId});
  }
}

class MockDatabase {
  final _tables = <String, List<Map<String, dynamic>>>{};

  void createTable(String name) {
    _tables[name] = List<Map<String, dynamic>>.empty(growable: true);
  }

  Future<void> insert(String tableName, Map<String, dynamic> data) async {
    final temp = _tables[tableName];
    if (temp == null) throw Exception('Table $tableName not found');
    _tables[tableName] = [...temp, data];
  }

  Future<void> delete(String tableName, String where, String id) async {
    final temp = _tables[tableName];
    if (temp == null) throw Exception('Table $tableName not found');
    temp.removeWhere((element) => element[where] == id);
    _tables[tableName] = [...temp];
  }

  Future<List<Map<String, dynamic>>> select(String tableName) async {
    final temp = _tables[tableName];
    if (temp == null) throw Exception('Table $tableName not found');
    return temp;
  }
}
