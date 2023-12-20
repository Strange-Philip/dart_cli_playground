import 'package:dart_cli_tool/dart_cli_tool.dart';
import 'dart:io';

import 'package:dart_cli_tool/playground.dart';
import 'package:watcher/watcher.dart';

void main(List<String> arguments) {
  // print('🐎🐎🐎 Hello world!');
  exitCode = 0; // presume success
  // Generator(arguments);
//   print('''# ------------------------------
// # 🚀 Release new version
// # ------------------------------''');
  // masonTestFunc();
  if (arguments.isEmpty) {
    logger.err('Please provide a project name.');
    final projName = logger.prompt(
      'What is the name of your project?',
      defaultValue: 'new_project',
    );
    return createFlutterProject(projName);
  }

  String projectName = arguments.first;

  createFlutterProject(projectName);
  // Watch for file changes in the 'lib' directory
  final watcher = DirectoryWatcher('lib');
  // Handle file changes
  watcher.events.listen((event) {
    if (event.type == ChangeType.MODIFY ||
        event.type == ChangeType.ADD ||
        event.type == ChangeType.REMOVE) {
      logger.prompt('File changed: ${event.path}');
      buildRunner();
    }
  });
}

class Generator with AssetClass {
  /// The command-line arguments.
  final List<String> _args;
  late final Map<String, dynamic> _results;

  /// Create an instance of [Generator] with the given command-line arguments.
  /// - [args] - The command-line arguments.
  Generator(this._args) {
    final ArgPasser arguments = ArgPasser(_args);

    if (arguments.hasVersion) {
      stdout.writeln('AssetCli version: ${arguments.version}');
      exit(1);
    }

    if (arguments.hasHelp) {
      logger.info('A command-line tool to generate an asset class.\n');
      logger.info('Usage: dart AssetCli [options]\n');
      logger.info('Global options:');
      logger.info('${arguments.usage}\n');
      exit(1);
    }

    _results = arguments.parse();

    init();
  }

  /// Initialize the generator.
  /// - [results] - The command-line arguments.
  init() {
    final className = _results['className'] ?? defaultClassName;

    final filePath = _results['output'] ?? defaultOutput;

    if (FileSystemEntity.isDirectorySync(filePath)) {
      final progress = logger.progress('Generating $defaultFileName in $filePath...');
      progress.complete('✅Done');
    } else {
      logger.info('To learn more, visit the $repoLink.');
      logger.err('The output path is not a directory.');
      logger.info('Run `AssetCli --help` for more information.');
      exit(1);
    }

    final File classFile = File('$filePath/$defaultFileName');

    final IOSink sink = classFile.openWrite();

    for (var i = 0; i < 3; i++) {
      sink.writeln("///* GENERATED CODE - DO NOT MODIFY BY HAND *///");
    }

    sink.writeln('');
    sink.writeln('class $className {');
    sink.writeln('  $className._();\n');

    for (var path in defaultPaths) {
      sink.writeln('/// $path');

      if (FileSystemEntity.isDirectorySync(path)) {
        _writeAssetsFromDirectory(Directory(path), sink, _results['prefix'], classFile);
      } else {
        _writeAssetFromFile(File(path), sink, _results['prefix']);
      }
      sink.writeln('');
    }

    sink.writeln('}');
    sink.close();

    // format the generated file
    Process.run('dart', ['format', classFile.path]).then((result) {
      if (result.exitCode == 0) {
        logger.success('Generated $className in $filePath');
      } else {
        logger.err('Could not format ${classFile.path}');
      }
    });
  }

  final List<String> _writtenAssets = [];

  _writeAssetsFromDirectory(Directory directory, IOSink sink, String? prefix, File classFile) {
    final List<FileSystemEntity> entities = directory.listSync().skipWhile((entity) {
      return FileSystemEntity.isDirectorySync(entity.path) || entity.path == classFile.path;
    }).toList();

    if (entities.isEmpty) {
      logger.err('No assets found in ${directory.path}.....');
      return;
    }

    logger.info(
        'Found ${entities.length} file${entities.length > 1 ? 's' : ''} in ${directory.path}');

    for (var entity in entities) {
      stdout.writeln('');

      _writeAssetFromFile(entity, sink, prefix);
    }
  }

  _writeAssetFromFile(FileSystemEntity entity, IOSink sink, String? prefix) {
    if (entity.path.endsWith('.dart')) {
      logger.info('Skipping ${entity.path}.....');
      return;
    }

    final String name = entity.path.split('/').last;
    final String key = (prefix ?? '') + name.split('.').first;
    final String value = entity.path;

    final generatedAsset = '  static const String $key = \'$value\';';

    if (_writtenAssets.contains(generatedAsset)) {
      stdout.writeln('Asset $name already exists.');
      return;
    }

    sink.writeln(generatedAsset);
    _writtenAssets.add(generatedAsset);
  }

  factory Generator.fromArgs(List<String> args) {
    return Generator(args);
  }
}
