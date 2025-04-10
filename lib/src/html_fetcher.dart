import 'package:flutter/material.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';

/// A widget that fetches HTML content from a URL using an embedded web view.
class HtmlFetcher extends StatefulWidget {
  final String url;
  final Function(String) onComplete;
  final Function(String) onError;

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
  bool _loading = true;
  String _progressText = 'Loading...';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Fetching content from:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.url,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_loading)
            Column(
              children: [
                LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                const SizedBox(height: 8),
                Text(_progressText),
              ],
            ),
          Opacity(
            opacity: 0.01, // Nearly invisible
            child: SizedBox(
              height: 1, // Very small height
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                onWebViewCreated: (controller) {
                  print('WebView created for URL: ${widget.url}');
                },
                onLoadStop: (controller, url) async {
                  print('Page loaded: $url');
                  setState(() {
                    _progressText = 'Extracting content...';
                    _progress = 0.8;
                  });
                  
                  try {
                    // Get the HTML content
                    final html = await controller.evaluateJavascript(
                      source: "document.documentElement.outerHTML.toString()"
                    );
                    
                    if (html != null && html.isNotEmpty) {
                      widget.onComplete(html);
                    } else {
                      widget.onError('Failed to extract HTML content');
                    }
                  } catch (e) {
                    print('Error extracting HTML: $e');
                    widget.onError('Error: $e');
                  }
                },
                onReceivedError: (controller, request, error) {
                  print('Error loading page: ${error.description}');
                  widget.onError('Error loading page: ${error.description}');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}