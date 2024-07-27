import 'package:sqflite/sqflite.dart' as sql;
import 'client_database_info.dart';
import '../client/client.dart';

abstract class Database {
  Future<void> addClient(Client client);

  Future<List<Client>> getAllClients();

  Future<void> deleteClient(String id);
}

final class DatabaseImpl implements Database {
  late sql.Database _db;

  DatabaseImpl() {
    sql.openDatabase(
      'clients.db',
      version: 1,
      onCreate: (db, version) {
        db.execute('CREATE TABLE ${ClientInfo.client} '
            '(${ClientInfo.id} TEXT primary key, '
            '${ClientInfo.clientType} TEXT)');
      },
    ).then((db) {
      _db = db;
    });
  }

  @override
  Future<void> addClient(Client client) async {
    await _db.insert(ClientInfo.client, client.toMap);
  }

  @override
  Future<void> deleteClient(String id) async {
    await _db.delete(
      ClientInfo.client,
      where: '${ClientInfo.id} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Client>> getAllClients() async {
    return (await _db.query(ClientInfo.client))
        .map((value) => Client.fromMap(value))
        .toList();
  }
}
