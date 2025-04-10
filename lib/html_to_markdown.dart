import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'src/html_fetcher.dart';

class HtmlToMarkdown {
  /// Fetches HTML content from the given URL and converts it to Markdown.
  static Future<String> convertUrlToMarkdown(BuildContext context, String url) async {
    print('Starting HTML to Markdown conversion for: $url');
    
    final completer = Completer<String>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => HtmlFetcher(
        url: url,
        onComplete: (content) {
          print('HTML content length: ${content.length}');
          final markdown = html2md.convert(content);
          print('Conversion completed. Markdown length: ${markdown.length}');
          completer.complete(markdown);
        },
        onError: (error) {
          print('Error during conversion: $error');
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }
}