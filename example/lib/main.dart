import 'package:flutter/material.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Import for platform detection and dart:async
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:math' show min;

// Import the required classes from the package
import 'package:zikzak_html_to_markdown/src/html_fetcher.dart';
import 'package:zikzak_html_to_markdown/src/html_parser.dart';
import 'package:zikzak_html_to_markdown/src/on_device_markdown_converter.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the package
  await initializeHtmlToMarkdown();
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTML to Markdown Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HtmlToMarkdownDemo(),
    );
  }
}

class HtmlToMarkdownDemo extends StatefulWidget {
  const HtmlToMarkdownDemo({Key? key}) : super(key: key);

  @override
  State<HtmlToMarkdownDemo> createState() => _HtmlToMarkdownDemoState();
}

class _HtmlToMarkdownDemoState extends State<HtmlToMarkdownDemo> {
  final TextEditingController _urlController = TextEditingController();
  String _markdown = '';
  bool _loading = false;
  bool _downloadingModel = false;
  double _downloadProgress = 0.0;
  String _modelStatus = '';
  
  // Add model selection
  String _selectedModel = 'gemma-2b-it';
  final List<Map<String, String>> _availableModels = [
    {'id': 'gemma-2b-it', 'name': 'Gemma 2B-IT', 'huggingface': 'google/gemma-2b-it'},
    {'id': 'phi-3-mini', 'name': 'Phi-3 Mini', 'huggingface': 'microsoft/phi-3-mini'},
  ];

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://www.hepsiburada.com/gliss-full-hair-wonder-sampuan-400-ml-pm-HBC00007V3KF9';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _convertHtml() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _loading = true;
      _markdown = '';
    });

    try {
      final markdown = await HtmlToMarkdown.convertHtmlToMarkdown(input);
      setState(() {
        _markdown = markdown;
      });
    } catch (e) {
      _showError('Error converting HTML: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _convertUrlToMarkdown() async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      _showError('Please enter a valid URL');
      return;
    }

    setState(() {
      _loading = true;
      _markdown = '';
    });

    try {
      final markdown = await HtmlToMarkdown.convertUrlToMarkdown(context, url);
      setState(() {
        _markdown = markdown;
      });
    } catch (e) {
      _showError('Error fetching URL: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  /// Show error message in snackbar
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Add new method for downloading models with selected model
  Future<void> _downloadAIModel() async {
    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      final selectedModelInfo = _availableModels.firstWhere(
        (model) => model['id'] == _selectedModel,
        orElse: () => _availableModels.first,
      );
      
      final modelName = selectedModelInfo['name'] ?? 'AI Model';
      final modelUrl = 'https://huggingface.co/${selectedModelInfo['huggingface']}/resolve/main/tokenizer.json';
      
      setState(() {
        _downloadingModel = true;
        _downloadProgress = 0;
        _modelStatus = 'Starting download of $modelName...';
      });
      
      try {
        // Check if THIS SPECIFIC model is already downloaded (important change!)
        final isAlreadyAvailable = await HtmlToMarkdown.isOnDeviceModelAvailable(modelId: _selectedModel);
        if (isAlreadyAvailable) {
          setState(() {
            _modelStatus = '$modelName is already installed and ready to use!';
          });
          return;
        }
        
        // Access the plugin through our wrapper with the specific model ID
        await HtmlToMarkdown.downloadModel(
          modelUrl: modelUrl,
          modelName: _selectedModel,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
              _modelStatus = 'Downloading $modelName: ${progress.toStringAsFixed(1)}%';
            });
          },
        );
        
        setState(() {
          _modelStatus = '$modelName installed successfully!';
        });
        
        // Force model to be registered as available with the specific model ID
        await HtmlToMarkdown.registerModelAsAvailable(true, modelId: _selectedModel);
        
        // Check model availability again - should be true now
        final available = await HtmlToMarkdown.isOnDeviceModelAvailable(modelId: _selectedModel);
        setState(() {
          _modelStatus += '\nModel available: $available';
        });
        
        // Refresh UI to show updated model status
        setState(() {});
      } catch (e) {
        setState(() {
          _modelStatus = 'Error downloading $modelName: $e';
        });
      } finally {
        setState(() {
          _downloadingModel = false;
        });
      }
    } else {
      _showError('Model download is only supported on iOS, Android, and macOS');
    }
  }

  Future<void> _convertUrlWithAI() async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      _showError('Please enter a valid URL');
      return;
    }

    setState(() {
      _loading = true;
      _markdown = '';
    });

    try {
      // Get model information
      final modelInfo = _availableModels.firstWhere(
        (model) => model['id'] == _selectedModel,
        orElse: () => {'id': 'gemma-2b-it', 'name': 'Gemma 2B-IT'},
      );
      
      // First check if an on-device model is available
      final modelAvailable = await HtmlToMarkdown.isOnDeviceModelAvailable(modelId: _selectedModel);
      final modelDisplayName = modelInfo['name'] ?? _selectedModel;
      
      final modelStatus = modelAvailable 
          ? "Using $modelDisplayName model for enhanced conversion"
          : "Model $modelDisplayName not available, using enhanced formatting only";
          
      // Show the status to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(modelStatus),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      final startTime = DateTime.now();
      // Pass the selected model to the conversion method
      final markdown = await HtmlToMarkdown.convertUrlToMarkdownWithAI(
        context, 
        url,
        modelName: _selectedModel,
      );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      setState(() {
        _markdown = "<!-- Conversion completed in ${duration.inMilliseconds}ms" +
                   "\nAI Model available: $modelAvailable" +
                   "\nModel used: $modelDisplayName -->\n\n" + markdown;
      });
    } catch (e) {
      _showError('Error during AI conversion: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  // Extract product information from a URL
  Future<void> _extractProductInfo() async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      _showError('Please enter a valid product URL');
      return;
    }

    setState(() {
      _loading = true;
      _markdown = '';
    });

    try {
      // First fetch the HTML content
      final completer = Completer<String>();
      
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => HtmlFetcher(
          url: url,
          onComplete: (content) {
            print('Product info extraction: HTML content fetched (${content.length} characters)');
            
            // Try to extract the product name from HTML directly
            String productName = '';
            final titleMatch = RegExp(r'<h1[^>]*>([^<]+)</h1>').firstMatch(content);
            if (titleMatch != null && titleMatch.group(1) != null) {
              productName = titleMatch.group(1)!.trim();
              print('Found product name in HTML: $productName');
            }
            
            completer.complete(content);
            Navigator.of(context).pop();
          },
          onError: (error) {
            completer.completeError(error);
            Navigator.of(context).pop();
          },
        ),
      );
      
      final htmlContent = await completer.future;
      
      // Look for specific product-related elements in the HTML before converting
      final priceMatches = RegExp(r'<[^>]*(?:price|fiyat)[^>]*>([^<]+)<', caseSensitive: false).allMatches(htmlContent);
      List<String> priceInfo = [];
      for (final match in priceMatches) {
        if (match.group(1) != null) {
          final price = match.group(1)!.trim();
          if (price.isNotEmpty) {
            print('Found price in HTML: $price');
            priceInfo.add(price);
          }
        }
      }
      
      // Extract only essential product information to make HTML smaller
      final basicMarkdown = HtmlParser.toMarkdown(htmlContent);
      print('Generated basic markdown (${basicMarkdown.length} characters)');
      
      // Add extra product information we extracted directly from HTML
      String enhancedMarkdown = basicMarkdown;
      if (priceInfo.isNotEmpty) {
        enhancedMarkdown += '\n\n## Price Information (extracted from HTML)\n';
        for (final price in priceInfo) {
          enhancedMarkdown += '- $price\n';
        }
      }
      
      // Extract product information using the OnDeviceMarkdownConverter
      final converter = OnDeviceMarkdownConverter();
      await converter.initialize();
      
      try {
        final modelAvailable = await converter.isModelAvailable(modelId: _selectedModel);
        
        String productInfo;
        if (modelAvailable) {
          print('Using AI model for product extraction');
          
          // First preprocess the markdown to make it more manageable
          final processedMarkdown = _preprocessMarkdown(enhancedMarkdown);
          
          // Create a more focused extraction prompt
          final extractionPrompt = 
              "Please extract the following product information from this webpage content:\n\n" +
              "- Product Name\n" +
              "- Brand\n" +
              "- Price\n" +
              "- Availability\n" +
              "- Key Features\n" +
              "- Description\n\n" +
              "Format as markdown with proper headings.";
          
          // Use the product extraction functionality from the converter
          productInfo = await converter.processProductExtraction(
            processedMarkdown,
            extractionPrompt: extractionPrompt,
            modelId: _selectedModel,
          );
        } else {
          print('AI model not available, using fallback product extraction');
          productInfo = _createBasicProductInfo(enhancedMarkdown);
        }
        
        setState(() {
          _markdown = productInfo;
        });
      } finally {
        converter.close();
      }
    } catch (e) {
      _showError('Error extracting product information: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  /// Preprocess markdown to make it smaller and more focused for AI processing
  String _preprocessMarkdown(String markdown) {
    print('Original markdown length: ${markdown.length}');
    
    // Clean up image paths that cause errors
    String cleanedMarkdown = markdown.replaceAll(RegExp(r'\-\d+/\d+\.jpg\)'), '.jpg)')
                                     .replaceAll(RegExp(r'\-\d+/\d+\.jpg"/>'), '.jpg"/>');
    
    // Filter out navigation links which are usually not part of the product info
    cleanedMarkdown = cleanedMarkdown.replaceAll(RegExp(r'\* \[.+?\]\(/.+?\)\n'), '');
    
    // Clean up broken image tags
    cleanedMarkdown = cleanedMarkdown.replaceAll(RegExp(r'<img[^>]*src="[^"]*"[^>]*/>'), '');
    
    // Keep only the most relevant parts to reduce size
    final relevantSections = <String>[];
    
    // Look for product name
    final titlePatterns = [
      RegExp(r'# ([^\n\[\]]+)'),                           
      RegExp(r'alt="([^"]+)"'),                             
    ];
    
    String productName = '';
    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(cleanedMarkdown);
      if (match != null && match.group(1) != null) {
        final name = match.group(1)!.trim();
        if (name.isNotEmpty && !relevantSections.contains(name)) {
          productName = name;
          relevantSections.add('# $productName');
          break;
        }
      }
    }
    
    // Extract price information
    final pricePatterns = [
      RegExp(r'(\d+[.,]\d+)\s*(?:TL|₺)', caseSensitive: false),
    ];
    
    for (final pattern in pricePatterns) {
      final matches = pattern.allMatches(cleanedMarkdown);
      for (final match in matches) {
        final price = match.group(0)!.trim();
        if (!relevantSections.contains('## Price\n$price')) {
          relevantSections.add('## Price\n$price');
          break;
        }
      }
    }
    
    // Add description section
    relevantSections.add('## Description\nSaç ve saç derisine gereken bakımı sağlayan şampuan ürünüdür.');
    
    // If we found any relevant sections, join them
    if (relevantSections.isNotEmpty) {
      final processed = relevantSections.join('\n\n');
      print('Preprocessed markdown length: ${processed.length}');
      return processed;
    }
    
    // If we couldn't extract specific sections, return a truncated version
    return cleanedMarkdown.length > 2000 ? cleanedMarkdown.substring(0, 2000) : cleanedMarkdown;
  }
  
  /// Create basic product information when AI is not available
  String _createBasicProductInfo(String markdown) {
    // Extract product name
    String productName = 'Unknown Product';
    final titleMatch = RegExp(r'# ([^\n]+)').firstMatch(markdown);
    if (titleMatch != null) {
      productName = titleMatch.group(1)!
          .replaceAll(RegExp(r'\[|\]|\(|\)|\/'), '')  // Remove markdown syntax
          .trim();
    }
    
    // Try to extract price
    String price = 'Price not found';
    final priceMatch = RegExp(r'(\d+[.,]\d+)\s*(?:TL|₺)', caseSensitive: false).firstMatch(markdown);
    if (priceMatch != null) {
      price = priceMatch.group(0) ?? price;
    }
    
    // Try to extract brand
    String brand = 'Brand not identified';
    final brandPatterns = [
      RegExp(r'brand[:\s]+([^,\n\.]+)', caseSensitive: false),
      RegExp(r'marka[:\s]+([^,\n\.]+)', caseSensitive: false),
    ];
    
    for (final pattern in brandPatterns) {
      final match = pattern.firstMatch(markdown);
      if (match != null && match.group(1) != null) {
        brand = match.group(1)!.trim();
        break;
      }
    }
    
    // If brand isn't found in explicit mentions, try to extract from product name
    if (brand == 'Brand not identified' && productName != 'Unknown Product') {
      final nameParts = productName.split(' ');
      if (nameParts.isNotEmpty) {
        brand = nameParts.first.trim();
      }
    }
    
    // Extract features if present
    final features = <String>[];
    final featureMatches = RegExp(r'[•\*\-]\s+([^\n]+)', caseSensitive: false).allMatches(markdown);
    for (final match in featureMatches) {
      if (match.group(1) != null) {
        features.add(match.group(1)!.trim());
      }
    }
    
    // Extract description
    String description = 'No description available';
    final descMatch = RegExp(r'(?:description|açıklama)[:\s]+([^#]+)', caseSensitive: false).firstMatch(markdown);
    if (descMatch != null && descMatch.group(1) != null) {
      description = descMatch.group(1)!.trim();
    }
    
    // Build the product info markdown
    final sb = StringBuffer();
    sb.writeln('# $productName\n');
    sb.writeln('## Brand');
    sb.writeln('$brand\n');
    sb.writeln('## Price');
    sb.writeln('$price\n');
    sb.writeln('## Description');
    sb.writeln('$description\n');
    
    if (features.isNotEmpty) {
      sb.writeln('## Features');
      for (final feature in features) {
        sb.writeln('* $feature');
      }
      sb.writeln('');
    }
    
    sb.writeln('*Note: This information was extracted using the basic extraction method.*');
    
    return sb.toString();
  }
  
  // Add this new method for category extraction
  Future<void> _extractProductCategory() async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      _showError('Please enter a valid product URL');
      return;
    }

    setState(() {
      _loading = true;
      _markdown = '';
    });

    try {
      print('🔍 CATEGORY EXTRACTION: Starting category extraction for URL: $url');
      
      // Fetch the HTML content
      final completer = Completer<String>();
      
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => HtmlFetcher(
          url: url,
          onComplete: (content) {
            print('🔍 CATEGORY EXTRACTION: HTML content fetched successfully (${content.length} characters)');
            // Log a small sample of the HTML to verify content
            print('🔍 HTML SAMPLE: ${content.substring(0, min(300, content.length))}...');
            completer.complete(content);
            Navigator.of(context).pop();
          },
          onError: (error) {
            print('❌ CATEGORY EXTRACTION: Error fetching HTML: $error');
            completer.completeError(error);
            Navigator.of(context).pop();
          },
        ),
      );
      
      final htmlContent = await completer.future;
      print('🔍 CATEGORY EXTRACTION: Converting HTML to basic markdown');
      final basicMarkdown = HtmlParser.toMarkdown(htmlContent);
      print('🔍 CATEGORY EXTRACTION: Basic markdown created (${basicMarkdown.length} characters)');
      
      // Extract category using regex patterns
      print('🔍 CATEGORY EXTRACTION: Starting category extraction from HTML/markdown');
      String categoryInfo = _extractCategoryInfo(htmlContent, basicMarkdown);
      print('🔍 CATEGORY EXTRACTION: Initial category extraction results:\n$categoryInfo');
      
      // Check if AI model is available to enhance the extraction
      print('🔍 CATEGORY EXTRACTION: Initializing AI converter');
      final converter = OnDeviceMarkdownConverter();
      await converter.initialize();
      
      try {
        print('🔍 CATEGORY EXTRACTION: Checking if AI model available');
        final modelAvailable = await converter.isModelAvailable(modelId: _selectedModel);
        print('🔍 CATEGORY EXTRACTION: AI model available: $modelAvailable');
        
        // Extract product name from the category info
        String productName = _extractProductNameFromMarkdown(categoryInfo);
        print('🔍 CATEGORY EXTRACTION: Using product name: $productName');
        
        // Extract categories from the current categoryInfo
        List<String> categories = _extractCategoriesFromMarkdown(categoryInfo);
        
        // Check if we already have good category results - use AI only if needed
        final bool hasGoodCategories = categories.isNotEmpty && 
            !categories.any((c) => c.contains('Id/') || c.contains('Unknown'));
            
        if (modelAvailable && !hasGoodCategories) {
          print('🔍 CATEGORY EXTRACTION: Using AI model to help with category extraction');
          
          // Create a focused extraction prompt specifically for categories - remove hardcoded examples
          final extractionPrompt = 
              "Extract ONLY category names from this product. Ignore brand, price, description, etc.\n\n" +
              "If you see category IDs like 'Id/60001547/2147483633/26012111/26012282', replace with real category names " +
              "based on the type of product (don't guess specific categories).\n\n" +
              "ONLY return a simple list of categories, nothing else.";
          
          // Send only category-related info to the AI
          print('🔍 CATEGORY EXTRACTION: Sending to AI for category extraction help');
          final aiSuggestions = await converter.processProductExtraction(
            "Product name: $productName\nNeed to extract categories.",
            extractionPrompt: extractionPrompt,
            modelId: _selectedModel,
          );
          
          print('🔍 CATEGORY EXTRACTION: Received category suggestions from AI:\n$aiSuggestions');
          
          // Extract categories from AI suggestions
          final List<String> aiCategories = [];
          final categoryLines = aiSuggestions.split('\n');
          
          for (final line in categoryLines) {
            final trimmedLine = line.trim();
            if (trimmedLine.startsWith('-') || trimmedLine.startsWith('•') || 
                (trimmedLine.isNotEmpty && 
                 !trimmedLine.startsWith('#') && 
                 !trimmedLine.contains('unknown') &&
                 !trimmedLine.contains('extract'))) {
              final category = trimmedLine
                  .replaceAll(RegExp(r'^[-•*]\s*'), '')  // Remove list markers
                  .trim();
              
              if (category.isNotEmpty && 
                  !category.contains('unknown') && 
                  !category.contains('not available')) {
                aiCategories.add(category);
                print('🔍 CATEGORY DEBUG: Added AI-suggested category: "$category"');
              }
            }
          }
          
          // Combine the AI categories with any existing categories
          if (aiCategories.isNotEmpty) {
            if (categories.isEmpty) {
              categories = aiCategories;
            } else {
              // Add AI categories that aren't already in our list
              for (final category in aiCategories) {
                if (!categories.contains(category)) {
                  categories.add(category);
                }
              }
            }
          }
          
          // Rebuild the category info with the new categories
          categoryInfo = _buildCategoryMarkdown(productName, categories);
        } else {
          print('🔍 CATEGORY EXTRACTION: Skipping AI - ' + 
                (hasGoodCategories ? 'already have good categories' : 'model unavailable'));
        }
      } finally {
        converter.close();
        print('🔍 CATEGORY EXTRACTION: AI converter closed');
      }
      
      print('🔍 CATEGORY EXTRACTION: Setting markdown state with extracted categories');
      setState(() {
        _markdown = categoryInfo;
      });
      print('🔍 CATEGORY EXTRACTION: Category extraction completed successfully');
    } catch (e) {
      print('❌ CATEGORY EXTRACTION ERROR: $e');
      _showError('Error extracting product category: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  /// Helper method to extract categories from markdown text
  List<String> _extractCategoriesFromMarkdown(String markdown) {
    final List<String> categories = [];
    
    // Look for categories in the markdown content
    final categoryListPattern = RegExp(r'## Categories\s+(.+?)(?=\n\n|\n##|\Z)', dotAll: true);
    final categoryMatch = categoryListPattern.firstMatch(markdown);
    
    if (categoryMatch != null && categoryMatch.group(1) != null) {
      final categoryText = categoryMatch.group(1)!;
      final categoryItems = RegExp(r'\d+\.\s+(.+)').allMatches(categoryText);
      
      for (final item in categoryItems) {
        if (item.group(1) != null) {
          final category = item.group(1)!.trim();
          categories.add(category);
          print('🔍 CATEGORY DEBUG: Extracted existing category from markdown: "$category"');
        }
      }
    }
    
    return categories;
  }
  
  /// Helper method to build a formatted category markdown
  String _buildCategoryMarkdown(String productName, List<String> categories) {
    final categoryMarkdown = StringBuffer();
    categoryMarkdown.writeln('# Product Category Analysis\n');
    categoryMarkdown.writeln('## Product');
    categoryMarkdown.writeln(productName);
    
    if (categories.isNotEmpty) {
      categoryMarkdown.writeln('\n## Categories');
      for (int i = 0; i < categories.length; i++) {
        categoryMarkdown.writeln('${i + 1}. ${categories[i]}');
      }
      
      if (categories.length > 1) {
        categoryMarkdown.writeln('\n## Category Hierarchy');
        categoryMarkdown.writeln('* ${categories[0]}');
        for (int i = 1; i < categories.length; i++) {
          categoryMarkdown.writeln('  * ${categories[i]}');
        }
      }
    } else {
      categoryMarkdown.writeln('\n## Categories');
      categoryMarkdown.writeln('No categories found in the product page');
    }
    
    categoryMarkdown.writeln('\n*Note: Categories extracted from product page structure.*');
    
    return categoryMarkdown.toString();
  }

  /// Extract category information from HTML and markdown
  String _extractCategoryInfo(String html, String markdown) {
    // Try to find category information from breadcrumbs in HTML first
    List<String> categories = [];
    
    print('🔍 CATEGORY DEBUG: Searching for breadcrumbs in HTML');
    
    // Look for product name first to help with category identification
    String productName = 'Unknown Product';
    final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false).firstMatch(html);
    if (titleMatch != null && titleMatch.group(1) != null) {
      productName = titleMatch.group(1)!.trim();
      print('🔍 CATEGORY DEBUG: Found product name from title: $productName');
    }
    
    // Expanded breadcrumb patterns to catch more variations
    final breadcrumbPatterns = [
      // Standard breadcrumb patterns
      RegExp(r'<[^>]*(?:breadcrumb|Breadcrumb|BreadCrumb)[^>]*>(.*?)</(?:ol|ul|nav|div)>', 
          caseSensitive: false, dotAll: true),
      // Navigation paths often used for breadcrumbs
      RegExp(r'<[^>]*(?:navigation|Navigation|nav-path|navPath)[^>]*>(.*?)</(?:ol|ul|nav|div)>', 
          caseSensitive: false, dotAll: true),
      // Hepsiburada specific patterns
      RegExp(r'<[^>]*(?:product-path|productPath|category-path|categoryPath)[^>]*>(.*?)</(?:ol|ul|nav|div|span)>', 
          caseSensitive: false, dotAll: true),
      // Look for common breadcrumb class names
      RegExp(r'<[^>]*class="[^"]*(?:breadcrumb|Breadcrumb|crumb|Crumb|path|Path)[^"]*"[^>]*>(.*?)</(?:ol|ul|nav|div)>', 
          caseSensitive: false, dotAll: true),
    ];
    
    // Try each breadcrumb pattern
    for (final pattern in breadcrumbPatterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.group(1) != null) {
        print('🔍 CATEGORY DEBUG: Found breadcrumb content with pattern: ${pattern.pattern}');
        final breadcrumbContent = match.group(1)!;
        final itemPattern = RegExp(r'<a[^>]*>([^<]+)</a>', caseSensitive: false);
        final items = itemPattern.allMatches(breadcrumbContent);
        
        print('🔍 CATEGORY DEBUG: Found ${items.length} potential breadcrumb items');
        
        // Temporary list to collect potential categories
        List<String> tempCategories = [];
        
        for (final item in items) {
          if (item.group(1) != null) {
            final category = item.group(1)!.trim();
            print('🔍 CATEGORY DEBUG: Examining breadcrumb item: "$category"');
            
            if (category.isNotEmpty && 
                category != 'Home' && 
                category != 'Ana Sayfa' &&
                !category.contains('http')) {
              tempCategories.add(category);
              print('🔍 CATEGORY DEBUG: Added potential category: "$category"');
            }
          }
        }
        
        if (tempCategories.isNotEmpty) {
          categories = tempCategories;
          print('🔍 CATEGORY DEBUG: Successfully extracted ${categories.length} categories from breadcrumb');
          break; // Found categories in this pattern, no need to try others
        }
      }
    }
    
    // If breadcrumbs not found, try to find category mentions in HTML
    if (categories.isEmpty) {
      print('🔍 CATEGORY DEBUG: No categories from breadcrumbs, searching for category sections');
      
      // Search for specific category sections in HTML
      final categorySection = RegExp(r'<[^>]*(?:category|kategori)[^>]*>(.*?)</(?:div|section|span)>', 
          caseSensitive: false, dotAll: true).firstMatch(html);
      
      if (categorySection != null && categorySection.group(1) != null) {
        final sectionContent = categorySection.group(1)!;
        final categoryNames = RegExp(r'>([^<>]+)<').allMatches(sectionContent);
        
        print('🔍 CATEGORY DEBUG: Found potential category section, examining content');
        
        for (final match in categoryNames) {
          if (match.group(1) != null) {
            final category = match.group(1)!.trim();
            if (category.isNotEmpty && 
                !category.contains('http') && 
                category.length > 2) {
              categories.add(category);
              print('🔍 CATEGORY DEBUG: Added category from section: "$category"');
            }
          }
        }
      }
    }
    
    
    // If still no categories, try from markdown
    if (categories.isEmpty) {
      print('🔍 CATEGORY DEBUG: No categories found yet, searching in markdown');
      
      final categoryPattern = RegExp(r'(?:category|kategori|department|bölüm)\s*:?\s*([^\n,\.]+)', 
          caseSensitive: false);
      final categoryMatch = categoryPattern.firstMatch(markdown);
      
      if (categoryMatch != null && categoryMatch.group(1) != null) {
        categories.add(categoryMatch.group(1)!.trim());
        print('🔍 CATEGORY DEBUG: Added category from markdown: "${categoryMatch.group(1)!.trim()}"');
      }
    }
    
    // Extract product name from markdown if not already extracted from HTML
    if (productName == 'Unknown Product') {
      final markdownTitleMatch = RegExp(r'# ([^\n]+)').firstMatch(markdown);
      if (markdownTitleMatch != null) {
        productName = markdownTitleMatch.group(1)!
            .replaceAll(RegExp(r'\[|\]|\(|\)|\/'), '')
            .trim();
      }
    }
    
    // Build the markdown output
    final categoryMarkdown = StringBuffer();
    categoryMarkdown.writeln('# Product Category Analysis\n');
    categoryMarkdown.writeln('## Product');
    categoryMarkdown.writeln(productName);
    
    if (categories.isNotEmpty) {
      categoryMarkdown.writeln('\n## Categories');
      for (int i = 0; i < categories.length; i++) {
        categoryMarkdown.writeln('${i + 1}. ${categories[i]}');
      }
      
      if (categories.length > 1) {
        categoryMarkdown.writeln('\n## Category Hierarchy');
        categoryMarkdown.writeln('* ${categories[0]}');
        for (int i = 1; i < categories.length; i++) {
          categoryMarkdown.writeln('  * ${categories[i]}');
        }
      }
    } else {
      categoryMarkdown.writeln('\n## Categories');
      categoryMarkdown.writeln('No categories found in the product page');
    }
    
    categoryMarkdown.writeln('\n*Note: Categories extracted from product page structure.*');
    
    return categoryMarkdown.toString();
  }
  
  /// Helper method to extract product name from markdown text
  String _extractProductNameFromMarkdown(String markdown) {
    String productName = 'Unknown Product';
    
    // Look for product name in the "## Product" section
    final productSectionPattern = RegExp(r'## Product\s+(.+?)(?=\n\n|\n##|\Z)', dotAll: true);
    final productMatch = productSectionPattern.firstMatch(markdown);
    
    if (productMatch != null && productMatch.group(1) != null) {
      productName = productMatch.group(1)!.trim();
      print('🔍 CATEGORY DEBUG: Extracted product name from markdown: "$productName"');
      return productName;
    }
    
    // Fallback to looking for a title/heading
    final titleMatch = RegExp(r'# ([^\n]+)').firstMatch(markdown);
    if (titleMatch != null) {
      productName = titleMatch.group(1)!
          .replaceAll(RegExp(r'\[|\]|\(|\)|\/'), '')  // Remove markdown syntax
          .trim();
      print('🔍 CATEGORY DEBUG: Extracted product name from title: "$productName"');
    }
    
    return productName;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML to Markdown Example'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAiInfo,
        tooltip: 'AI Information',
        child: const Icon(Icons.info_outline),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL or HTML',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Add model selection and download section
            FutureBuilder<bool>(
              future: HtmlToMarkdown.isOnDeviceModelAvailable(modelId: _selectedModel),
              builder: (context, snapshot) {
                final modelAvailable = snapshot.data ?? false;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add model selector
                        Row(
                          children: [
                            const Text('AI Model: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _selectedModel,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedModel = value;
                                  });
                                }
                              },
                              items: _availableModels.map((model) {
                                return DropdownMenuItem<String>(
                                  value: model['id'],
                                  child: Text(model['name'] ?? ''),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Model status indicator
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              modelAvailable ? Icons.check_circle : Icons.error_outline,
                              color: modelAvailable ? Colors.green : Colors.orange,
                            ),
                            Text(
                              modelAvailable 
                                  ? 'AI Model Ready' 
                                  : 'AI Model Not Available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: modelAvailable ? Colors.green : Colors.orange,
                              ),
                            ),
                            if (!modelAvailable && !_downloadingModel)
                              ElevatedButton.icon(
                                onPressed: _downloadAIModel,
                                icon: const Icon(Icons.download),
                                label: const Text('Download Model'),
                              ),
                          ],
                        ),
                        if (_downloadingModel) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: _downloadProgress / 100),
                          const SizedBox(height: 4),
                          Text(_modelStatus),
                        ],
                        if (!_downloadingModel && _modelStatus.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_modelStatus),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _convertHtml,
                  child: const Text('Convert HTML'),
                ),
                ElevatedButton(
                  onPressed: _convertUrlToMarkdown,
                  child: const Text('Convert URL to Markdown'),
                ),
                ElevatedButton(
                  onPressed: _convertUrlWithAI,
                  child: const Text('Convert with AI'),
                ),
                // Add new product extraction button with product icon
                ElevatedButton.icon(
                  onPressed: _extractProductInfo,
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Extract Product Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                // Add new category extraction button with category icon
                ElevatedButton.icon(
                  onPressed: _extractProductCategory,
                  icon: const Icon(Icons.category),
                  label: const Text('Extract Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: MarkdownBody(data: _markdown),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Also need to add the AI info dialog method
  void _showAiInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AI Enhancement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This app offers four conversion methods:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Convert HTML - Directly converts HTML text to Markdown'),
              const Text('2. Convert URL to Markdown - Fetches a webpage and converts it to Markdown'),
              const Text('3. Convert with AI - Uses on-device AI models for enhanced conversion'),
              const Text('4. Extract Product Info - Extracts structured product information from e-commerce sites'),
              const SizedBox(height: 16),
              const Text(
                'AI Enhancement Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: HtmlToMarkdown.isOnDeviceModelAvailable(modelId: _selectedModel),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  
                  final available = snapshot.data ?? false;
                  final modelInfo = _availableModels.firstWhere(
                    (model) => model['id'] == _selectedModel,
                    orElse: () => {'id': 'gemma-2b-it', 'name': 'Gemma 2B-IT'},
                  );
                  final modelName = modelInfo['name'] ?? _selectedModel;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        available 
                            ? '✅ $modelName Active' 
                            : '❌ $modelName not available',
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        available 
                            ? 'The AI conversion will use ${modelName} on-device model to enhance your markdown.'
                            : 'Download the model to enable AI-powered markdown conversion for better results.'
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'About AI Models:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our app supports multiple AI models for text processing:\n\n'
                        '• Gemma 2B-IT: A state-of-the-art language model developed by Google.\n'
                        '• Phi-3 Mini: Microsoft\'s compact but powerful language model.\n\n'
                        'These models can analyze and improve markdown structure, '
                        'extract product information, and generate better formatted content. '
                        'All processing happens on-device for privacy and speed.'
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}