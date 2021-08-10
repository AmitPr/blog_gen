import 'dart:convert';

import 'package:highlight/highlight.dart' as highlight;
import 'package:markdown/markdown.dart';

String escapeHtml(String html) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(html);

String escapeHtmlAttribute(String text) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(text);

/// Parses Fenced Code Blocks, and runs Syntax Highlighting on them.
class FencedHighlightedCodeBlockSyntax extends FencedCodeBlockSyntax {
  const FencedHighlightedCodeBlockSyntax();

  @override
  Node parse(BlockParser parser) {
    // Get the syntax identifier, if there is one.
    var match = pattern.firstMatch(parser.current)!;
    var endBlock = match.group(1);
    var infoString = match.group(2)!;

    var childLines = parseChildLines(parser, endBlock);

    // The Markdown tests expect a trailing newline.
    childLines.add('');

    var text = childLines.join('\n');
    if (parser.document.encodeHtml) {
      text = escapeHtml(text);
    }
    var code = Element.text('code', text);

    // the info-string should be trimmed
    // http://spec.commonmark.org/0.22/#example-100
    infoString = infoString.trim();
    if (infoString.isNotEmpty) {
      // only use the first word in the syntax
      // http://spec.commonmark.org/0.22/#example-100
      var firstSpace = infoString.indexOf(' ');
      if (firstSpace >= 0) {
        infoString = infoString.substring(0, firstSpace);
      }
      text = highlight.highlight.parse(text, language: infoString).toHtml();
      if (parser.document.encodeHtml) {
        infoString = escapeHtmlAttribute(infoString);
      }
      code = Element.text('code', text);
      code.attributes['class'] = 'hljs language-$infoString';
    }
    code.attributes['class'] = (code.attributes['class'] ?? '') + ' code-block';
    var element = Element('pre', [code]);

    return element;
  }
}
