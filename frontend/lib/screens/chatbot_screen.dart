// lib/screens/chatbot_screen.dart
import 'package:flutter/material.dart';

// Simple model for a chat message
class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, required this.isUserMessage});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [
    // Initial welcome message from the bot
    ChatMessage(
      text: 'Hi there! How can I help you with vaccine information today?',
      isUserMessage: false,
    ),
  ];
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
      // TODO: Add logic here to get a response from your actual chatbot backend
      // For now, we'll just add a placeholder bot response.
      _messages.add(
        ChatMessage(
          text: 'Thinking...', // Placeholder for bot response
          isUserMessage: false,
        ),
      );
    });

    _textController.clear();
    _scrollToBottom();

    // Simulate bot response delay and replace "Thinking..."
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.removeLast(); // Remove "Thinking..."
        _messages.add(
          ChatMessage(
            text: 'This is a simulated bot response for: "$text"',
            isUserMessage: false,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  // Helper to scroll to the latest message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Chatbot'),
        backgroundColor: const Color(0xFFB794F6), // Matching card color
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  // Builds a single chat message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUserMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isUserMessage
              ? Theme.of(context).primaryColor.withOpacity(0.8)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(20.0).copyWith(
            bottomLeft: message.isUserMessage
                ? const Radius.circular(20.0)
                : const Radius.circular(0),
            bottomRight: message.isUserMessage
                ? const Radius.circular(0)
                : const Radius.circular(20.0),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUserMessage ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // Builds the text input field and send button row
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Ask about vaccines...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              onSubmitted: _sendMessage, // Send message on keyboard submit
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
