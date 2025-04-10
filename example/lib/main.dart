import 'package:flutter/material.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
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
}