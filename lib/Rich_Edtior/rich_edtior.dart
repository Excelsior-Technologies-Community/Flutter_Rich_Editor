import 'package:flutter/material.dart';
import 'custom_rich_text_controller.dart';
import 'model.dart';
import 'package:image_picker/image_picker.dart';


class RichEditorDemo extends StatelessWidget {
  const RichEditorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: CustomRichEditor()));
  }
}

class CustomRichEditor extends StatefulWidget {
  const CustomRichEditor({super.key});

  @override
  State<CustomRichEditor> createState() => _CustomRichEditorState();
}

class _CustomRichEditorState extends State<CustomRichEditor> {

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImageFromGallery() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // insert placeholder text
    _insertInline('🖼 [image:${image.path}]');
  }
  Future<void> pickVideoFromGallery() async {
    final XFile? video =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    _insertInline('🎬 [video:${video.path}]');
  }
  void _showUrlDialog({
    required String title,
    required String hint,
    required String prefix,
  }) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _insertInline('$prefix${controller.text.trim()}]');
              }
              Navigator.pop(context);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }
  void insertYoutubeUrl() {
    _showUrlDialog(
      title: 'YouTube URL',
      hint: 'https://youtube.com/...',
      prefix: '▶️ [youtube:',
    );
  }

  void insertLinkUrl() {
    _showUrlDialog(
      title: 'Insert Link',
      hint: 'https://example.com',
      prefix: '🔗 [link:',
    );
  }

  Future<void> pickAudioFromGallery() async {
    final XFile? audio =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (audio == null) return;

    _insertInline('🎵 [audio:${audio.path}]');
  }


  final FocusNode _focusNode = FocusNode();
  final List<StyledChar> _chars = [];
  late RichTextController _controller;

  // inline (future typing)
  bool bold = false;
  bool italic = false;
  bool underline = false;
  Color currentTextColor = Colors.black;

  // block (future typing)
  double currentFontSize = 16;
  FontWeight currentFontWeight = FontWeight.normal;
  BlockAlign currentAlign = BlockAlign.left;

  final List<Color> _palette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.teal,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _controller = RichTextController(_chars);
    _controller.addListener(_onTextChanged);
  }

  bool get _hasSelection =>
      _controller.selection.start != _controller.selection.end;

  int _lineStart(int i) {
    final t = _controller.text;
    for (int x = i - 1; x >= 0; x--) {
      if (t[x] == '\n') return x + 1;
    }
    return 0;
  }

  int _lineEnd(int i) {
    final t = _controller.text;
    for (int x = i; x < t.length; x++) {
      if (t[x] == '\n') return x;
    }
    return t.length;
  }

  /* ================= TEXT CHANGE ================= */

  void _onTextChanged() {
    final t = _controller.text;

    // ENTER → continue list
    if (t.endsWith('\n') && t.length > 1) {
      final cur = _controller.selection.start;
      int s = cur - 2;
      while (s >= 0 && t[s] != '\n') s--;
      s++;
      final prev = t.substring(s, cur - 1);

      String ins = '';
      if (prev.startsWith('• ')) ins = '• ';
      final m = RegExp(r'^(\d+)\.\s').firstMatch(prev);
      if (m != null) ins = '${int.parse(m.group(1)!) + 1}. ';
      if (prev.startsWith('☐ ')) ins = '☐ ';

      if (ins.isNotEmpty) {
        _controller.text += ins;
        _chars.addAll(ins.split('').map((c) => StyledChar(c)));
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      }
    }

    if (_chars.length < t.length) {
      for (int i = _chars.length; i < t.length; i++) {
        _chars.add(
          StyledChar(
            t[i],
            bold: bold,
            italic: italic,
            underline: underline,
            color: currentTextColor,
            fontSize: currentFontSize,
            fontWeight: currentFontWeight,
            align: currentAlign,
          ),
        );
      }
    } else if (_chars.length > t.length) {
      _chars.removeRange(t.length, _chars.length);
    }
    setState(() {});
  }

  /* ================= INLINE ================= */

  void _applyToSelection({
    bool? bold,
    bool? italic,
    bool? underline,
    Color? color,
  }) {
    final sel = _controller.selection;
    for (int i = sel.start; i < sel.end && i < _chars.length; i++) {
      if (bold != null) _chars[i].bold = bold;
      if (italic != null) _chars[i].italic = italic;
      if (underline != null) _chars[i].underline = underline;
      if (color != null) _chars[i].color = color;
    }
    setState(() {});
  }

  /* ================= COLOR POPUP ================= */

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Text color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _palette
              .map((c) => GestureDetector(
            onTap: () {
              if (_hasSelection) {
                _applyToSelection(color: c);
              } else {
                currentTextColor = c;
              }
              Navigator.pop(context);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }

  /* ================= BLOCK ================= */

  void applyHeading(int level) {
    const sizes = {1: 32.0, 2: 28.0, 3: 24.0, 4: 20.0, 5: 18.0, 6: 16.0};
    if (_hasSelection) {
      final s = _lineStart(_controller.selection.start);
      final e = _lineEnd(_controller.selection.start);
      for (int i = s; i < e; i++) {
        _chars[i].fontSize = sizes[level]!;
        _chars[i].fontWeight = FontWeight.bold;
      }
    } else {
      currentFontSize = sizes[level]!;
      currentFontWeight = FontWeight.bold;
    }
    setState(() {});
  }

  void applyNormalText() {
    currentFontSize = 16;
    currentFontWeight = FontWeight.normal;
    setState(() {});
  }

  /* ================= JUSTIFY ================= */

  void applyAlignment(BlockAlign a) {
    if (_hasSelection) {
      final s = _lineStart(_controller.selection.start);
      final e = _lineEnd(_controller.selection.start);
      for (int i = s; i < e; i++) {
        _chars[i].align = a;
      }
    } else {
      currentAlign = a;
    }
    setState(() {});
  }

  TextAlign _currentTextAlign() {
    if (_chars.isEmpty) return TextAlign.left;
    final i =
    _controller.selection.start.clamp(0, _chars.length - 1);
    switch (_chars[i].align) {
      case BlockAlign.center:
        return TextAlign.center;
      case BlockAlign.right:
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  /* ================= INSERT HELPERS ================= */

  void _insertAtLineStart(String v) {
    final s = _lineStart(_controller.selection.start);
    _controller.text = _controller.text.replaceRange(s, s, v);
    _chars.insertAll(s, v.split('').map((c) => StyledChar(c)));
    _controller.selection =
        TextSelection.collapsed(offset: s + v.length);
  }

  void insertBullet() => _insertAtLineStart('• ');
  void insertNumber() => _insertAtLineStart('1. ');
  void insertCheckbox() => _insertAtLineStart('☐ ');
  void indent() => _insertAtLineStart('  ');
  void outdent() {
    final s = _lineStart(_controller.selection.start);
    if (_controller.text.startsWith('  ', s)) {
      _controller.text =
          _controller.text.replaceRange(s, s + 2, '');
      _chars.removeRange(s, s + 2);
    }
  }

  void _insertInline(String t) {
    final c = _controller.selection.start;
    _controller.text =
        _controller.text.replaceRange(c, c, t);
    _chars.insertAll(
      c,
      t.split('').map((x) => StyledChar(x)),
    );
    _controller.selection =
        TextSelection.collapsed(offset: c + t.length);
  }

  void insertImage() => _insertInline('🖼 [image:url]');
  void insertVideo() => _insertInline('🎬 [video:url]');
  void insertAudio() => _insertInline('🎵 [audio:url]');
  void insertYoutube() => _insertInline('▶️ [youtube:url]');
  void insertLink() => _insertInline('🔗 [link:url]');

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _toolbar(),
        Expanded(
          child: EditableText(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 16, height: 1.6),
            cursorColor: Colors.deepPurple,
            backgroundCursorColor: Colors.black,
            selectionColor: Colors.deepPurple.withOpacity(0.3),
            maxLines: null,
            textAlign: _currentTextAlign(),
          ),
        ),
      ],
    );
  }

  /* ================= TOOLBAR ================= */

  Widget _toolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _icon(Icons.format_bold,
                  () => _hasSelection
                  ? _applyToSelection(bold: true)
                  : setState(() => bold = !bold)),
          _icon(Icons.format_italic,
                  () => _hasSelection
                  ? _applyToSelection(italic: true)
                  : setState(() => italic = !italic)),
          _icon(Icons.format_underline,
                  () => _hasSelection
                  ? _applyToSelection(underline: true)
                  : setState(() => underline = !underline)),
          const VerticalDivider(),

          _icon(Icons.format_list_bulleted, insertBullet),
          _icon(Icons.format_list_numbered, insertNumber),
          _icon(Icons.check_box_outlined, insertCheckbox),
          const VerticalDivider(),

          _icon(Icons.format_indent_increase, indent),
          _icon(Icons.format_indent_decrease, outdent),
          const VerticalDivider(),

          _icon(Icons.format_align_left,
                  () => applyAlignment(BlockAlign.left)),
          _icon(Icons.format_align_center,
                  () => applyAlignment(BlockAlign.center)),
          _icon(Icons.format_align_right,
                  () => applyAlignment(BlockAlign.right)),
          const VerticalDivider(),

          _icon(Icons.image, pickImageFromGallery),
          _icon(Icons.videocam, pickVideoFromGallery),
          _icon(Icons.audiotrack, pickAudioFromGallery),
          _icon(Icons.play_circle_fill, insertYoutubeUrl),
          _icon(Icons.link, insertLinkUrl),

          const VerticalDivider(),

          _icon(Icons.format_color_text, _showColorPicker),
          const VerticalDivider(),

          _hBtn('P', applyNormalText),
          _hBtn('H1', () => applyHeading(1)),
          _hBtn('H2', () => applyHeading(2)),
          _hBtn('H3', () => applyHeading(3)),
          _hBtn('H4', () => applyHeading(4)),
          _hBtn('H5', () => applyHeading(5)),
          _hBtn('H6', () => applyHeading(6)),
        ],
      ),
    );
  }

  Widget _icon(IconData i, VoidCallback onTap) =>
      IconButton(icon: Icon(i), onPressed: onTap);

  Widget _hBtn(String t, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: OutlinedButton(onPressed: onTap, child: Text(t)),
  );
}




