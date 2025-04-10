import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'markdown_converter_interface.dart';

/// Creates the appropriate markdown converter implementation
MarkdownConverterInterface createMarkdownConverter() {
  return GemmaMarkdownConverter();
}

/// Implementation that uses Gemma model for markdown conversion
class GemmaMarkdownConverter implements MarkdownConverterInterface {
  final FlutterGemmaPlugin _gemmaPlugin = FlutterGemmaPlugin.instance;
  InferenceModel? _inferenceModel;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Check platform compatibility
      if (!_isPlatformSupported()) {
        throw Exception('Platform not supported for Gemma model');
      }
      
      // Configure based on platform
      await _configurePlatformSpecifics();
      
      // Create the model instance
      _inferenceModel = await _gemmaPlugin.createModel(
        modelType: ModelType.GEMMA_2B_IT, // Use the appropriate model type
        maxTokens: 2048, // Increased token limit for better handling of longer texts
      );
      
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize on-device model: $e');
    }
  }
  
  /// Check if the current platform is supported
  bool _isPlatformSupported() {
    if (kIsWeb) {
      // Web is supported but requires GPU backend
      return true;
    }
    
    if (Platform.isIOS) {
      // Check iOS version (needs 13.0+)
      final version = Platform.operatingSystemVersion;
      return !version.contains('Version 1') || 
             version.contains('Version 13') || 
             version.contains('Version 14') || 
             version.contains('Version 15') || 
             version.contains('Version 16') || 
             version.contains('Version 17');
    }
    
    // Android should be supported
    return Platform.isAndroid;
  }
  
  /// Configure platform-specific settings
  Future<void> _configurePlatformSpecifics() async {
    try {
      final modelManager = _gemmaPlugin.modelManager;
      
      if (kIsWeb) {
        // Web setup is handled by the index.html additions
      } else if (Platform.isIOS) {
        // iOS requires specific setup but most is handled in Podfile
        // Check if the model is already available or needs to be downloaded
        if (!await modelManager.isModelPresent()) {
          // For demo purposes, you might want to include a small model in assets
          // Or provide instructions for downloading the model
          print('Model not present on iOS device - user needs to add it');
        }
      } else if (Platform.isAndroid) {
        // Android setup
        // Check if the model is already available or needs to be downloaded
        if (!await modelManager.isModelPresent()) {
          print('Model not present on Android device - user needs to add it');
        }
      }
    } catch (e) {
      print('Error during platform configuration: $e');
    }
  }

  @override
  Future<bool> isModelAvailable() async {
    if (!_isPlatformSupported()) {
      return false;
    }
    
    try {
      final modelManager = _gemmaPlugin.modelManager;
      // Try a simple operation to check if model is accessible
      try {
        // Check if model exists
        return await modelManager.isModelPresent();
      } catch (_) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> enhanceMarkdown(String markdown) async {
    if (_inferenceModel == null) {
      return markdown;
    }
    
    try {
      // Create a session for processing
      final session = await _inferenceModel!.createSession(
        temperature: 0.1, // Low temperature for more deterministic output
      );
      
      // Prepare the prompt for cleaning and enhancing markdown
      final prompt = '''
      I have a markdown document that was converted from HTML. Please clean it up and improve its formatting while preserving all the content.
      Fix any issues with headings, lists, and code blocks. Remove any redundant whitespace or formatting artifacts.
      Don't add any explanations or comments, just return the cleaned markdown.
      
      Here's the markdown to improve:
      
      $markdown
      ''';
      
      await session.addQueryChunk(Message(text: prompt));
      
      // Get the response
      final response = await session.getResponse();
      
      // Clean up
      await session.close();
      
      // If the response is empty or much shorter than the original, return the original
      if (response.isEmpty || response.length < markdown.length / 2) {
        return markdown;
      }
      
      return response;
    } catch (e) {
      // If any error occurs, return the original markdown
      return markdown;
    }
  }
  
  @override
  void close() {
    _inferenceModel?.close();
    _inferenceModel = null;
    _initialized = false;
  }
}
