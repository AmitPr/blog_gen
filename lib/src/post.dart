import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart';

import 'config.dart';

class Post {
  String content = '';
  String path = '';
  Map<String, dynamic> attributes = <String, dynamic>{};
  String get formattedContent {
    return markdownToHtml(content, extensionSet: CONFIG.markdownExtensions);
  }

  Post(String sourceContent, String path) {
    this.path = path;
    var splitPos = sourceContent.indexOf(RegExp(r'\n---\n'));
    //Get Attributes and Content
    var header = sourceContent.substring(0, splitPos);
    content = sourceContent.substring(splitPos + 4).trim();

    attributes['content'] = content;
    attributes['formattedContent'] = formattedContent;

    // Convert attributes to a map
    header.split('\n').forEach((element) {
      var splitPos = element.indexOf(':');
      if (splitPos < 0) return;
      var key = element.substring(0, splitPos).trim();
      var value = element.substring(splitPos + 1).trim();
      attributes[key] = value;
    });
    attributes['url'] = '/' + path;
    // Format certain attributes
    attributes['createdAt'] = DateFormat.yMMMMd().format(
        DateTime.tryParse(attributes['createdAt'] ?? '') ?? DateTime.now());
  }
}
