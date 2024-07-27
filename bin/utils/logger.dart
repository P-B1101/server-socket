import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class Logger {
  Logger._();
  static final Logger _instance = Logger._();

  static Logger get instance => _instance;

  final _controller = BehaviorSubject<String>();
  final StringBuffer _buffer = StringBuffer();

  void log(Object message) {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final finalData = '${dateFormat.format(DateTime.now())} ~> $message';
    _buffer.writeln(finalData);
    _controller.add(_buffer.toString());
  }

  Stream<String> get observer => _controller.stream;
}
