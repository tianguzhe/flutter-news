import 'package:flutter/material.dart';

// Matches digit sequences optionally joined by decimal/thousands separators.
final _numRegex = RegExp(r'\d+(?:[.,]\d+)*');

/// Renders [data] with digit sequences in the Mogra font; all other
/// characters inherit the default or [style] font.
class NumText extends StatelessWidget {
  const NumText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final inherited = DefaultTextStyle.of(context);
    final base = inherited.style.merge(style);
    final numStyle = base.copyWith(fontFamily: 'Mogra', fontFamilyFallback: []);

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _numRegex.allMatches(data)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: data.substring(cursor, match.start), style: base));
      }
      spans.add(TextSpan(text: match.group(0), style: numStyle));
      cursor = match.end;
    }
    if (cursor < data.length) {
      spans.add(TextSpan(text: data.substring(cursor), style: base));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines ?? inherited.maxLines,
      overflow: overflow ?? inherited.overflow,
      textAlign: textAlign,
    );
  }
}