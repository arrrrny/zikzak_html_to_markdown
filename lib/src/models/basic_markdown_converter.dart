import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'markdown_converter_base.dart';
import '../html_utils.dart';

/// Basic markdown converter that uses standard HTML parsing
class BasicMarkdownConverter implements MarkdownConverterBase {
  bool _initialized = false;
  
  @override
  Future<void> initialize() async {
    _initialized = true;
  }
  
  @override
  Future<bool> isAvailable() async {
    return true; // Basic converter is always available
  }
  
  @override
  bool isAdvanced() {
    return false; // This is not an advanced converter
  }

  @override
  Future<String> convertHtmlToMarkdown(String html) async {
    // Parse the HTML
    final document = html_parser.parse(html);
    
    // Remove unwanted elements
    document.querySelectorAll('script, style, nav, header, footer, .navigation, .ads, .cookie-banner, #cookie-banner')
            .forEach((element) => element.remove());
    
    // Extract main content
    final mainContent = HtmlUtils.findMainContent(document);
    
    // Process the content
    return HtmlUtils.convertToMarkdown(mainContent ?? document.body ?? document);
  }
  
  @override
  void close() {
    _initialized = false;
  }
}
