# ZikZak HTML to Markdown

A Flutter package for converting HTML content to clean, structured Markdown.

## Features

- Convert HTML from any URL to clean, readable Markdown
- Visual loading UI with progress indication
- Optional AI-powered conversion using local Ollama models
- Simple API with just a few method calls
- Fallback to standard conversion if AI model is unavailable

## Getting Started

Add this package to your Flutter project:

```yaml
dependencies:
  zikzak_html_to_markdown: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';

Future<void> convertUrl() async {
  final markdown = await HtmlToMarkdown.convertUrlToMarkdown(
    context,
    'https://pub.dev/packages/html2md',
  );
  
  print(markdown);
}
```

### AI-Powered Conversion

For improved conversion quality with semantic understanding, you can use the AI-powered conversion that leverages local Ollama models:

1. First, [install Ollama](https://ollama.ai/download) on your machine
2. Start the Ollama server
3. Use the AI-powered conversion method:

```dart
final markdown = await HtmlToMarkdown.convertUrlToMarkdownWithAI(
  context,
  'https://flutter.dev/docs',
  ollamaServerUrl: 'http://localhost:11434',
  modelName: 'mistral', // or any other model you've pulled with Ollama
);
```

## How it Works

The package works in two steps:

1. **Content Fetching**: Uses an embedded InAppWebView to load the page, ensuring all JavaScript and dynamic content is properly rendered.

2. **Conversion**: 
   - **Standard conversion**: Uses a custom HTML parser to convert the content to markdown.
   - **AI-powered conversion**: Uses a local Ollama model to intelligently convert the HTML content to well-structured markdown with improved semantic understanding.

## Example

The included example app demonstrates both standard and AI-powered conversion:

```dart
import 'package:flutter/material.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('HTML to Markdown')),
        body: Center(
          child: ElevatedButton(
            child: Text('Convert'),
            onPressed: () async {
              final markdown = await HtmlToMarkdown.convertUrlToMarkdown(
                context,
                'https://pub.dev/packages/html2md',
              );
              
              // Use the markdown...
            },
          ),
        ),
      ),
    );
  }
}
```

## Requirements

- Flutter SDK: >=3.0.0 <4.0.0
- For AI-powered conversion: Ollama installed and running locally

## License

MIT