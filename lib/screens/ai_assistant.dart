/// VYRO AI — AI Assistant Screen
///
/// Premium chat experience: real AI responses (OpenAI with free Pollinations
/// fallback), smooth typewriter reveal, thinking indicator, message actions
/// (copy / regenerate / share / speak / like / dislike), rich markdown with
/// syntax-highlighted code blocks, image attachments, auto-scroll and a fixed
/// bottom composer — all in the Vyro AI dark design system.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/branding.dart';
import '../widgets/chat_markdown.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/chat_store.dart';
import '../../core/services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  /// When true, renders without its own Scaffold/AppBar so it can be
  /// embedded inside the home dashboard's bottom-navigation shell.
  const AiAssistantScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final ChatService _chat = ChatService.instance;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<ChatTurn> _messages = [];
  final Set<int> _liked = {};
  final Set<int> _disliked = {};
  final Map<int, String> _revealing =
      {}; // index -> currently revealed characters

  bool _sending = false;
  bool _speaking = false;
  String? _error;
  Uint8List? _attachedBytes;
  String _attachedName = '';

  Timer? _revealTimer;
  int _revealTarget = -1;

  @override
  void initState() {
    super.initState();
    _restoreChat();
  }

  /// Restores the last conversation from Firestore (per-user). Falls back
  /// to the friendly welcome message for fresh users.
  Future<void> _restoreChat() async {
    final saved = await ChatStore.load();
    if (!mounted) return;
    setState(() {
      if (saved.isEmpty) {
        _messages.add(ChatTurn(
          role: 'assistant',
          content: "Hi! I'm **Vyro AI Assistant** — your creative copilot for "
              'videos, reels and images.\n\n'
              'Try asking:\n'
              '- *Give me 5 viral reel ideas*\n'
              '- *Write a prompt for a cinematic drone shot*\n'
              '- *Draft a 30-second script with a hook*',
        ));
      } else {
        _messages.addAll(saved);
      }
    });
    _scrollToBottom();
  }

  /// Starts a fresh conversation (New Chat). Clears the persisted session.
  Future<void> _newChat() async {
    if (_sending) _chat.cancelCurrent();
    _revealTimer?.cancel();
    _revealing.clear();
    _liked.clear();
    _disliked.clear();
    await ChatStore.clear();
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _error = null;
      _sending = false;
      _messages.add(ChatTurn(
        role: 'assistant',
        content: "Fresh start! ✨ I'm **Vyro AI Assistant** — tell me what "
            'you want to create:\n'
            '- *Viral reel ideas*\n'
            '- *Cinematic video prompts*\n'
            '- *Scripts with hooks*',
      ));
    });
  }

  /// Stops the in-flight generation. The pending request is cancelled and
  /// the conversation keeps everything produced so far — nothing fake.
  void _stopGeneration() {
    _chat.cancelCurrent();
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==========================================================================
  // SEND / RECEIVE
  // ==========================================================================

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final attachmentNote = _attachedBytes != null
        ? '\n\n_[attached image: $_attachedName]_'
        : '';
    setState(() {
      _messages.add(ChatTurn(
        role: 'user',
        content: '$text$attachmentNote',
        attachedBytes: _attachedBytes,
        attachedName: _attachedName,
      ));
      _inputCtrl.clear();
      _attachedBytes = null;
      _attachedName = '';
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      // The API call excludes ephemeral UI-only error bubbles.
      final apiHistory = _messages
          .where((m) => !m.isError && m.content.isNotEmpty)
          .toList();
      unawaited(ChatStore.save(apiHistory));
      final reply = await _chat.sendMessage(apiHistory);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatTurn(role: 'assistant', content: reply));
        _sending = false;
      });
      unawaited(ChatStore.save(_messages));
      _startReveal(_messages.length - 1);
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.cancel) {
        // User pressed Stop — keep history, no error card, nothing fake.
        setState(() => _sending = false);
        return;
      }
      setState(() {
        _error = 'Assistant request failed (network). Please try again.';
        _sending = false;
      });
    } on ChatServiceError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Assistant failed: $e';
        _sending = false;
      });
    }
  }

  /// Re-send the last user prompt (used by Retry on errors and the
  /// Regenerate action on completed replies).
  Future<void> _regenerate() async {
    if (_sending) return;
    final lastUser = _messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => ChatTurn(role: 'user', content: ''),
    );
    if (lastUser.content.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final apiHistory = _messages
          .where((m) => !m.isError && m.content.isNotEmpty)
          .takeWhile((m) => !identical(m, lastUser))
          .toList()
        ..add(lastUser);
      unawaited(ChatStore.save(apiHistory));
      final reply = await _chat.sendMessage(apiHistory);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatTurn(role: 'assistant', content: reply));
        _sending = false;
      });
      unawaited(ChatStore.save(_messages));
      _startReveal(_messages.length - 1);
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.cancel) {
        setState(() => _sending = false);
        return;
      }
      setState(() {
        _error = 'Assistant request failed (network). Please try again.';
        _sending = false;
      });
    } on ChatServiceError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Assistant failed: $e';
        _sending = false;
      });
    }
  }

  // ==========================================================================
  // TYPEWRITER REVEAL — smooth, flicker-free
  // ==========================================================================

  void _startReveal(int index) {
    _revealTimer?.cancel();
    _revealTarget = index;
    _revealing[index] = '';
    int pos = 0;
    final content = _messages[index].content;
    // Reveal in small chunks with a fixed tick so long answers finish fast
    // and short ones still feel typed.
    const tick = Duration(milliseconds: 16);
    const charsPerTick = 3;
    _revealTimer = Timer.periodic(tick, (t) {
      if (!mounted || _revealTarget != index) {
        t.cancel();
        return;
      }
      pos = (pos + charsPerTick).clamp(0, content.length);
      setState(() => _revealing[index] = content.substring(0, pos));
      _scrollToBottom();
      if (pos >= content.length) {
        t.cancel();
        setState(() => _revealing.remove(index));
      }
    });
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ==========================================================================
  // MESSAGE ACTIONS
  // ==========================================================================

  Future<void> _copyMessage(String content) async {
    // Strip markdown images for a cleaner clipboard payload.
    final plain = content
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAll(RegExp(r'\n\n_\[attached image: [^\]]*\]_'), '');
    await Clipboard.setData(ClipboardData(text: plain));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Response copied.'),
      ),
    );
  }

  Future<void> _shareMessage(String content) async {
    try {
      final result = await Share.share(
        content,
        subject: 'Vyro AI Assistant',
      );
      if (result.status != ShareResultStatus.success) {
        await Clipboard.setData(ClipboardData(text: content));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Copied — paste it anywhere to share.'),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: content));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Copied — paste it anywhere to share.'),
        ),
      );
    }
  }

  Future<void> _speak(String content) async {
    // Strip markdown so the voice reads clean prose.
    final plain = content
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' code block. ')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAll(RegExp(r'[#*_>`~|]'), '')
        .trim();
    if (plain.isEmpty) return;
    setState(() => _speaking = true);
    try {
      final result = await AiService.instance
          .synthesizeSpeech(TtsRequest(text: plain, voiceId: 'en-US-Standard-C'));
      if (!mounted) return;
      if (result.success && result.data != null) {
        final src = result.data!;
        if (src.startsWith('data:audio')) {
          final bytes = base64Decode(src.split(',').last);
          await _audioPlayer.stop();
          await _audioPlayer.play(BytesSource(bytes));
          return;
        }
        if (src.startsWith('http')) {
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(src));
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            result.error ?? 'Text-to-speech is not configured — add a TTS '
                'provider key in .env to enable voice replies.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Text-to-speech failed: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _attachImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachedBytes = bytes;
        _attachedName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not attach image: $e'),
        ),
      );
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        if (!widget.embedded) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
        ],
        const VyroLogo(size: 34, borderRadius: 10, glow: false),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vyro AI Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                _sending
                    ? 'Thinking…'
                    : 'Powered by ${_chat.providerLabel}',
                style: TextStyle(
                  color: _sending
                      ? const Color(0xFF00D5FF)
                      : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'New chat',
          icon: const Icon(Icons.add_comment_outlined,
              color: Color(0xFF94A3B8)),
          onPressed: _sending ? null : _newChat,
        ),
      ],
    );

    final chatBody = SafeArea(
      child: Column(
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: header,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 0),
              child: header,
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_error != null ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _error != null) {
                  return _buildErrorCard();
                }
                return _buildMessage(i);
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );

    if (widget.embedded) return chatBody;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: null,
      body: chatBody,
    );
  }

  Widget _buildMessage(int index) {
    final m = _messages[index];
    final isUser = m.role == 'user';
    final revealing = _revealing[index];
    final shown = revealing ?? m.content;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          margin: const EdgeInsets.only(left: 48, top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8855FF), Color(0xFF6D3AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8855FF).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _UserBubbleContent(
            content: m.content,
            attachedBytes: m.attachedBytes,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        margin: const EdgeInsets.only(right: 36, top: 10, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VyroLogo(size: 30, borderRadius: 9, glow: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17243B),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: const Color(0xFF263750)),
                    ),
                    child: revealing != null && revealing.isEmpty
                        ? _buildThinkingDots()
                        : ChatMarkdown(data: shown),
                  ),
                  if (_revealing[index] == null)
                    _buildActionRow(index, m),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(int index, ChatTurn m) {
    final liked = _liked.contains(index);
    final disliked = _disliked.contains(index);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Row(
        children: [
          _ActionIcon(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            onTap: () => _copyMessage(m.content),
          ),
          _ActionIcon(
            icon: Icons.refresh_rounded,
            tooltip: 'Regenerate',
            onTap: _sending ? null : _regenerate,
          ),
          _ActionIcon(
            icon: Icons.share_rounded,
            tooltip: 'Share',
            onTap: () => _shareMessage(m.content),
          ),
          _ActionIcon(
            icon: _speaking
                ? Icons.stop_rounded
                : Icons.volume_up_rounded,
            tooltip: _speaking ? 'Stop' : 'Listen',
            active: _speaking,
            onTap: _speaking
                ? () async {
                    await _audioPlayer.stop();
                    if (mounted) setState(() => _speaking = false);
                  }
                : () => _speak(m.content),
          ),
          _ActionIcon(
            icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
            tooltip: 'Good response',
            active: liked,
            color: liked ? const Color(0xFF10B981) : null,
            onTap: () => setState(() {
              _liked.add(index);
              _disliked.remove(index);
            }),
          ),
          _ActionIcon(
            icon: disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
            tooltip: 'Bad response',
            active: disliked,
            color: disliked ? const Color(0xFFEF4444) : null,
            onTap: () => setState(() {
              _disliked.add(index);
              _liked.remove(index);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, right: 36),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 13,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: _sending ? null : _regenerate,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Color(0xFF00D5FF),
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingDots() {
    return SizedBox(
      height: 26,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return _PulsingDot(delay: i * 180);
        }),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1420),
        border: Border(top: BorderSide(color: Color(0xFF1B2A44))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachedBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF17243B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF263750)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _attachedBytes!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachedName,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12.5,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18,
                        color: Color(0xFF94A3B8)),
                    onPressed: () => setState(() {
                      _attachedBytes = null;
                      _attachedName = '';
                    }),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF17243B),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF263750)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0xFF94A3B8), size: 22),
                  tooltip: 'Attach image',
                  onPressed: _attachImage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17243B),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: _inputFocus.hasFocus
                          ? const Color(0xFF8855FF).withValues(alpha: 0.6)
                          : const Color(0xFF263750),
                    ),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _inputFocus,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontFamily: 'Inter',
                    ),
                    cursorColor: const Color(0xFF00D5FF),
                    decoration: const InputDecoration(
                      hintText: 'Ask Vyro AI anything…',
                      hintStyle: TextStyle(
                        color: Color(0xFF5B6B85),
                        fontSize: 14.5,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_sending)
                _StopButton(onStop: _stopGeneration)
              else
                _SendButton(
                  enabled: _inputCtrl.text.trim().isNotEmpty,
                  busy: false,
                  onSend: _send,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onStop;
  const _StopButton({required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF17243B),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
      ),
      child: IconButton(
        tooltip: 'Stop generation',
        onPressed: onStop,
        icon: const Icon(Icons.stop_rounded, color: Color(0xFFEF4444), size: 24),
      ),
    );
  }
}

