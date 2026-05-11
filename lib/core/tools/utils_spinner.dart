// tools/utils_spinner.dart
import 'dart:async';
import 'dart:io';

class Spinner {
  final String message;
  final List<String> frames;
  Timer? _timer;
  int _index = 0;

  Spinner(this.message, {this.frames = const ['|', '/', '-', '\\']});

  void start() {
    try {
      if (!stdout.hasTerminal) {
        // non-interactive environment (IDE) — fallback to simple print
        stdout.writeln('$message...');
        return;
      }
    } catch (_) {
      stdout.writeln('$message...');
      return;
    }

    stdout.write('$message ');
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      stdout.write('\r$message ${frames[_index]}');
      _index = (_index + 1) % frames.length;
    });
  }

  void stop([String doneMessage = '✅ Done!']) {
    _stop('');
    _stop( doneMessage);
  }
  _stop(String doneMessage){
    if (_timer != null) {
      _timer?.cancel();
      stdout.write('\r$doneMessage\n');
    } else {
      stdout.writeln('\r$doneMessage\n');
    }
  }
}
