/// VYRO AI — Premium AI chat markdown renderer
///
/// Renders assistant responses with the Vyro AI design system:
/// headings, bold/italic, lists, tables, inline code and dark
/// syntax-highlighted code blocks with a language label, copy button and
/// horizontal scrolling for long lines.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

class ChatMarkdown extends StatelessWidget {
  final String data;
  const ChatMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      syntaxHighlighter: _VyroHighlighter(),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14.5,
          height: 1.55,
          fontFamily: 'Inter',
        ),
        h1: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          height: 1.3,
        ),
        h2: const TextStyle(
          color: Colors.white,
          fontSize: 17.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          height: 1.3,
        ),
        h3: const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
          height: 1.3,
        ),
        h1Padding: const EdgeInsets.only(top: 8, bottom: 6),
        h2Padding: const EdgeInsets.only(top: 8, bottom: 5),
        h3Padding: const EdgeInsets.only(top: 6, bottom: 4),
        strong: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
        em: const TextStyle(fontStyle: FontStyle.italic),
        listBullet: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14.5,
          height: 1.55,
          fontFamily: 'Inter',
        ),
        code: TextStyle(
          color: const Color(0xFF7DD3FC),
          backgroundColor: const Color(0xFF17243B).withValues(alpha: 0.9),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0A1120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF263750)),
        ),
        blockquote: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          height: 1.5,
          fontFamily: 'Inter',
        ),
        blockquoteDecoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: Color(0xFF8855FF), width: 3),
          ),
          color: const Color(0xFF8855FF).withValues(alpha: 0.08),
        ),
        tableHead: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          fontFamily: 'Inter',
        ),
        tableBody: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 13.5,
          fontFamily: 'Inter',
        ),
        tableBorder: TableBorder.all(
          color: const Color(0xFF263750),
          width: 1,
          borderRadius: BorderRadius.circular(8),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        a: const TextStyle(color: Color(0xFF00D5FF)),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF263750).withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
      builders: {
        'pre': _CodeBlockBuilder(),
      },
    );
  }
}

// ============================================================================
// CODE BLOCK — dark container, language label, copy button, horizontal scroll
// ============================================================================

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Fenced blocks: <pre><code class="language-xyz">…</code></pre>
    final codeChild = element.children?.isNotEmpty == true
        ? element.children!.first
        : null;
    String code = '';
    String language = '';
    if (codeChild is md.Text) {
      code = codeChild.text.trimRight();
    } else if (codeChild is md.Element) {
      code = codeChild.children
              ?.whereType<md.Text>()
              .map((t) => t.text)
              .join()
              .trimRight() ??
          '';
      final cls = codeChild.attributes['class'] ?? '';
      if (cls.contains('language-')) {
        language = cls.split('language-').last.trim();
      }
    }
    if (element.attributes['language'] != null) {
      language = element.attributes['language']!;
    }

    return _CodeBlock(code: code, language: language);
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  const _CodeBlock({required this.code, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF263750)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF101B35),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8855FF).withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    language.isEmpty ? 'code' : language,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _CopyCodeButton(code: code),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: SelectableText(
              code,
              style: TextStyle(
                color: const Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.55,
                fontFamily: 'monospace',
                // keep the syntax palette readable on the dark container
                backgroundColor: const Color(0xFF0A1120),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyCodeButton extends StatefulWidget {
  final String code;
  const _CopyCodeButton({required this.code});

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy_rounded,
              size: 14,
              color: _copied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              _copied ? 'Copied' : 'Copy',
              style: TextStyle(
                color: _copied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LIGHTWEIGHT SYNTAX HIGHLIGHTER — keywords, strings, comments, numbers
// ============================================================================

class _VyroHighlighter extends SyntaxHighlighter {
  static const _keywordColor = Color(0xFFC084FC); // violet
  static const _stringColor = Color(0xFF86EFAC); // green
  static const _commentColor = Color(0xFF64748B); // slate
  static const _numberColor = Color(0xFFFBBF24); // amber
  static const _baseColor = Color(0xFFCBD5E1);

  @override
  TextSpan format(String source) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/)' // comments
      r'|("(?:[^"\\]|\\.)*")' // double-quoted strings
      r"|('(?:[^'\\]|\\.)*')" // single-quoted strings
      r'|\b(0x[0-9a-fA-F]+|\d+(?:\.\d+)?)\b' // numbers
      r'|\b(const|var|let|function|return|if|else|for|while|class|new|import|export|from|async|await|def|public|private|static|void|int|float|double|String|bool|true|false|null|self|this|try|catch|except|finally|with|as|in|not|and|or)\b',
      multiLine: true,
    );

    var last = 0;
    for (final m in pattern.allMatches(source)) {
      if (m.start > last) {
        spans.add(TextSpan(text: source.substring(last, m.start)));
      }
      final text = m.group(0)!;
      Color color;
      if (m.group(1) != null) {
        color = _commentColor;
      } else if (m.group(2) != null) {
        color = _stringColor;
      } else if (m.group(3) != null) {
        color = _numberColor;
      } else {
        color = _keywordColor;
      }
      spans.add(TextSpan(text: text, style: TextStyle(color: color)));
      last = m.end;
    }
    if (last < source.length) {
      spans.add(TextSpan(text: source.substring(last)));
    }
    return TextSpan(
      style: TextStyle(color: _baseColor, fontSize: 12.5, height: 1.55, fontFamily: 'monospace'),
      children: spans,
    );
  }
}
