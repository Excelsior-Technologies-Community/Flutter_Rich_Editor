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





