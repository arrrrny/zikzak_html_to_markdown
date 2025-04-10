import 'dart:async';
import 'package:flutter/material.dart';
import 'src/html_fetcher.dart';
import 'src/html_parser.dart';
import 'src/on_device_markdown_converter.dart';

class HtmlToMarkdown {
  /// Fetches HTML content from the given URL and converts it to Markdown using standard conversion.
  static Future<String> convertUrlToMarkdownBasic(BuildContext context, String url) async {
    print('Starting basic HTML to Markdown conversion for: $url');
    
    final completer = Completer<String>();
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => HtmlFetcher(
        url: url,
        onComplete: (content) {
          print('HTML content length: ${content.length}');
          final markdown = HtmlParser.toMarkdown(content);
          print('Basic conversion completed. Markdown length: ${markdown.length}');
          completer.complete(markdown);
          Navigator.of(context).pop();
        },
        onError: (error) {
          print('Error during conversion: $error');
          completer.completeError(error);
          Navigator.of(context).pop();
        },
      ),
    );

    return completer.future;
  }
  
  /// Fetches HTML content and converts it to Markdown.
  static Future<String> convertUrlToMarkdown(BuildContext context, String url) async {
    return convertUrlToMarkdownBasic(context, url);
  }
  
  /// Directly converts HTML string to Markdown.
  static Future<String> convertHtmlToMarkdown(String html) async {
    print('Starting direct HTML to Markdown conversion');
    return HtmlParser.toMarkdown(html);
  }
  
  /// Simplified AI-powered conversion that doesn't require external models.
  /// Uses basic HTML-to-Markdown conversion with some extra formatting improvements.
  static Future<String> convertUrlToMarkdownWithAI(
    BuildContext context, 
    String url, {
    String? ollamaServerUrl, // Ignored parameter, kept for compatibility
    String? modelName, // Ignored parameter, kept for compatibility
  }) async {
    print('Starting enhanced HTML to Markdown conversion for: $url');
    
    final completer = Completer<String>();
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => HtmlFetcher(
        url: url,
        onComplete: (content) {
          print('HTML content length: ${content.length}');
          // Use the HTML parser with some extra cleanup
          final markdown = _enhanceMarkdown(HtmlParser.toMarkdown(content));
          print('Enhanced conversion completed. Markdown length: ${markdown.length}');
          completer.complete(markdown);
          Navigator.of(context).pop();
        },
        onError: (error) {
          print('Error during conversion: $error');
          completer.completeError(error);
          Navigator.of(context).pop();
        },
      ),
    );

    return completer.future;
  }
  
  /// Apply some basic enhancements to the markdown without requiring ML models
  static String _enhanceMarkdown(String markdown) {
    // Fix common markdown formatting issues
    return markdown
        // Fix extra blank lines (more than 2 consecutive newlines)
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Ensure proper spacing around headers
        .replaceAll(RegExp(r'([^\n])(#{1,6}\s)'), r'$1\n\n$2')
        // Clean up list formatting
        .replaceAll(RegExp(r'\n\s*[-*]\s'), '\n* ')
        // Normalize numbered lists
        .replaceAll(RegExp(r'\n\s*(\d+)[.)] '), r'\n$1. ')
        // Clean up any HTML entities that weren't properly converted
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll("&apos;", "'")
        .trim();
  }
  
  /// Always returns false as we're not using ML models
  static Future<bool> isOnDeviceModelAvailable() async {
    return false;
  }
}