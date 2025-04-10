import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikzak_html_to_markdown/html_to_markdown.dart';

void main() {
  group('HtmlToMarkdown', () {
    testWidgets('convertUrlToMarkdown should convert pub.dev page', (tester) async {
      // Build a minimal app to provide context
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final markdown = await HtmlToMarkdown.convertUrlToMarkdown(
                  context,
                  'https://pub.dev/packages/html2md',
                );
                expect(markdown, contains('# html2md'));
                expect(markdown, contains('## Installing'));
                expect(markdown, contains('```yaml'));
                expect(markdown, contains('dependencies:'));
              },
              child: const Text('Convert'),
            ),
          ),
        ),
      );

      // Trigger the conversion
      await tester.tap(find.text('Convert'));
      await tester.pumpAndSettle();
    });

    testWidgets('convertUrlToMarkdown should handle errors gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                expect(
                  () => HtmlToMarkdown.convertUrlToMarkdown(
                    context,
                    'https://invalid.url.example',
                  ),
                  throwsA(isA<Exception>()),
                );
              },
              child: const Text('Convert'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Convert'));
      await tester.pumpAndSettle();
    });
  });
}