//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
//
// class CharacterData {
//   String char;
//   bool isBold;
//   bool isItalic;
//   bool isUnderline;
//   bool isStrikethrough;
//   Color color;
//   double fontSize;
//   bool isBulletPoint;
//   bool isNumberedPoint;
//
//   CharacterData({
//     required this.char,
//     this.isBold = false,
//     this.isItalic = false,
//     this.isUnderline = false,
//     this.isStrikethrough = false,
//     this.color = Colors.black,
//     this.fontSize = 16.0,
//     this.isBulletPoint = false,
//     this.isNumberedPoint = false,
//   });
//
//   CharacterData copyWith({
//     String? char,
//     bool? isBold,
//     bool? isItalic,
//     bool? isUnderline,
//     bool? isStrikethrough,
//     Color? color,
//     double? fontSize,
//     bool? isBulletPoint,
//     bool? isNumberedPoint,
//   }) {
//     return CharacterData(
//       char: char ?? this.char,
//       isBold: isBold ?? this.isBold,
//       isItalic: isItalic ?? this.isItalic,
//       isUnderline: isUnderline ?? this.isUnderline,
//       isStrikethrough: isStrikethrough ?? this.isStrikethrough,
//       color: color ?? this.color,
//       fontSize: fontSize ?? this.fontSize,
//       isBulletPoint: isBulletPoint ?? this.isBulletPoint,
//       isNumberedPoint: isNumberedPoint ?? this.isNumberedPoint,
//     );
//   }
//
//   TextStyle getStyle() {
//     return TextStyle(
//       fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//       fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
//       decoration: isUnderline
//           ? (isStrikethrough
//           ? TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough])
//           : TextDecoration.underline)
//           : (isStrikethrough ? TextDecoration.lineThrough : TextDecoration.none),
//       color: color,
//       fontSize: fontSize,
//     );
//   }
// }
//
// class RichTextEditorPage extends StatefulWidget {
//   const RichTextEditorPage({Key? key}) : super(key: key);
//
//   @override
//   State<RichTextEditorPage> createState() => _RichTextEditorPageState();
// }
//
// class _RichTextEditorPageState extends State<RichTextEditorPage> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//
//   List<CharacterData> _characters = [];
//
//   // Current formatting for new text
//   bool _isBold = false;
//   bool _isItalic = false;
//   bool _isUnderline = false;
//   bool _isStrikethrough = false;
//   Color _textColor = Colors.black;
//   double _fontSize = 16.0;
//   TextAlign _textAlign = TextAlign.left;
//   bool _isBulletList = false;
//   bool _isNumberedList = false;
//   int _listNumber = 1;
//
//   int _lastTextLength = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller.addListener(_onTextChanged);
//   }
//
//   @override
//   void dispose() {
//     _controller.removeListener(_onTextChanged);
//     _controller.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   void _onTextChanged() {
//     String text = _controller.text;
//     int currentLength = text.length;
//
//     if (currentLength > _lastTextLength) {
//       // Text added
//       String addedText = text.substring(_lastTextLength, currentLength);
//
//       // Check if Enter was pressed and we're in a list mode
//       if (addedText.contains('\n')) {
//         if (_isBulletList) {
//           // Auto-add bullet on new line
//           int cursorPos = _controller.selection.baseOffset;
//           String beforeCursor = text.substring(0, cursorPos);
//           String afterCursor = text.substring(cursorPos);
//
//           String newText = beforeCursor + '• ' + afterCursor;
//           _controller.text = newText;
//           _controller.selection = TextSelection.fromPosition(
//             TextPosition(offset: cursorPos + 2),
//           );
//           _lastTextLength = newText.length;
//           return;
//         } else if (_isNumberedList) {
//           // Auto-add number on new line
//           int cursorPos = _controller.selection.baseOffset;
//           String beforeCursor = text.substring(0, cursorPos);
//           String afterCursor = text.substring(cursorPos);
//
//           String newText = beforeCursor + '$_listNumber. ' + afterCursor;
//           _listNumber++;
//           _controller.text = newText;
//           _controller.selection = TextSelection.fromPosition(
//             TextPosition(offset: cursorPos + '$_listNumber. '.length),
//           );
//           _lastTextLength = newText.length;
//           return;
//         }
//       }
//
//       setState(() {
//         for (int i = 0; i < addedText.length; i++) {
//           _characters.add(CharacterData(
//             char: addedText[i],
//             isBold: _isBold,
//             isItalic: _isItalic,
//             isUnderline: _isUnderline,
//             isStrikethrough: _isStrikethrough,
//             color: _textColor,
//             fontSize: _fontSize,
//             isBulletPoint: _isBulletList,
//             isNumberedPoint: _isNumberedList,
//           ));
//         }
//       });
//     } else if (currentLength < _lastTextLength) {
//       // Text deleted
//       int deletedCount = _lastTextLength - currentLength;
//       setState(() {
//         for (int i = 0; i < deletedCount && _characters.isNotEmpty; i++) {
//           _characters.removeLast();
//         }
//       });
//     }
//
//     _lastTextLength = currentLength;
//   }
//
//   void _applyFormatToSelection() {
//     final selection = _controller.selection;
//     if (!selection.isValid || selection.start == selection.end) {
//       return;
//     }
//
//     int start = selection.start;
//     int end = selection.end;
//
//     setState(() {
//       for (int i = start; i < end && i < _characters.length; i++) {
//         _characters[i] = _characters[i].copyWith(
//           isBold: _isBold,
//           isItalic: _isItalic,
//           isUnderline: _isUnderline,
//           isStrikethrough: _isStrikethrough,
//           color: _textColor,
//           fontSize: _fontSize,
//         );
//       }
//     });
//   }
//
//   void _toggleBold() {
//     setState(() {
//       _isBold = !_isBold;
//     });
//     if (_hasSelection()) {
//       _applyFormatToSelection();
//     }
//   }
//
//   void _toggleItalic() {
//     setState(() {
//       _isItalic = !_isItalic;
//     });
//     if (_hasSelection()) {
//       _applyFormatToSelection();
//     }
//   }
//
//   void _toggleUnderline() {
//     setState(() {
//       _isUnderline = !_isUnderline;
//     });
//     if (_hasSelection()) {
//       _applyFormatToSelection();
//     }
//   }
//
//   void _toggleStrikethrough() {
//     setState(() {
//       _isStrikethrough = !_isStrikethrough;
//     });
//     if (_hasSelection()) {
//       _applyFormatToSelection();
//     }
//   }
//
//   void _toggleBulletList() {
//     setState(() {
//       _isBulletList = !_isBulletList;
//       _isNumberedList = false;
//
//       if (_isBulletList) {
//         // Add bullet point
//         String currentText = _controller.text;
//         String textToAdd = '';
//
//         if (currentText.isEmpty) {
//           textToAdd = '• ';
//         } else if (currentText.endsWith('\n')) {
//           textToAdd = '• ';
//         } else {
//           textToAdd = '\n• ';
//         }
//
//         int cursorPos = _controller.selection.baseOffset;
//         if (cursorPos == -1) cursorPos = currentText.length;
//
//         String newText = currentText.substring(0, cursorPos) +
//             textToAdd +
//             currentText.substring(cursorPos);
//
//         _controller.text = newText;
//         _controller.selection = TextSelection.fromPosition(
//           TextPosition(offset: cursorPos + textToAdd.length),
//         );
//         _lastTextLength = newText.length;
//       }
//     });
//   }
//
//   void _toggleNumberedList() {
//     setState(() {
//       _isNumberedList = !_isNumberedList;
//       _isBulletList = false;
//
//       if (_isNumberedList) {
//         // Add numbered point
//         String currentText = _controller.text;
//         String textToAdd = '';
//
//         if (currentText.isEmpty) {
//           textToAdd = '1. ';
//           _listNumber = 2;
//         } else if (currentText.endsWith('\n')) {
//           textToAdd = '$_listNumber. ';
//           _listNumber++;
//         } else {
//           textToAdd = '\n$_listNumber. ';
//           _listNumber++;
//         }
//
//         int cursorPos = _controller.selection.baseOffset;
//         if (cursorPos == -1) cursorPos = currentText.length;
//
//         String newText = currentText.substring(0, cursorPos) +
//             textToAdd +
//             currentText.substring(cursorPos);
//
//         _controller.text = newText;
//         _controller.selection = TextSelection.fromPosition(
//           TextPosition(offset: cursorPos + textToAdd.length),
//         );
//         _lastTextLength = newText.length;
//       } else {
//         _listNumber = 1;
//       }
//     });
//   }
//
//   void _changeColor(Color color) {
//     setState(() {
//       _textColor = color;
//     });
//     if (_hasSelection()) {
//       _applyFormatToSelection();
//     }
//     Navigator.of(context).pop();
//   }
//
//   void _insertImage() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Insert Image'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               decoration: const InputDecoration(
//                 labelText: 'Image URL',
//                 hintText: 'https://example.com/image.jpg',
//                 border: OutlineInputBorder(),
//               ),
//               onSubmitted: (url) {
//                 if (url.isNotEmpty) {
//                   _controller.text += '\n[Image: $url]\n';
//                   Navigator.pop(context);
//                 }
//               },
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _insertLink() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Insert Link'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               decoration: const InputDecoration(
//                 labelText: 'Link Text',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {},
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               decoration: const InputDecoration(
//                 labelText: 'URL',
//                 hintText: 'https://example.com',
//                 border: OutlineInputBorder(),
//               ),
//               onSubmitted: (url) {
//                 if (url.isNotEmpty) {
//                   _controller.text += '[Link: $url] ';
//                   Navigator.pop(context);
//                 }
//               },
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   bool _hasSelection() {
//     final selection = _controller.selection;
//     return selection.isValid && selection.start != selection.end;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text('Rich Text Editor'),
//         backgroundColor: const Color(0xFF7E57C2),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save_outlined),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Content saved!')),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildToolbar(),
//           Expanded(
//             child: Container(
//               color: Colors.white,
//               child: Stack(
//                 children: [
//                   // Formatted text display
//                   if (_characters.isNotEmpty)
//                     Positioned.fill(
//                       child: SingleChildScrollView(
//                         padding: const EdgeInsets.all(16),
//                         child: RichText(
//                           textAlign: _textAlign,
//                           text: TextSpan(
//                             children: _characters.map((charData) {
//                               return TextSpan(
//                                 text: charData.char,
//                                 style: charData.getStyle(),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//                     ),
//                   // Input field
//                   Positioned.fill(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Opacity(
//                         opacity: 0.01, // 👈 VERY IMPORTANT (not 0, not transparent)
//                         child: TextField(
//                           controller: _controller,
//                           focusNode: _focusNode,
//                           maxLines: null,
//                           expands: true,
//                           textAlign: _textAlign,
//                           cursorColor: Colors.black, // cursor visible
//                           style: TextStyle(
//                             fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
//                             fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
//                             decoration:
//                             _isUnderline ? TextDecoration.underline : TextDecoration.none,
//                             fontSize: _fontSize,
//                           ),
//                           decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: '',
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildToolbar() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             _buildToolbarIconButton(
//               icon: Icons.format_bold,
//               isActive: _isBold,
//               onPressed: _toggleBold,
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_italic,
//               isActive: _isItalic,
//               onPressed: _toggleItalic,
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_underline,
//               isActive: _isUnderline,
//               onPressed: _toggleUnderline,
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.strikethrough_s,
//               isActive: _isStrikethrough,
//               onPressed: _toggleStrikethrough,
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_list_bulleted,
//               isActive: _isBulletList,
//               onPressed: _toggleBulletList,
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_list_numbered,
//               isActive: _isNumberedList,
//               onPressed: _toggleNumberedList,
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_align_left,
//               isActive: _textAlign == TextAlign.left,
//               onPressed: () => setState(() => _textAlign = TextAlign.left),
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_align_center,
//               isActive: _textAlign == TextAlign.center,
//               onPressed: () => setState(() => _textAlign = TextAlign.center),
//             ),
//             _buildToolbarIconButton(
//               icon: Icons.format_align_right,
//               isActive: _textAlign == TextAlign.right,
//               onPressed: () => setState(() => _textAlign = TextAlign.right),
//             ),
//             const SizedBox(width: 8),
//             // Color Picker
//             _buildToolbarIconButton(
//               icon: Icons.color_lens,
//               isActive: false,
//               onPressed: _showColorPicker,
//             ),
//             // Image Insert
//             _buildToolbarIconButton(
//               icon: Icons.image,
//               isActive: false,
//               onPressed: _insertImage,
//             ),
//             // Link Insert
//             _buildToolbarIconButton(
//               icon: Icons.link,
//               isActive: false,
//               onPressed: _insertLink,
//             ),
//             const SizedBox(width: 8),
//             PopupMenuButton<String>(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey[300]!),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('H1', style: TextStyle(fontWeight: FontWeight.bold)),
//                     Icon(Icons.arrow_drop_down, size: 20),
//                   ],
//                 ),
//               ),
//               onSelected: (value) {
//                 setState(() {
//                   switch (value) {
//                     case 'H1':
//                       _fontSize = 32;
//                       _isBold = true;
//                       break;
//                     case 'H2':
//                       _fontSize = 24;
//                       _isBold = true;
//                       break;
//                     case 'H3':
//                       _fontSize = 20;
//                       _isBold = true;
//                       break;
//                     case 'Normal':
//                       _fontSize = 16;
//                       _isBold = false;
//                       break;
//                   }
//                 });
//                 if (_hasSelection()) {
//                   _applyFormatToSelection();
//                 }
//               },
//               itemBuilder: (context) => [
//                 const PopupMenuItem(value: 'H1', child: Text('Heading 1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
//                 const PopupMenuItem(value: 'H2', child: Text('Heading 2', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
//                 const PopupMenuItem(value: 'H3', child: Text('Heading 3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
//                 const PopupMenuItem(value: 'Normal', child: Text('Normal', style: TextStyle(fontSize: 16))),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolbarIconButton({
//     required IconData icon,
//     required bool isActive,
//     required VoidCallback onPressed,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(4),
//         child: Container(
//           padding: const EdgeInsets.all(10),
//           child: Icon(
//             icon,
//             size: 22,
//             color: isActive ? const Color(0xFF7E57C2) : const Color(0xFF424242),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showColorPicker() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Choose Color'),
//         content: Wrap(
//           spacing: 12,
//           runSpacing: 12,
//           children: [
//             Colors.black,
//             Colors.red,
//             Colors.blue,
//             Colors.green,
//             Colors.orange,
//             Colors.purple,
//             Colors.pink,
//             Colors.teal,
//             Colors.brown,
//             Colors.indigo,
//             Colors.amber,
//             Colors.cyan,
//             Colors.deepOrange,
//             Colors.lime,
//             Colors.grey,
//           ].map((color) {
//             bool isSelected = _textColor == color;
//             return GestureDetector(
//               onTap: () => _changeColor(color),
//               child: Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: color,
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: isSelected ? Colors.white : Colors.grey[300]!,
//                     width: isSelected ? 4 : 2,
//                   ),
//                   boxShadow: [
//                     if (isSelected)
//                       BoxShadow(
//                         color: color.withOpacity(0.5),
//                         blurRadius: 8,
//                         spreadRadius: 2,
//                       ),
//                   ],
//                 ),
//                 child: isSelected
//                     ? const Icon(Icons.check, color: Colors.white, size: 20)
//                     : null,
//               ),
//             );
//           }).toList(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }
