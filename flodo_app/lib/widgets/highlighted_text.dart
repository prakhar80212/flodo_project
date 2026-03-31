import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;        // full task title
  final String query;       // what the user typed
  final TextStyle? baseStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    // If nothing is searched, just render the text normally
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    // Case-insensitive search — convert both to lowercase for matching
    final lowerText  = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // Find all match positions
    final spans = <TextSpan>[];
    int start = 0;
    int matchStart;

    while ((matchStart = lowerText.indexOf(lowerQuery, start)) != -1) {
      final matchEnd = matchStart + lowerQuery.length;
      if (matchStart > start) spans.add(TextSpan(text: text.substring(start, matchStart)));
      spans.add(TextSpan(
        text: text.substring(matchStart, matchEnd),
        style: const TextStyle(
          backgroundColor: Color(0xFFE8EAF6),
          color: Color(0xFF283593),
          fontWeight: FontWeight.w700,
        ),
      ));
      start = matchEnd;
    }

    if (spans.isEmpty) return Text(text, style: baseStyle);
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));

    return RichText(
      text: TextSpan(
        style: baseStyle ?? DefaultTextStyle.of(context).style,
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}