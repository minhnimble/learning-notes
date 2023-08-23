# Definition

Ensure only a single instance of a class is created, and you want to provide a global point of access to it.

# Example code

A Debug Logger

```dart
import 'package:logging/logging.dart';
import 'package:intl/intl.dart' show DateFormat;

class DebugLogger {
  static DebugLogger _instance;
  static Logger _logger;
  static final _dateFormatter = DateFormat('H:m:s.S');
  static const appName = 'my_app';

  DebugLogger._internal() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_recordHandler);

    _logger = Logger(appName);
      
    _instance = this;
  };

  factory DebugLogger() => _instance ?? DebugLogger._internal();

  void _recordHandler(LogRecord rec) {
    print('${_dateFormatter.format(rec.time)}: ${rec.message}');
  }

  void log(message, [Object error, StackTrace stackTrace]) =>
      _logger.info(message, error, stackTrace);
}

// Get the logger Singleton instance
final logger = DebugLogger();
```
