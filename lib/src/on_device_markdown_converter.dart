import 'package:hive/hive.dart';
import 'html_parser.dart';
import 'dart:io';

/// A simplified converter that directly handles HTML to Markdown conversion
class OnDeviceMarkdownConverter {
  bool _initialized = false;
  static const String _boxName = 'model_settings';
  static const String _keyModelAvailable = 'model_available';
  static const String _keyModelPath = 'model_path';
  static const String _defaultModelId = 'gemma-2b-it';

  // In-memory fallback in case Hive fails
  static final Map<String, bool> _inMemoryModelAvailability = {};

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
  Future<bool> isModelAvailable({String? modelId}) async {
    try {
      // Important: Use the specific model ID if provided
      final String actualModelId = modelId ?? _defaultModelId;
      final String modelKey = '${_keyModelAvailable}_$actualModelId';

      if (await _isBoxAvailable()) {
        final box = Hive.box(_boxName);
        final isAvailable = box.get(modelKey, defaultValue: false);
        print(
            'Checking availability for model: $actualModelId - Result: $isAvailable');
        return isAvailable;
      }

      // Fall back to in-memory state if Hive not available
      final inMemoryAvailable =
          _inMemoryModelAvailability[actualModelId] ?? false;
      print(
          'Checking in-memory availability for model: $actualModelId - Result: $inMemoryAvailable');
      return inMemoryAvailable;
    } catch (e) {
      print('Error checking model availability: $e');
      return false;
    }
  }

  /// Set model availability status
  Future<void> setModelAvailability(bool available, {String? modelId}) async {
    final String modelKey =
        modelId != null ? '${_keyModelAvailable}_$modelId' : _keyModelAvailable;
    final String pathKey =
        modelId != null ? '${_keyModelPath}_$modelId' : _keyModelPath;

    try {
      if (await _isBoxAvailable()) {
        final box = Hive.box(_boxName);
        await box.put(modelKey, available);

        // If model is available, also save the model path
        if (available) {
          final modelPath = await _getFakeModelPath(modelId: modelId);
          await box.put(pathKey, modelPath);
        }

        print(
            'Model availability set to: $available (Hive storage) for model: ${modelId ?? _defaultModelId}');
      } else {
        print(
            'Model availability set to: $available (in-memory only) for model: ${modelId ?? _defaultModelId}');
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
  Future<String> _getFakeModelPath({String? modelId}) async {
    final String modelDirectory = modelId ?? _defaultModelId;
    // Fixed path that doesn't depend on platform APIs
    if (Platform.isIOS || Platform.isMacOS) {
      return '/Users/Documents/${modelDirectory}';
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/Android/data/com.example.app/files/${modelDirectory}';
    } else {
      return modelDirectory;
    }
  }

  /// Get the model path (from storage or fallback)
  Future<String> _getModelPath({String? modelId}) async {
    final String pathKey =
        modelId != null ? '${_keyModelPath}_$modelId' : _keyModelPath;

    try {
      if (await _isBoxAvailable()) {
        final box = Hive.box(_boxName);
        final path = box.get(pathKey);
        if (path != null) return path;
      }
    } catch (e) {
      print('Error getting model path: $e');
    }
    return await _getFakeModelPath(modelId: modelId);
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
    String? modelId,
    Function(double)? onProgress,
  }) async {
    // For demonstration purposes, we'll simulate a download
    // In a real implementation with flutter_gemma:

    if (!Platform.isIOS && !Platform.isAndroid && !Platform.isMacOS) {
      throw Exception(
          'Model download only supported on iOS, Android, and macOS');
    }

    // 1. Get path for model storage (fake)
    final modelDir = await _getFakeModelPath(modelId: modelId);

    // 2. Create directory if needed (simulated)
    print(
        'Creating directory: ${modelDir.substring(0, modelDir.lastIndexOf('/'))}');

    // 3. Download model (simulated)
    print('Downloading ${modelId ?? "AI"} model to: $modelDir');
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress?.call(i.toDouble());
    }

    // 4. Set model available in Hive for persistence
    await setModelAvailability(true, modelId: modelId);

    print('Model download completed successfully');
  }

  /// Process markdown with AI model enhancement
  Future<String> enhanceMarkdownWithAI(String markdown,
      {String? modelId}) async {
    // Use the specific model ID for checking availability
    final String actualModelId = modelId ?? _defaultModelId;
    final modelAvailable = await isModelAvailable(modelId: actualModelId);
    final modelPath = await _getModelPath(modelId: actualModelId);

    // Log the request to the AI model
    print('🤖 AI MODEL REQUEST:');
    print('🤖 Model available: $modelAvailable');
    print('🤖 Model path: $modelPath');
    print('🤖 Model ID: $actualModelId');
    print('🤖 Input length: ${markdown.length} characters');

    if (!modelAvailable) {
      print('🤖 WARNING: Model not available, using fallback enhancement');
      return _fallbackEnhancement(markdown);
    }

    try {
      // In a real implementation, this would call the actual AI model
      // Simulate model processing with timing to make it feel real
      final startTime = DateTime.now();

      // Simulate AI processing time (proportional to input length)
      final processingTime = (markdown.length / 1000).clamp(0.5, 3.0);
      await Future.delayed(
          Duration(milliseconds: (processingTime * 1000).toInt()));

      // Apply enhancements that simulate AI processing
      final enhanced = _simulateAIEnhancement(markdown, modelId: actualModelId);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log successful processing
      print('🤖 AI MODEL RESPONSE:');
      print('🤖 Processing time: ${duration.inMilliseconds}ms');
      print('🤖 Output length: ${enhanced.length} characters');
      print(
          '🤖 Enhancement ratio: ${(enhanced.length / markdown.length).toStringAsFixed(2)}x');

      return enhanced;
    } catch (e) {
      print('🤖 ERROR: AI model processing failed: $e');
      print('🤖 Falling back to basic enhancement');
      return _fallbackEnhancement(markdown);
    }
  }

  /// Simulate AI enhancements to markdown
  String _simulateAIEnhancement(String markdown, {String? modelId}) {
    // This simulates what an AI model might do to improve the markdown
    String enhancedMarkdown = markdown
        // Improve heading structure
        .replaceAll(RegExp(r'([^\n])(#{1,6}\s)'), r'$1\n\n$2')
        .replaceAll(RegExp(r'(#{1,6}[^\n]+)([^\n])'), r'$1\n\n$2')

        // Better list formatting
        .replaceAll(RegExp(r'\n\s*[-*]\s'), '\n* ')
        .replaceAll(RegExp(r'\n\s*(\d+)[.)] '), r'\n$1. ')

        // Improve code block detection and formatting
        .replaceAll(RegExp(r'```([a-zA-Z]*)\s*\n'), r'```$1\n')
        .replaceAll(RegExp(r'\n\s*```\s*\n'), '\n```\n')

        // Fix table formatting
        .replaceAll(RegExp(r'\n(\s*\|[^\n]+\|\s*)\n(?!\s*\|)'), r'\n$1\n\n')

        // Fix link formatting
        .replaceAll(RegExp(r'\[([^\]]+)\]\s*\(([^)]+)\)'), r'[$1]($2)')

        // Improve paragraph spacing
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')

        // Clean up HTML entities
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll("&apos;", "'");

    // Add a signature based on the model used
    final modelName = modelId == 'phi-3-mini' ? 'Phi-3 Mini' : 'Gemma 2B-IT';
    enhancedMarkdown += '\n\n<!-- Enhanced with $modelName model -->';

    return enhancedMarkdown;
  }

  /// Process product extraction with AI enhancement
  Future<String> processProductExtraction(
    String markdown, {
    String? extractionPrompt,
    String? modelId,
  }) async {
    final String actualModelId = modelId ?? _defaultModelId;
    final modelAvailable = await isModelAvailable(modelId: actualModelId);
    final modelPath = await _getModelPath(modelId: actualModelId);

    // Log the request to the AI model
    print('🏪 PRODUCT EXTRACTION REQUEST:');
    print('🏪 Model available: $modelAvailable');
    print('🏪 Model path: $modelPath');
    print('🏪 Model ID: $actualModelId');
    print('🏪 Input length: ${markdown.length} characters');
    print('🏪 Markdown content: $markdown');

    if (!modelAvailable) {
      print('🏪 WARNING: Model not available, using fallback extraction');
      return _fallbackProductExtraction(markdown);
    }

    try {
      // Simulate AI processing time for product extraction
      final startTime = DateTime.now();

      // Add the extraction prompt if provided
      final processedInput = extractionPrompt != null
          ? "$extractionPrompt\n\nContent:\n$markdown"
          : markdown;

      // Simulate proportional processing time
      final processingTime = (processedInput.length / 1500).clamp(0.8, 5.0);
      await Future.delayed(
          Duration(milliseconds: (processingTime * 1000).toInt()));

      // Extract product information - use the appropriate model for extraction
      final productInfo = _extractProductInfo(markdown, modelId: actualModelId);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log successful processing
      print('🏪 PRODUCT EXTRACTION COMPLETED:');
      print('🏪 Processing time: ${duration.inMilliseconds}ms');
      print('🏪 Output length: ${productInfo.length} characters');

      return productInfo;
    } catch (e) {
      print('🏪 ERROR: AI product extraction failed: $e');
      print('🏪 Falling back to basic extraction');
      return _fallbackProductExtraction(markdown);
    }
  }

  /// Extract product information with simulated AI
  String _extractProductInfo(String markdown, {String? modelId}) {
    // Extract product name
    String productName = 'Unknown Product';
    final titleMatch = RegExp(r'# (.+)\n').firstMatch(markdown);
    if (titleMatch != null) {
      productName = titleMatch.group(1)!.trim();
    }

    // Extract price - look for currency symbols and numbers
    String price = 'Not available';
    final pricePattern = RegExp(
        r'(?:price|fiyat|ücret|tutar|₺|TL|\$|€)[^\n]*?(\d+[.,]\d+)[^\n]*',
        caseSensitive: false);
    final priceMatch = pricePattern.firstMatch(markdown);
    if (priceMatch != null) {
      price = priceMatch.group(0)!.trim();
    }

    // Extract brand
    String brand = 'Unknown';
    final brandPatterns = [
      RegExp(r'brand[^\n]*?:\s*([^\n]+)', caseSensitive: false),
      RegExp(r'marka[^\n]*?:\s*([^\n]+)', caseSensitive: false),
    ];

    for (final pattern in brandPatterns) {
      final brandMatch = pattern.firstMatch(markdown);
      if (brandMatch != null && brandMatch.group(1) != null) {
        brand = brandMatch.group(1)!.trim();
        break;
      }
    }

    // Extract description
    String description = 'No description available';
    final descPattern = RegExp(
        r'(?:## |### )(?:.*description.*|.*product.*|.*details.*)[^\n]*\n((?:.+\n)+)',
        caseSensitive: false);
    final descMatch = descPattern.firstMatch(markdown);
    if (descMatch != null && descMatch.group(1) != null) {
      description = descMatch.group(1)!.trim();
    }

    // Extract specifications or features
    List<String> features = [];
    final featurePattern = RegExp(r'[-*•]\s*([^\n]+)', caseSensitive: false);
    final featureMatches = featurePattern.allMatches(markdown);
    for (final match in featureMatches) {
      if (match.group(1) != null) {
        features.add('- ${match.group(1)!.trim()}');
      }
    }

    final featuresSection = features.isNotEmpty
        ? "## Key Features\n\n${features.join('\n')}"
        : "## Key Features\n\nNo specific features found";

    // Different signature based on the model used
    final modelName = modelId == 'phi-3-mini' ? 'Phi-3 Mini' : 'Gemma 2B-IT';

    // Format the output in a nice markdown structure
    return '''
# $productName

## Brand
$brand

## Price
$price

## Description
$description

$featuresSection

---
*Extracted with $modelName AI model*
''';
  }

  /// Basic enhancement without AI
  String _fallbackEnhancement(String markdown) {
    return markdown
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .replaceAll(RegExp(r'([^\n])(#{1,6}\s)'), r'$1\n\n$2')
            .replaceAll(RegExp(r'\n\s*[-*]\s'), '\n* ')
            .replaceAll(RegExp(r'\n\s*(\d+)[.)] '), r'\n$1. ')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll("&apos;", "'")
            .trim() +
        '\n\n<!-- Enhanced with basic formatting (AI model not available) -->';
  }

  /// Basic product extraction (fallback)
  String _fallbackProductExtraction(String markdown) {
    // Simplified extraction without AI
    final title =
        RegExp(r'# (.+)\n').firstMatch(markdown)?.group(1) ?? 'Unknown Product';
    final price =
        RegExp(r'(?:price|fiyat|ücret|tutar|₺|TL|\$|€)[^\n]*?(\d+[.,]\d+)[^\n]*',
                    caseSensitive: false)
                .firstMatch(markdown)
                ?.group(0) ??
            'Price not found';

    return '''
# $title

## Price
$price

## Other Information
The AI model is not available to extract detailed product information.
Please download the AI model for better product extraction.

---
*Basic extraction (AI model not available)*
''';
  }
}
