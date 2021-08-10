import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:jinja/jinja.dart';
import 'package:markdown/markdown.dart';

import 'extensions/md_syntax_highlighter.dart';

class CONFIG {
  static ExtensionSet markdownExtensions = ExtensionSet(
    <BlockSyntax>[
      const FencedHighlightedCodeBlockSyntax(),
      const HeaderWithIdSyntax(),
      const SetextHeaderWithIdSyntax(),
      const TableSyntax(),
    ],
    <InlineSyntax>[
      InlineHtmlSyntax(),
      StrikethroughSyntax(),
      EmojiSyntax(),
      AutolinkExtensionSyntax()
    ],
  );

  late Map<String, dynamic> config;
  String get contentDirectory => config['contentDirectory'] ?? 'content';
  String get outputDirectory => config['outputDirectory'] ?? 'static';
  String get templateDirectory => config['templateDirectory'] ?? 'templates';
  List<dynamic> get ignoredFiles => config['ignoredFiles'] ?? [];
  late Environment jinjaEnv;

  CONFIG._load(this.config) {
    createJinjaEnvironment();
  }

  void createJinjaEnvironment() {
    jinjaEnv = Environment(
      loader: FileSystemLoader(
        path: path.relative(templateDirectory),
        extensions: {'html', 'jinja'},
      ),
      leftStripBlocks: true,
      trimBlocks: true,
    );
  }

  static Future<CONFIG> load({String configFilePath = 'config.json'}) async {
    final configFile = File('config.json');
    final jsonString = await configFile.readAsString();
    Map<String, dynamic> config = jsonDecode(jsonString);
    if (config.containsKey('author')) {
      var response = await http.get(
        Uri.parse(
          "https://api.github.com/users/${config['author']}",
        ),
      );
      var author = jsonDecode(response.body);
      config['author'] = author;
    }
    return CONFIG._load(config);
  }
}
