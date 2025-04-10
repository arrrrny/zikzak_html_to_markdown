import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'html_parser.dart';

/// A simplified converter that directly handles HTML to Markdown conversion
class OnDeviceMarkdownConverter {
  bool _initialized = false;
  
  /// Initialize the converter - simplified to always succeed
  Future<void> initialize() async {
    _initialized = true;
  }
  
  /// Always returns false to indicate no ML model is available
  Future<bool> isModelAvailable() async {
    return false;
  }

  /// Convert HTML to Markdown using standard processing
  Future<String> convertHtmlToMarkdown(String html) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Use our HTML parser to convert HTML to Markdown
    return HtmlParser.toMarkdown(html);
  }
  
  /// Release resources - no-op in this simplified version
  void close() {
    _initialized = false;
  }
}