// ============================================================================
// SUB-WIDGETS
// ============================================================================

/// User bubble content: attached image thumbnail (if any) + text.
class _UserBubbleContent extends StatelessWidget {
  final String content;
  final Uint8List? attachedBytes;
  const _UserBubbleContent({required this.content, this.attachedBytes});

  @override
  Widget build(BuildContext context) {
    final text = content
        .replaceAll(RegExp(r'\n\n_\[attached image: [^\]]*\]_'), '')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachedBytes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                attachedBytes!,
                width: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (text.isNotEmpty)
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
              fontFamily: 'Inter',
            ),
          ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final int delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _a = Tween<double>(begin: 0.35, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: const BoxDecoration(
          color: Color(0xFF8855FF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (active ? const Color(0xFF00D5FF) : const Color(0xFF64748B));
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: c),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onSend;

  const _SendButton({
    required this.enabled,
    required this.busy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: enabled || busy
            ? const LinearGradient(
                colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
              )
            : const LinearGradient(
                colors: [Color(0xFF263750), Color(0xFF263750)],
              ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF8855FF).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: IgnorePointer(
        ignoring: !enabled && !busy,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled && !busy ? onSend : null,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: enabled ? Colors.white : const Color(0xFF5B6B85),
                    size: 21,
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// END — all helpers use direct package imports (share_plus, dart:convert).
// ============================================================================
