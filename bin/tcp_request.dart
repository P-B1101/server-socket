import './method.dart';
import './body_type.dart';

class TCPRequest {
  final Map<String, dynamic> headers;
  final Object? body;

  const TCPRequest({
    required this.body,
    required this.headers,
  });

  Method get method => Method.fromJson(headers['method']);

  BodyType get bodyType => BodyType.fromJson(headers['bodyType']);
}
