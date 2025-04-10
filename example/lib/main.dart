import 'package:flutter/material.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Import for platform detection
import 'dart:io' show Platform;

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

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://flutter.dev/';
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
      // First check if an on-device model is available
      final modelAvailable = await HtmlToMarkdown.isOnDeviceModelAvailable();
      final modelStatus = modelAvailable 
          ? "Using on-device AI model for enhanced conversion"
          : "No AI model available, using enhanced formatting only";
          
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
      final markdown = await HtmlToMarkdown.convertUrlToMarkdownWithAI(context, url);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      setState(() {
        _markdown = "<!-- Conversion completed in ${duration.inMilliseconds}ms" +
                   "\nAI Model available: $modelAvailable -->\n\n" + markdown;
      });
    } catch (e) {
      _showError('Error during AI conversion: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  // Add new method for downloading models
  Future<void> _downloadGemmaModel() async {
    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      final modelUrl = 'https://huggingface.co/google/gemma-2b-it/resolve/main/tokenizer.json';
      
      setState(() {
        _downloadingModel = true;
        _downloadProgress = 0;
        _modelStatus = 'Starting download...';
      });
      
      try {
        // Check if model is already downloaded
        final isAlreadyAvailable = await HtmlToMarkdown.isOnDeviceModelAvailable();
        if (isAlreadyAvailable) {
          setState(() {
            _modelStatus = 'Model is already installed and ready to use!';
          });
          return;
        }
        
        // Access the plugin through our wrapper
        await HtmlToMarkdown.downloadModel(
          modelUrl: modelUrl,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
              _modelStatus = 'Downloading: ${progress.toStringAsFixed(1)}%';
            });
          },
        );
        
        setState(() {
          _modelStatus = 'Model installed successfully!';
        });
        
        // Force model to be registered as available
        await HtmlToMarkdown.registerModelAsAvailable(true);
        
        // Check model availability again - should be true now
        final available = await HtmlToMarkdown.isOnDeviceModelAvailable();
        setState(() {
          _modelStatus += '\nModel available: $available';
        });
        
        // Refresh UI to show updated model status
        setState(() {});
      } catch (e) {
        setState(() {
          _modelStatus = 'Error downloading model: $e';
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
  
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
            
            // Add model download section
            FutureBuilder<bool>(
              future: HtmlToMarkdown.isOnDeviceModelAvailable(),
              builder: (context, snapshot) {
                final modelAvailable = snapshot.data ?? false;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Replace the Row with Wrap to fix overflow
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
                                onPressed: _downloadGemmaModel,
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
                'This app offers three conversion methods:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Convert HTML - Directly converts HTML text to Markdown'),
              const Text('2. Convert URL to Markdown - Fetches a webpage and converts it to Markdown'),
              const Text('3. Convert with AI - Uses on-device Gemma model for enhanced conversion if available'),
              const SizedBox(height: 16),
              const Text(
                'AI Enhancement Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: HtmlToMarkdown.isOnDeviceModelAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  
                  final available = snapshot.data ?? false;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        available 
                            ? '✅ Gemma 2B Model Active' 
                            : '❌ Gemma model not available',
                        style: TextStyle(
                          color: available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        available 
                            ? 'The AI conversion will use Google\'s Gemma 2B-IT on-device model to enhance your markdown.'
                            : 'Download the model to enable AI-powered markdown conversion for better results.'
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