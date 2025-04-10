import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:hive/hive.dart';
import 'html_parser.dart';
import 'dart:io';

/// A simplified converter that directly handles HTML to Markdown conversion
class OnDeviceMarkdownConverter {
  bool _initialized = false;
  static const String _boxName = 'model_settings';
  static const String _keyModelAvailable = 'model_available';
  static const String _keyModelPath = 'model_path';
  
  // In-memory fallback in case Hive fails
  static bool _inMemoryModelAvailable = false;
  
  /// Initialize the converter
  Future<void> initialize() async {
    if (!_initialized) {
      try {
        // Ensure box is open
        await _ensureBoxOpen();
        _initialized = true;
      } catch (e) {
        print('Error initializing converter: $e');
        // Recover by marking as initialized anyway
        _initialized = true;
      }
    }
  }
  
  /// Check if the model is available - uses Hive for persistence
  Future<bool> isModelAvailable() async {
    try {
      if (await _isBoxAvailable()) {
        final box = Hive.box(_boxName);
        return box.get(_keyModelAvailable, defaultValue: false);
      }
      // Fall back to in-memory state if Hive not available
      return _inMemoryModelAvailable;
    } catch (e) {
      print('Error checking model availability: $e');
      // Fall back to in-memory state if error occurs
      return _inMemoryModelAvailable;
    }
  }
  
  /// Set model availability status
  Future<void> setModelAvailability(bool available) async {
    try {
      // Update in-memory state (as backup)
      _inMemoryModelAvailable = available;
      
      if (await _isBoxAvailable()) {
        final box = Hive.box(_boxName);
        await box.put(_keyModelAvailable, available);
        
        // If model is available, also save the model path
        if (available) {
          final modelPath = await _getFakeModelPath();
          await box.put(_keyModelPath, modelPath);
        }
        
        print('Model availability set to: $available (Hive storage)');
      } else {
        print('Model availability set to: $available (in-memory only)');
      }
    } catch (e) {
      print('Error setting model availability: $e');
    }
  }
  
  /// Check if Hive box is available
  Future<bool> _isBoxAvailable() async {
    try {
      return Hive.isBoxOpen(_boxName);
    } catch (e) {
      print('Error checking box availability: $e');
      return false;
    }
  }
  
  /// Ensure Hive box is open
  Future<void> _ensureBoxOpen() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
    } catch (e) {
      print('Error ensuring box is open: $e');
      rethrow;
    }
  }

  /// Get a consistent path for demo purposes
  Future<String> _getFakeModelPath() async {
    // Fixed path that doesn't depend on platform APIs
    if (Platform.isIOS || Platform.isMacOS) {
      return '/Users/Documents/gemma_model/gemma-2b-it';
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/Android/data/com.example.app/files/gemma_model/gemma-2b-it';
    } else {
      return 'gemma_model/gemma-2b-it';
    }
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

  /// Download model from network
  Future<void> downloadModelFromNetwork(
    String url, {
    Function(double)? onProgress,
  }) async {
    // For demonstration purposes, we'll simulate a download
    // In a real implementation with flutter_gemma:
    
    if (!Platform.isIOS && !Platform.isAndroid && !Platform.isMacOS) {
      throw Exception('Model download only supported on iOS, Android, and macOS');
    }
    
    // 1. Get path for model storage (fake)
    final modelDir = await _getFakeModelPath();
    
    // 2. Create directory if needed (simulated)
    print('Creating directory: ${modelDir.substring(0, modelDir.lastIndexOf('/'))}');
    
    // 3. Download model (simulated)
    print('Downloading Gemma 2B-IT model to: $modelDir');
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress?.call(i.toDouble());
    }
    
    // 4. Set model available in Hive for persistence
    await setModelAvailability(true);
    
    print('Model download completed successfully');
  }
}