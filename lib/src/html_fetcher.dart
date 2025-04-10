import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';

class HtmlFetcher extends StatefulWidget {
  final String url;
  final Function(String) onComplete;
  final Function(Exception) onError;

  const HtmlFetcher({
    Key? key,
    required this.url,
    required this.onComplete,
    required this.onError,
  }) : super(key: key);

  @override
  State<HtmlFetcher> createState() => _HtmlFetcherState();
}

class _HtmlFetcherState extends State<HtmlFetcher> {
  bool _hasCompleted = false;
  String _status = 'Initializing...';

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(_status, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _hasCompleted ? 1.0 : null),
              ],
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) {
                print('WebView created');
                _updateStatus('Loading webpage...');
              },
              onLoadStart: (controller, uri) {
                print('Page load started: $uri');
                _updateStatus('Loading content from ${uri?.host ?? "website"}...');
              },
              onLoadStop: (controller, uri) async {
                print('Page load stopped: $uri');
                _updateStatus('Extracting content...');
                if (uri == WebUri(widget.url) && !_hasCompleted) {
                  try {
                    print('Evaluating JavaScript to get HTML content');
                    final content = await controller.evaluateJavascript(
                        source: 'document.documentElement.outerHTML;');
                    print('Successfully retrieved HTML content');
                    _hasCompleted = true;
                    if (mounted) {
                      _updateStatus('Converting to Markdown...');
                      await Future.delayed(const Duration(milliseconds: 100));
                      Navigator.of(context).pop();
                      widget.onComplete(content ?? '');
                    }
                  } catch (e) {
                    print('Error evaluating JavaScript: $e');
                    if (!_hasCompleted && mounted) {
                      _hasCompleted = true;
                      Navigator.of(context).pop();
                      widget.onError(Exception('Failed to evaluate JavaScript: $e'));
                    }
                  }
                }
              },
              onLoadError: (controller, uri, code, message) {
                print('Load error: code=$code, message=$message, uri=$uri');
                if (!_hasCompleted && mounted) {
                  _hasCompleted = true;
                  _updateStatus('Error loading page: $message');
                  Navigator.of(context).pop();
                  widget.onError(Exception('Failed to load page: $message'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}