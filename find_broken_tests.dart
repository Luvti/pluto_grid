import 'dart:convert';
import 'dart:io';

void main() async {
  print('Running tests to find failures...');

  // ignore: close_sinks
  final process = await Process.start('flutter', ['test', '-r', 'json']);

  final testNames = <int, String>{};
  final testUrls = <int, String>{};
  bool hasFailures = false;

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      if (!line.startsWith('{')) return;
      try {
        final event = jsonDecode(line) as Map<String, dynamic>;
        final type = event['type'];

        if (type == 'testStart') {
          final test = event['test'];
          final id = test['id'];
          final name = test['name'];
          final url = test['url']; // Sometimes populated for loading events

          if (id != null && name != null) {
            testNames[id] = name;
          }
          if (id != null && url != null) {
            testUrls[id] = url;
          }
        } else if (type == 'testDone') {
          final result = event['result'];
          final hidden = event['hidden'] ?? false;
          final testID = event['testID'];

          if (result != 'success' && !hidden) {
            final name = testNames[testID];
            if (name != null) {
              hasFailures = true;
              if (name.startsWith('loading ')) {
                // For loading errors, it's usually better to run the file
                // The name is usually "loading path/to/file.dart"
                final path = name.substring('loading '.length);
                print('flutter test $path');
              } else {
                // Escape double quotes in the name for the command
                final escapedName = name.replaceAll('"', r'\"');
                print('flutter test --plain-name "$escapedName"');
              }
            }
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    },
  );

  final exitCode = await process.exitCode;
  if (!hasFailures && exitCode == 0) {
    print('All tests passed!');
  } else if (!hasFailures && exitCode != 0) {
    print(
      'Test process exited with code $exitCode but no individual test failures were detected.',
    );
  }
}
