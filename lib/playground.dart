import 'package:mason_logger/mason_logger.dart';
import 'dart_cli_tool.dart';

final favoriteAnimal = logger.prompt(
  'What is your favorite animal?',
  defaultValue: '🐈',
);

/// Ask user to choose an option.
final favoriteColor = logger.chooseOne(
  'What is your favorite color?',
  choices: ['red', 'green', 'blue'],
  defaultValue: 'blue',
);

/// Ask user to choose zero or more options.
final desserts = logger.chooseAny(
  'Which desserts do you like?',
  choices: ['🍦', '🍪', '🍩'],
);

// Ask for user confirmation.
final likesCats = logger.confirm('Do you like cats?', defaultValue: true);

// Prompt for any number of answers.
final programmingLanguages = logger.promptAny(
  'What are your favorite programming languages?',
);

final repoLink = link(
  message: 'GitHub Repository',
  uri: Uri.parse('https://github.com/felangel/mason'),
);