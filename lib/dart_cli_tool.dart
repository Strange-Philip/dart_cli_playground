import 'package:mason_logger/mason_logger.dart';
import 'dart:io';

int calculate() {
  return 6 * 7;
}

void masonTestFunc() async {
  final progress = logger.progress('Calculating');
  await Future<void>.delayed(const Duration(seconds: 1));

  // Provide an update.
  progress.update('Almost done');
  await Future<void>.delayed(const Duration(seconds: 1));
  progress.complete('Done!');
  progress.fail("Failed!");
  progress.cancel();
  progress.update('Updated');
  progress.update('Updated');
}

void buildRunner() {
  final progress = logger.progress('Running build_runner...');
  progress.update('Running build_runner...');
  Process.run('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs'])
      .then((ProcessResult result) {
    // progress.update(result.stdout);
    if (result.exitCode == 0) {
      progress.complete('✅Done');
    } else {
      progress.fail('❌Error updating generated files...');
    }
  });
}

void createFlutterProject(String projectName) {
  final progress = logger.progress('Creating $projectName flutter project ...');
  progress.update('Creating $projectName flutter project ...');
  Process.run('flutter', ['create', projectName]).then((ProcessResult results) {
    if (results.exitCode == 0) {
      progress.update(results.stdout);
      progress.complete('✅Flutter project "$projectName" created successfully.');
    } else {
      progress.fail('❌Error creating Flutter project. Please check the Flutter installation.');
    }
  });
}

final logger = Logger(
  level: Level.info,
  theme: LogTheme(),
);

mixin AssetClass {
  final pubspecFileContent = File('pubspec.yaml').readAsStringSync();

  String? get name {
    return RegExp(r'name: (.*)').firstMatch(pubspecFileContent)?.group(1);
  }

  /// Get name of the application from pubspec.yaml
  /// - [name] - Name of the application.
  String get defaultClassName {
    if (name == null) {
      throw Exception('name section not found in pubspec.yaml');
    }

    return '${name!.substring(0, 1).toUpperCase() + name!.substring(1)}Assets';
  }

  /// - [defaultPaths] - Default Directory for assets from pubspec.yaml
  /// - [path] - Default Path to the asset directory.
  List<String> get defaultPaths {
    final lines = pubspecFileContent.split('\n');
    final assetsIndex = lines.indexWhere((line) => line.trim() == 'assets:');
    if (assetsIndex == -1) {
      throw Exception('assets section not found in pubspec.yaml');
    }

    final paths = <String>[];
    for (var i = assetsIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('-')) {
        paths.add(line.substring(1).trim());
      } else if (line.isNotEmpty) {
        break;
      }
    }

    return paths;
  }

  /// - [defaultFileName] - Default Name of the generated asset class.
  ///   default: 'projectName_assets'
  String get defaultFileName => '${name}_assets.dart';

  /// - [defaultOutput] - Default Path to the generated asset class file.
  ///  default: 'lib/'
  String get defaultOutput {
    final String path = 'lib/';
    if (!(Directory(path).existsSync())) {
      throw Exception('lib directory not found');
    }

    return path;
  }
}

class ArgPasser {
  final List<String> args;

  ArgPasser(this.args);

  // parse function
  Map<String, dynamic> parse() {
    // check for invalid arguments and unknown flags
    invalidArgument();

    return {
      'prefix': prefix,
      'output': output,
      'className': className,
    };
  }

  bool get hasVersion => args.contains('-v') || args.contains('--version');

  bool get hasHelp => args.contains('-h') || args.contains('--help');

  bool get hasPrefix => args.contains('-p') || args.contains('--prefix');

  String? get prefix {
    final index = args.indexWhere((arg) => arg == '-p' || arg == '--prefix');
    if (index == -1) {
      return null;
    }

    return args[index + 1];
  }

  String? get output {
    final index = args.indexWhere((arg) => arg == '-o' || arg == '--output');
    if (index == -1) {
      return null;
    }

    final path = args[index + 1];

    if (FileSystemEntity.isDirectorySync(path)) {
      return path;
    } else {
      throw Exception('''The output path is not a directory.
          Run `AssetCli --help` for more information.
          ''');
    }
  }

  String? get className {
    final index = args.indexWhere((arg) => arg == '-c' || arg == '--class');
    if (index == -1) {
      return null;
    }

    return args[index + 1];
  }

  String version = '0.0.1';

  String usage = '''
    -h, --help       Show this help message.
    -v, --version    Show the version of this application.
    -p, --prefix     Prefix to add to the asset class members.
    -o, --output     Path to the generated asset class file.
    -c, --class      Name of the generated asset class.
  ''';

  void invalidArgument() {
    Map<String, String> flags = {};
    for (var i = 0; i < args.length; i += 2) {
      if (args[i].startsWith('-')) {
        if (['-v', '--version', '-h', '--help', '-p', '--prefix', '-o', '--output', '-c', '--class']
            .contains(args[i])) {
          if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
            flags[args[i]] = args[i + 1];
          } else {
            throw Exception('''Expected a value after ${args[i]}
                Run `AssetCli --help` for more information.
                ''');
          }
        } else {
          throw Exception('''Unknown flag ${args[i]}
              Run `AssetCli --help` for more information.
              ''');
        }
      } else {
        throw Exception('''Invalid argument ${args[i]}
            Run `AssetCli --help` for more information.
            ''');
      }
    }
  }
}
