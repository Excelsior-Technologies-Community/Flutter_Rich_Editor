import 'package:flutter/material.dart';

enum BlockAlign { left, center, right }

class StyledChar {
  String char;

  bool bold;
  bool italic;
  bool underline;

  Color color;
  Color? backgroundColor; // ✅ ADD
  double fontSize;
  FontWeight fontWeight;
  bool isBlockQuote;
  BlockAlign align;

  StyledChar(
      this.char, {
        this.bold = false,
        this.italic = false,
        this.underline = false,
        this.color = Colors.black,
        this.backgroundColor, // ✅
        this.fontSize = 16,
        this.fontWeight = FontWeight.normal,
        this.isBlockQuote = false,
        this.align = BlockAlign.left,
      });

  TextStyle get style => TextStyle(
    fontSize: fontSize,
    fontWeight: bold ? FontWeight.bold : fontWeight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    decoration:
    underline ? TextDecoration.underline : TextDecoration.none,
    color: isBlockQuote ? Colors.grey : color,
    backgroundColor: backgroundColor, // ✅
    height: 1.6,
  );
}
