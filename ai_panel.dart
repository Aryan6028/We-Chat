import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/providers/ai_provider.dart';

class AiPanel extends StatefulWidget {
  const AiPanel({super.key});

  @override
  State<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<AiPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  late AiProvider _aiProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _aiProvider = context.read<AiProvider>();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔥 AUTO SCROLL
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
      _controller.clear();
    });

    _scrollToBottom();

    String reply;

    try {
      reply = await _aiProvider.query(text);
    } catch (e) {
      reply = "Error: ${e.toString()}";
    }

    if (!mounted) return;

    setState(() {
      _messages.add({'role': 'assistant', 'text': reply});
      _loading = false;
    });

    _scrollToBottom();
  }

  Widget _buildMessage(Map<String, String> m) {
    final isUser = m['role'] == 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            m['text'] ?? '',
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // 🔥 HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI Assistant',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _messages.clear()),
                ),
              ],
            ),
          ),

          // 🔥 CHAT AREA
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      "Ask anything 🤖",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessage(_messages[i]),
                  ),
          ),

          // 🔥 LOADING BUBBLE (BETTER UX)
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text("AI is typing..."),
            ),

          // 🔥 INPUT
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Ask the assistant...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _send,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}