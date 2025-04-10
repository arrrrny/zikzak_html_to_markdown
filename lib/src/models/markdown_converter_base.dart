/// Base class for all markdown converters
abstract class MarkdownConverterBase {
  /// Initialize the converter
  Future<void> initialize();
  
  /// Check if converter is available
  Future<bool> isAvailable();
  
  /// Check if this is an advanced converter
  bool isAdvanced();
  
  /// Convert HTML to Markdown
  Future<String> convertHtmlToMarkdown(String html);
  
  /// Release resources
  void close();
}
