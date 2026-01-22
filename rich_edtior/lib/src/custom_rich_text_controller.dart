import 'package:flutter/material.dart';
import 'model.dart';

class RichTextController extends TextEditingController {
  final List<StyledChar> chars;

  RichTextController(this.chars);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(fontSize: 16, height: 1.9);

    return TextSpan(
      style: baseStyle,
      children: chars
          .map((c) => TextSpan(text: c.char, style: baseStyle.merge(c.style)))
          .toList(),
    );
  }
}
