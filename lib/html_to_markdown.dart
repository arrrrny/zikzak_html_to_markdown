import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'src/html_fetcher.dart';
import 'src/html_parser.dart';
import 'src/on_device_markdown_converter.dart';

/// Initialize the package - should be called in main() before runApp()
Future<void> initializeHtmlToMarkdown() async {
  try {
    // Initialize Hive without path_provider dependency
    await _initializeHiveWithoutPathProvider();
    print('Hive initialized successfully');
    
    // Open the box
    if (!Hive.isBoxOpen('model_settings')) {
      await Hive.openBox('model_settings');
      print('Hive box opened successfully');
    }
    
    // Pre-initialize the converter
    final converter = OnDeviceMarkdownConverter();
    await converter.initialize();
    
    // Check model status at startup
    final isModelAvailable = await converter.isModelAvailable();
    print('AI Model availability: $isModelAvailable');
    
    converter.close();
    print('HTML to Markdown initialized successfully');
  } catch (e) {
    print('Error initializing HTML to Markdown package: $e');
  }
}

/// Initialize Hive without using path_provider
Future<void> _initializeHiveWithoutPathProvider() async {
  try {
    // Get a usable temp directory that doesn't require special permissions
    final tempDir = Directory.systemTemp;
    Hive.init(tempDir.path);
  } catch (e) {
    print('Error initializing Hive: $e');
    rethrow;
  }
}

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
    String? modelName, // Model ID parameter
  }) async {
    print('Starting enhanced HTML to Markdown conversion for: $url');
    
    final completer = Completer<String>();
    final startTime = DateTime.now();
    
    // Check model availability first for logging
    final converter = OnDeviceMarkdownConverter();
    await converter.initialize();
    final modelAvailable = await converter.isModelAvailable(modelId: modelName);
    
    print('🔍 AI conversion request:');
    print('🔍 URL: $url');
    print('🔍 Model available: $modelAvailable');
    print('🔍 Model: ${modelName ?? "default"}');
    print('🔍 Start time: $startTime');
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => HtmlFetcher(
        url: url,
        onComplete: (content) async {
          print('🔍 HTML content fetched: ${content.length} characters');
          try {
            // First convert HTML to basic markdown
            final basicMarkdown = HtmlParser.toMarkdown(content);
            print('🔍 Basic markdown generated: ${basicMarkdown.length} characters');
            
            // Then enhance with AI if model is available
            final aiEnhanced = await converter.enhanceMarkdownWithAI(
              basicMarkdown,
              modelId: modelName,
            );
            
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime);
            
            print('🔍 AI conversion completed');
            print('🔍 Processing time: ${duration.inMilliseconds}ms');
            print('🔍 Output length: ${aiEnhanced.length} characters');
            
            completer.complete(aiEnhanced);
            Navigator.of(context).pop();
          } catch (e) {
            print('🔍 Error during AI enhancement: $e');
            // Fallback to basic enhancement
            final markdown = _enhanceMarkdown(HtmlParser.toMarkdown(content));
            completer.complete(markdown);
            Navigator.of(context).pop();
          } finally {
            converter.close();
          }
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
  
  /// Check if an on-device AI model is available for enhanced markdown conversion
  static Future<bool> isOnDeviceModelAvailable({String? modelId}) async {
    final converter = OnDeviceMarkdownConverter();
    await converter.initialize();
    try {
      final isAvailable = await converter.isModelAvailable(modelId: modelId);
      return isAvailable;
    } finally {
      converter.close();
    }
  }
  
  /// Register model as available 
  static Future<void> registerModelAsAvailable(bool available, {String? modelId}) async {
    final converter = OnDeviceMarkdownConverter();
    await converter.initialize();
    try {
      await converter.setModelAvailability(available, modelId: modelId);
    } finally {
      converter.close();
    }
  }
  
  /// Download and install an AI model for enhanced markdown conversion
  static Future<void> downloadModel({
    required String modelUrl, 
    String? modelName,
    Function(double)? onProgress,
  }) async {
    final converter = OnDeviceMarkdownConverter();
    await converter.initialize();
    
    try {
      // First check if the model is already downloaded
      final isAvailable = await converter.isModelAvailable(modelId: modelName);
      if (isAvailable) {
        return; // Model already downloaded
      }
      
      // Download the model
      await converter.downloadModelFromNetwork(
        modelUrl, 
        modelId: modelName,
        onProgress: onProgress,
      );
      
      // After successful download, mark model as available
      await converter.setModelAvailability(true, modelId: modelName);
    } finally {
      converter.close();
    }
  }
}