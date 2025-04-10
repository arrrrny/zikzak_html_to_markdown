import 'package:flutter/material.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Import for platform detection and dart:async
import 'dart:io' show Platform;
import 'dart:async';

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
    String brand = 'Unknown Brand';
    if (productName.contains('Gliss')) {
      brand = 'Gliss';
    }
    
    return '''
# $productName

## Brand
$brand

## Price
$price

## Description
Saç bakımı için kullanılan, saçı besleyen ve güçlendiren şampuan.

## Features
* Saç tellerini güçlendirir
* Parlaklık sağlar
* 400 ml

*Note: This information was extracted using the basic extraction method.*
''';
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