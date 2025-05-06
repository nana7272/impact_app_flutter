enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

class Logger {
  static final Logger _instance = Logger._internal();
  
  factory Logger() {
    return _instance;
  }
  
  Logger._internal();
  
  LogLevel logLevel = LogLevel.debug; // Set default log level
  
  void setLogLevel(LogLevel level) {
    logLevel = level;
  }
  
  void v(String tag, String message) {
    if (logLevel.index <= LogLevel.verbose.index) {
      print('VERBOSE [$tag]: $message');
    }
  }
  
  void d(String tag, String message) {
    if (logLevel.index <= LogLevel.debug.index) {
      print('DEBUG [$tag]: $message');
    }
  }
  
  void i(String tag, String message) {
    if (logLevel.index <= LogLevel.info.index) {
      print('INFO [$tag]: $message');
    }
  }
  
  void w(String tag, String message) {
    if (logLevel.index <= LogLevel.warning.index) {
      print('WARNING [$tag]: $message');
    }
  }
  
  void e(String tag, String message, {StackTrace? stackTrace}) {
    if (logLevel.index <= LogLevel.error.index) {
      print('ERROR [$tag]: $message');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
}