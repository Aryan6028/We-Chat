import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:we_chat_app/providers/ai_provider.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<String> _categories = const [
    'Business names',
    'Human names',
    'Games names',
    'Pet names',
    'Dish names',
    'Character names',
  ];

  late final stt.SpeechToText _speech;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatUser _me = ChatUser(id: 'user', firstName: 'You');
  final ChatUser _bot = ChatUser(id: 'bot', firstName: 'BlueSpeak');
  final List<ChatUser> _typingUsers = [];
  bool _isListening = false;
  String _spokenText = '';

  AiProvider get _aiProvider => context.read<AiProvider>();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    setState(() {
      _spokenText = '';
    });

    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (err) {
          debugPrint('Speech error: $err');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _spokenText = val.recognizedWords;
              _textController.text = _spokenText;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      text: trimmed,
      user: _me,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
      _typingUsers.add(_bot);
      _textController.clear();
    });

    try {
      final reply = await _aiProvider.query(trimmed);
      final botMessage = ChatMessage(
        text: reply,
        user: _bot,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, botMessage);
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        text: '❌ Error: ${e.toString()}',
        user: _bot,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    } finally {
      setState(() {
        _typingUsers.remove(_bot);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          'Blue Speak',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildIntroUI()
                  : DashChat(
                      messages: _messages,
                      currentUser: _me,
                      typingUsers: _typingUsers,
                      onSend: (message) => _sendMessage(message.text),
                      readOnly: true,
                      messageOptions: MessageOptions(
                        currentUserContainerColor: Colors.deepPurpleAccent,
                        containerColor: Colors.grey.shade100,
                        borderRadius: 16,
                        messagePadding: const EdgeInsets.all(12),
                        messageTextBuilder: (message, _, __) {
                          return MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 16, height: 1.4),
                              strong: const TextStyle(fontWeight: FontWeight.bold),
                              em: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            _inputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'images/app_icon.png',
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            _chatBubble('Hi, you can ask me anything about names'),
            const SizedBox(height: 10),
            _suggestionBubble(_categories),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _suggestionBubble(List<String> items) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome, size: 18, color: Colors.deepPurple),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'I suggest you some names you can ask me..',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Colors.deepPurple),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      onPressed: () {
                        _textController.text = item;
                      },
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask me about names...',
                  border: InputBorder.none,
                  suffixIcon: GestureDetector(
                    onTap: _listen,
                    child: Icon(
                      _isListening ? Icons.mic_none : Icons.mic,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple,
              ),
              padding: const EdgeInsets.all(14),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
