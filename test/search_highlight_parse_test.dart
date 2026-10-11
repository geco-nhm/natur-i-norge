import 'package:flutter/material.dart';
import 'package:naturinorge_guide/src/search/search_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('highlightTextSpans marks matched tokens', () {
    const style = TextStyle(fontSize: 16);
    const text = 'ettersuksesjonsstadiet være NA-TB01 fastmarkskogmark';
    final spans = highlightTextSpans(text, 'NA-TB01', style);

    final highlighted = spans.where(
      (span) => span is TextSpan && span.style?.backgroundColor != null,
    );
    expect(highlighted.length, 1);
    expect((highlighted.first as TextSpan).text, 'NA-TB01');
  });
}
