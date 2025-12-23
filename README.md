# 📝 Custom Flutter Rich Text Editor

A **lightweight, fully custom rich text editor built in Flutter** using
`EditableText` and a character-level styling model.

This editor supports **inline formatting, block formatting, lists, alignment,
headings, colors, and rich media placeholders (image, video, audio, YouTube, links)** —
all without using WebView or HTML.

---

## ✨ Features

### Inline Formatting
- Bold
- Italic
- Underline
- Text color
- Per-character styling

### Block Formatting
- Headings (H1 – H6)
- Normal paragraph text
- Left / Center / Right alignment
- Indentation & outdentation

### Lists
- Bullet list (`•`)
- Numbered list (`1.` auto-increment on Enter)
- Checkbox list (`☐`)

### Rich Media Placeholders
- 🖼 Image (gallery picker)
- 🎬 Video (gallery picker)
- 🎵 Audio
- ▶️ YouTube URL
- 🔗 External links

> Media is inserted as **inline placeholders**, making it easy to later render
or export as HTML / Markdown / JSON.

---
## ✨ Preview



https://github.com/user-attachments/assets/b44f0447-b3ec-44ef-aa75-a4d74df9fa76






---


##  Installation
Add this to your package's pubspec.yaml file:
```
dependencies:
  flutter_rich_editor:
    path: ../flutter_rich_editor
```
from git:
```
dependencies:
  flutter_rich_editor:
    git:
      url: https://github.com/yourusername/flutter_rich_editor.git

```
Then Run:
```
flutter pub get
```

## 📚 Dependencies Used
```
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.0

```
## 📦 Required Permissions
```
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

```
## 📁 Folder Structure
```
flutter_rich_editor/
│
├── lib/
│   │
│   ├── flutter_rich_editor.dart      # Package export file
│   ├── model.dart                    # StyledChar model
│   ├── custom_rich_text_controller.dart # RichTextController
│   └── rich_editor.dart              # CustomRichEditor widget
│
├── example/
│   └── rich_editor_demo.dart          # Demo screen
│
└── README.md

  ```


## 1️⃣ StyledChar Model

Each character in the editor is represented by a StyledChar.
```
class StyledChar {
  String char;
  bool bold;
  bool italic;
  bool underline;

  Color color;
  Color? backgroundColor;
  double fontSize;
  FontWeight fontWeight;

  bool isBlockQuote;
  BlockAlign align;
}

```
## 2️⃣ RichTextController

Custom TextEditingController that renders text using TextSpan.
```
class RichTextController extends TextEditingController {
  final List<StyledChar> chars;

  @override
  TextSpan buildTextSpan(...) {
    return TextSpan(
      children: chars.map(
        (c) => TextSpan(
          text: c.char,
          style: baseStyle.merge(c.style),
        ),
      ).toList(),
    );
  }
}


```
## 3️⃣ CustomRichEditor Widget
```
EditableText(
  controller: _controller,
  focusNode: _focusNode,
  textAlign: _currentTextAlign(),
  maxLines: null,
)

```
## 🎛 Toolbar Actions


| Action        | Description             |
| ------------- | ----------------------- |
| **B / I / U** | Bold, Italic, Underline |
| 🎨            | Text color picker       |
| •             | Bullet list             |
| 1.            | Numbered list           |
| ☐             | Checkbox                |
| ⬅ ➡           | Indent / Outdent        |
| ⬅ ⬍ ➡         | Text alignment          |
| 🖼 🎬 🎵      | Image / Video / Audio   |
| ▶️            | YouTube URL             |
| 🔗            | External link           |
| H1–H6         | Headings                |

## 🎥 Media Insertion Format
```
🖼 [image:/path/to/image.jpg]
🎬 [video:/path/to/video.mp4]
🎵 [audio:/path/to/audio.mp3]
▶️ [youtube:https://youtube.com/...]
🔗 [link:https://example.com]

```
## 📜 License
MIT License
```
Copyright (c) 2025 Excelsior Technologies

Permission is hereby granted, free of charge, to any person obtaining a copy  
of this software and associated documentation files (the "Software"), to deal  
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell  
copies of the Software, and to permit persons to whom the Software is  
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all  
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```
