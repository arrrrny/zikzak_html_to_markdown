import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// A utility class for parsing HTML content and converting it to Markdown.
class HtmlParser {
  /// Convert HTML string to Markdown format
  static String toMarkdown(String html) {
    // Parse the HTML
    final document = html_parser.parse(html);
    
    // Remove unwanted elements
    document.querySelectorAll('script, style, nav, header, footer, .navigation, .ads, .cookie-banner, #cookie-banner')
            .forEach((element) => element.remove());
    
    // Extract main content
    final mainContent = _findMainContent(document);
    
    // Process the content
    return _processNode(mainContent ?? document.body ?? document);
  }
  
  /// Find the main content element in the document
  static dom.Element? _findMainContent(dom.Document document) {
    // Common content container selectors - ordered by priority
    final contentSelectors = [
      'main',
      'article',
      '[role="main"]',
      '#content',
      '.content',
      '.main-content',
      '.post-content',
      '.entry-content',
      '.article-content',
      '.blog-post',
    ];

    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        return element;
      }
    }

    return null;
  }
  
  /// Process an HTML node to convert it to Markdown
  static String _processNode(dom.Node node) {
    if (node is dom.Text) {
      return _cleanText(node.text);
    }

    if (node is! dom.Element) return '';

    final element = node;
    final buffer = StringBuffer();
    final tag = element.localName?.toLowerCase() ?? '';

    switch (tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.parse(tag[1]);
        final prefix = '#' * level;
        buffer.writeln('$prefix ${_processInline(element)}');
        buffer.writeln();
        break;

      case 'p':
        final text = _processInline(element);
        if (text.trim().isNotEmpty) {
          buffer.writeln(text);
          buffer.writeln();
        }
        break;

      case 'br':
        buffer.writeln();
        break;

      case 'ul':
        for (final child in element.children) {
          if (child.localName == 'li') {
            buffer.writeln('* ${_processInline(child)}');
          }
        }
        buffer.writeln();
        break;

      case 'ol':
        var index = 1;
        for (final child in element.children) {
          if (child.localName == 'li') {
            buffer.writeln('$index. ${_processInline(child)}');
            index++;
          }
        }
        buffer.writeln();
        break;

      case 'pre':
        final code = element.querySelector('code');
        if (code != null) {
          final language = _detectCodeLanguage(code);
          buffer.writeln('```$language');
          buffer.writeln(code.text.trim());
          buffer.writeln('```');
          buffer.writeln();
        } else {
          buffer.writeln('```');
          buffer.writeln(element.text.trim());
          buffer.writeln('```');
          buffer.writeln();
        }
        break;

      case 'code':
        buffer.write('`${element.text.trim()}`');
        break;

      case 'blockquote':
        final lines = _processInline(element).split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            buffer.writeln('> $line');
          }
        }
        buffer.writeln();
        break;

      case 'table':
        _processTable(element, buffer);
        break;

      case 'div':
        // Handle div specially to avoid unnecessary newlines for nested divs
        final childContent = StringBuffer();
        for (final child in element.nodes) {
          childContent.write(_processNode(child));
        }
        final content = childContent.toString();
        if (content.trim().isNotEmpty) {
          buffer.write(content);
          // Only add newline if the content doesn't end with one
          if (!content.endsWith('\n\n')) {
            buffer.writeln();
          }
        }
        break;

      case 'hr':
        buffer.writeln('---');
        buffer.writeln();
        break;

      case 'img':
        final src = element.attributes['src'];
        final alt = element.attributes['alt'] ?? '';
        if (src != null && src.isNotEmpty) {
          buffer.writeln('![$alt]($src)');
          buffer.writeln();
        }
        break;

      default:
        for (final child in element.nodes) {
          buffer.write(_processNode(child));
        }
    }

    return buffer.toString();
  }

  /// Detect language for code blocks
  static String _detectCodeLanguage(dom.Element codeElement) {
    // Check for class with language hints
    final classAttr = codeElement.attributes['class'] ?? '';
    
    // Common class patterns
    final languagePatterns = [
      RegExp(r'language-(\w+)'),
      RegExp(r'lang-(\w+)'),
      RegExp(r'brush:\s*(\w+)'),
    ];
    
    for (final pattern in languagePatterns) {
      final match = pattern.firstMatch(classAttr);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? '';
      }
    }
    
    // Try to detect based on content
    final code = codeElement.text;
    if (code.contains(RegExp(r'(function|const|let|var|return)\s'))) {
      return 'javascript';
    } else if (code.contains(RegExp(r'(import|class|def|if __name__ ==)'))) {
      return 'python';
    } else if (code.contains(RegExp(r'(public static void main|class .* \{)'))) {
      return 'java';
    } else if (code.contains(RegExp(r'(<html|<body|<div|<script)'))) {
      return 'html';
    } else if (code.contains(RegExp(r'(#include|int main|void)'))) {
      return 'c';
    }
    
    return ''; // Default to no language specified
  }

  /// Clean up text content
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Process inline elements for markdown formatting
  static String _processInline(dom.Element element) {
    final buffer = StringBuffer();
    
    for (final node in element.nodes) {
      if (node is dom.Text) {
        buffer.write(_cleanText(node.text));
      } else if (node is dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        final content = _processInline(node);

        switch (tag) {
          case 'strong':
          case 'b':
            buffer.write('**$content**');
            break;
          case 'em':
          case 'i':
            buffer.write('_${content}_');
            break;
          case 'code':
            buffer.write('`$content`');
            break;
          case 'a':
            final href = node.attributes['href'];
            if (href != null && href.isNotEmpty) {
              buffer.write('[$content]($href)');
            } else {
              buffer.write(content);
            }
            break;
          case 'img':
            final src = node.attributes['src'];
            final alt = node.attributes['alt'] ?? '';
            if (src != null && src.isNotEmpty) {
              buffer.write('![$alt]($src)');
            }
            break;
          case 'br':
            buffer.write('\n');
            break;
          case 'mark':
          case 'highlight':
            buffer.write('==$content==');
            break;
          case 'del':
          case 's':
          case 'strike':
            buffer.write('~~$content~~');
            break;
          case 'sub':
            buffer.write('~$content~');
            break;
          case 'sup':
            buffer.write('^$content^');
            break;
          default:
            buffer.write(content);
        }
      }
    }
    
    return buffer.toString().trim();
  }
  
  /// Process tables
  static void _processTable(dom.Element table, StringBuffer buffer) {
    var rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return;

    final headerCells = rows.first.querySelectorAll('th');
    final columnCount = headerCells.isNotEmpty 
        ? headerCells.length 
        : rows.first.querySelectorAll('td').length;

    if (columnCount == 0) return;

    // Process header row
    buffer.write('| ');
    if (headerCells.isNotEmpty) {
      buffer.writeln(headerCells.map((cell) => _processInline(cell)).join(' | ') + ' |');
      buffer.writeln('| ${List.filled(columnCount, '---').join(' | ')} |');
    } else {
      // If no header cells, use the first row as header
      final firstRowCells = rows.first.querySelectorAll('td');
      buffer.writeln(firstRowCells.map((cell) => _processInline(cell)).join(' | ') + ' |');
      buffer.writeln('| ${List.filled(columnCount, '---').join(' | ')} |');
      
      // Skip the first row in processing data rows
      rows = rows.skip(1).toList();
    }

    // Process data rows
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isNotEmpty) {
        buffer.writeln('| ${cells.map((cell) => _processInline(cell)).join(' | ')} |');
      }
    }
    buffer.writeln();
  }
}