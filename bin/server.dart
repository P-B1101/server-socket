import 'dart:convert';
import 'dart:io';

const _udpPort = 1101;
const _tcpPort = 1102;
final _clients = List.empty(growable: true);

bool _isBrodcastReceived = false;

void main(List<String> args) async {
  final ip = await findMyIp() ?? InternetAddress.loopbackIPv4;
  _brodcastServerIp(ip);
  _startListen(ip);
}

Future<InternetAddress?> findMyIp() async {
  final interfaces = await NetworkInterface.list();
  if (interfaces.isEmpty) return null;
  for (var interface in interfaces) {
    if (interface.addresses.isEmpty) continue;
    for (var address in interface.addresses) {
      if (address.address.startsWith('192.168.1')) return address;
    }
  }
  return null;
}

void _brodcastServerIp(InternetAddress ip) {
  RawDatagramSocket.bind(ip, _udpPort).then((udpSocket) async {
    udpSocket.broadcastEnabled = true;
    final message = '${ip.address}:$_tcpPort';
    final data = utf8.encode(message);
    while (!_isBrodcastReceived) {
      udpSocket.send(data, InternetAddress('255.255.255.255'), _udpPort);
      print('$message sent');
      await Future.delayed(const Duration(seconds: 1));
    }
  });
}

void _startListen(InternetAddress ip) async {
  final socket = await ServerSocket.bind(ip, _tcpPort);
  socket.listen(_listen);
  print('listening on $ip:$_tcpPort');
}

void _listen(Socket socket) {
  print('client ip: ${socket.remoteAddress.address}:${socket.remotePort}');
  _clients.add('${socket.remoteAddress.address}:${socket.remotePort}');
  socket.listen((event) {
    final message = utf8.decode(event);
    final jsonMessage = json.decode(message);
    _handleMessage(jsonMessage, socket);
  });
}

void _handleMessage(Map<String, dynamic> data, Socket socket) {
  final headers = data['headers'];
  final body = data['body'];
  switch (headers['method']) {
    case 'AUTHENTICATION':
      _handleAuthentication(body, socket);
      break;
    case 'ACK':
      _handleAck(body, socket);
      break;
  }
}

void _handleAuthentication(dynamic body, Socket socket) async {
  _isBrodcastReceived = true;
  await Future.delayed(const Duration(seconds: 5));
  final headers = {
    'method': 'COMMAND',
  };
  final body = {
    'commandType': 'START_RECORD',
  };
  final message = json.encode({
    'headers': headers,
    'body': body,
  });
  _sendMessage(socket, message);
  print('send start record command');
}

void _handleAck(dynamic body, Socket socket) async {
  final commandType = body['commandType'];
  if (commandType == 'START_RECORD') {
    await Future.delayed(const Duration(seconds: 5));
    final headers = {
      'method': 'COMMAND',
    };
    final body = {
      'commandType': 'STOP_RECORD',
    };
    final message = json.encode({
      'headers': headers,
      'body': body,
    });
    _sendMessage(socket, message);
    print('send stop record command');
  }
}

void _sendMessage(Socket socket, String message) {
  final data = utf8.encode(message);
  socket.add(data);
}
