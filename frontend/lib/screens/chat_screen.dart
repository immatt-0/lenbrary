import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _conversations = [];
  List<dynamic>? _currentMessages;
  String? _currentConversationId;
  Map<String, dynamic>? _currentUser;
  bool _isLibrarian = false;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userInfoFuture = ApiService.getUserInfo();
      final conversationsFuture = ApiService.getMessages();

      final results = await Future.wait([userInfoFuture, conversationsFuture]);
      final user = results[0] as Map<String, dynamic>;
      final conversations = results[1] as List<dynamic>;

      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _isLibrarian = user['is_librarian'] ?? false;
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentConversationId = conversationId;
    });

    try {
      final messages = await ApiService.getMessages(conversationId: conversationId);

      if (!mounted) return;

      setState(() {
        _currentMessages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (!mounted || _currentConversationId == null) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      // Find the other user in the conversation
      final conversation = _conversations.firstWhere(
        (conv) => conv['conversation_id'] == _currentConversationId,
      );
      final otherUser = conversation['other_user'];

      await ApiService.sendMessage(
        recipientId: otherUser['id'],
        content: content,
      );

      // Reload the conversation
      await _loadConversation(_currentConversationId!);
      // Also reload the conversations list to update the last message
      await _loadData();
    } catch (e) {
      if (!mounted) return;

      NotificationService.showError(
        context: context,
        message: 'Eroare la trimiterea mesajului: \\${e.toString()}',
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted || !_isLibrarian || query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ApiService.searchUsers(query);
      
      if (!mounted) return;

      setState(() {
        _searchResults = results is List ? results : [];
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      NotificationService.showError(
        context: context,
        message: 'Eroare la căutarea utilizatorilor: \\${e.toString()}',
      );
    }
  }

  Future<void> _startNewChat(Map<String, dynamic> user) async {
    if (!mounted) return;

    try {
      // Send an initial message to start the conversation
      await ApiService.sendMessage(
        recipientId: user['id'],
        content: 'Bună! Cum te pot ajuta?',
      );

      // Reload conversations to show the new chat
      await _loadData();
    } catch (e) {
      if (!mounted) return;

      NotificationService.showError(
        context: context,
        message: 'Eroare la începerea conversației: \\${e.toString()}',
      );
    }
  }

  Widget _buildConversationList() {
    if (_conversations.isEmpty) {
      return const Center(
        child: Text('Nu ai conversații.'),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final otherUser = conversation['other_user'];
        final lastMessage = conversation['last_message'];
        final unreadCount = conversation['unread_count'] as int;

        return ListTile(
          leading: CircleAvatar(
            child: Text(otherUser['name'][0].toUpperCase()),
          ),
          title: Text(
            otherUser['name'],
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            lastMessage['content'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unreadCount > 0 ? Colors.black : Colors.grey,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: () => _loadConversation(conversation['conversation_id']),
        );
      },
    );
  }

  Widget _buildChatView() {
    if (_currentMessages == null) {
      return const Center(
        child: Text('Selectează o conversație pentru a începe.'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: _currentMessages!.length,
            itemBuilder: (context, index) {
              final message = _currentMessages![_currentMessages!.length - 1 - index];
              final isMe = message['is_sent_by_me'] as bool;
              final timestamp = DateTime.parse(message['timestamp']).toLocal();

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['content'],
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Scrie un mesaj...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Nu s-au găsit utilizatori.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final displayName = user['display_name'] ?? user['full_name'] ?? user['username'] ?? 'Unknown';
        final email = user['email'] ?? '';
        
        return ListTile(
          leading: CircleAvatar(
            child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
          ),
          title: Text(displayName),
          subtitle: Text(email),
          onTap: () {
            Navigator.pop(context); // Close the search dialog
            _startNewChat(user);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          if (_isLibrarian)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _searchResults = [];
                  _isSearching = true;
                });
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Caută utilizator'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Nume sau email...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: _searchUsers,
                            autofocus: true,
                          ),
                          const SizedBox(height: 16),
                          if (_isSearching)
                            const Center(child: CircularProgressIndicator())
                          else
                            Flexible(
                              child: _buildSearchResults(),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Anulează'),
                      ),
                    ],
                  ),
                ).then((_) {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                    _isSearching = false;
                  });
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Încearcă din nou'),
                      ),
                    ],
                  ),
                )
              : _currentConversationId == null
                  ? _buildConversationList()
                  : _buildChatView(),
    );
  }
} 