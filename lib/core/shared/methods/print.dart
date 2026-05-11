
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as logger_pkg;



enum LoggerType { warning, info, error, fatal }

// extension LoggerTypeExt on LoggerType {
//
//
//   String get getIcon {
//     switch (this) {
//       case LoggerType.warning:
//         return '⚠️';
//       case LoggerType.info:
//         return '💡';
//       case LoggerType.error:
//         return '💥';
//       case LoggerType.fatal:
//         return '🛑';
//     }
//   }
// }



  class PrintHelper {
    PrintHelper._();
    static final PrintHelper _instance = PrintHelper._().._init();
    factory PrintHelper() => _instance;

    logger_pkg.Logger? logger;

    void _init() {
      if (logger != null) return;
      logger = logger_pkg.Logger(
        printer: logger_pkg.PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          printTime: false,
        ),
      );
    }



    void ordinaryPrint(Object? object){
    if(kDebugMode){
      print(object);
    }

  }


    void loggerPrint(dynamic message, LoggerType type, [String? tag, int framesToSkip=3]) {
    if (kDebugMode  ) {
      final String caller = _getCallerFunction(framesToSkip);
      final String timestamp = DateTime.now().toString().split(' ').last;
      final String tagLabel = tag != null ? '[$tag] ' : '';
      final String msg = '[$timestamp] $tagLabel$caller\n   └─ $message';

      switch (type) {
        case LoggerType.warning:
           logger?.w(msg);
          break;
        case LoggerType.info:
         logger?.i(msg);
          break;
        case LoggerType.error:
   logger?.e(msg);
          break;
        case LoggerType.fatal:
 logger?.f(msg);
          break;
      }
    }
  }
}



String _getCallerFunction(int framesToSkip) {
  try {
    final stackLines = StackTrace.current.toString().split('\n');
    for (int i = framesToSkip; i < stackLines.length; i++) {
      final line = stackLines[i];
      if (line.contains('/lib/') && line.contains('.dart')) {
        final pathMatch = RegExp(r'((?:package:[^ ]+)|(?:\/[^ ]+\.dart))').firstMatch(line);
        final methodMatch = RegExp(r' ([A-Za-z0-9_<>]+)\(').firstMatch(line);

        final filePath = pathMatch != null
            ? pathMatch.group(1)!
                .replaceAll('package:', '')
                .replaceAll(RegExp(r'^[^/]+/'), 'lib/')
            : 'unknown_file.dart';

        final methodName = methodMatch?.group(1) ?? 'unknown_method';
        return '$filePath → $methodName()';
      }
    }
    return 'Unknown caller';
  } catch (e) {
    return 'Unknown caller';
  }
}

