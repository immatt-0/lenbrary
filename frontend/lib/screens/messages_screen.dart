import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _messages = [];
  List<dynamic> _users = []; // For librarians to see all users
  bool _isLibrarian = false;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedUser;
  String _searchQuery = '';

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
      final usersFuture = ApiService.getAllUsers();
      final results = await Future.wait<dynamic>([
        userInfoFuture,
        usersFuture,
      ]);
      if (!mounted) return;
      final userInfo = results[0] as Map<String, dynamic>;
      final users = results[1];
      setState(() {
        _isLibrarian = userInfo['is_librarian'] ?? false;
        _users = users is List ? users : [];
      });
      if (!_isLibrarian) {
        final librarians = _users.where((user) => user['is_librarian'] == true && user['id'] != null).toList();
        if (librarians.isNotEmpty) {
          setState(() { _selectedUser = librarians[0]; });
          final messages = await ApiService.getMessages(conversationId: librarians[0]['id'].toString());
          if (!mounted) return;
          setState(() {
            if (messages is List) {
              _messages = messages;
            } else {
              _messages = [];
              _errorMessage = messages.toString();
            }
          });
        }
      } else {
        final messages = await ApiService.getMessages();
        if (!mounted) return;
        setState(() {
          if (messages is List) {
            _messages = messages;
          } else {
            _messages = [];
            _errorMessage = messages.toString();
          }
        });
      }
      setState(() { _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversation(String? conversationId) async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final messages = await ApiService.getMessages(conversationId: conversationId);
      if (!mounted) return;
      setState(() {
        if (messages is List) {
          _messages = messages;
        } else {
          _messages = [];
          _errorMessage = messages.toString();
        }
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

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final users = await ApiService.getAllUsers();
      if (!mounted) return;
      final filteredUsers = (users is List ? users : []).where((user) {
        final name = (user['first_name'] != null && user['last_name'] != null)
            ? '${user['first_name']} ${user['last_name']}'.toLowerCase()
            : (user['username'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
      setState(() {
        _users = filteredUsers;
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
    if (!mounted) return;
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    int? recipientId;
    if (_isLibrarian) {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te rugăm să selectezi un utilizator'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      recipientId = _selectedUser!['id'];
    } else {
      if (_selectedUser == null) {
        final librarians = _users.where((user) => user['is_librarian'] == true && user['id'] != null).toList();
        if (librarians.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nu s-a găsit niciun bibliotecar disponibil. Vă rugăm să încercați din nou.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() { _selectedUser = librarians[0]; });
        recipientId = librarians[0]['id'];
      } else {
        recipientId = _selectedUser!['id'];
      }
    }
    _messageController.clear();
    try {
      await ApiService.sendMessage(
        recipientId: recipientId!,
        content: content,
      );
      await _loadConversation(recipientId.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la trimiterea mesajului: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      final name = (user['display_name'] ?? user['full_name'] ?? 
                     (user['first_name'] != null && user['last_name'] != null
                        ? '${user['first_name']} ${user['last_name']}'
                        : user['username'] ?? 'Unknown')).toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildUserList() {
    if (_users.isEmpty) {
      return const Center(
        child: Text('Nu există utilizatori.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Caută utilizator...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              final displayName = toTitleCase(user['display_name'] ?? user['full_name'] ?? 
                                 ((user['first_name'] != null && user['last_name'] != null)
                                    ? '${user['first_name']} ${user['last_name']}'
                                    : (user['username'] ?? 'Unknown')));
              final email = user['email'] ?? '';
              final isLibrarian = user['is_librarian'] == true;
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(displayName.isNotEmpty ? displayName[0] : '?'),
                ),
                title: Text(displayName),
                subtitle: Text(email),
                trailing: isLibrarian ? const Icon(Icons.verified_user, color: Colors.blue) : null,
                selected: _selectedUser?['id'] == user['id'],
                onTap: () {
                  setState(() {
                    _selectedUser = user;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isLibrarian
                  ? 'Nu există mesaje în această conversație.'
                  : 'Nu există mesaje cu bibliotecarul.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['is_sent_by_me'] == true;
        final content = message['content']?.toString() ?? '';
        final timestamp = DateTime.tryParse(message['timestamp']?.toString() ?? '') ?? DateTime.now();
        final sender = message['sender'];
        String senderName = 'Unknown';
        if (sender is Map<String, dynamic>) {
          if (sender['first_name'] != null && sender['last_name'] != null) {
            senderName = '${sender['first_name']} ${sender['last_name']}';
          } else if (sender['username'] != null) {
            senderName = sender['username'].toString();
          }
        } else if (sender is String && sender.isNotEmpty) {
          senderName = sender;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe && !_isLibrarian) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    toTitleCase(senderName).substring(0, 1),
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe && _isLibrarian)
                        Text(
                          toTitleCase(senderName),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      Text(content),
                      Text(
                        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe && !_isLibrarian) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    toTitleCase(senderName).substring(0, 1),
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
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
        ),
      );
    }

    if (_isLibrarian) {
      if (_selectedUser == null) {
        // Show user search interface
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mesaje'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Caută utilizator',
                    hintText: 'Nume sau email...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _users = [];
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.isNotEmpty) {
                      _searchUsers(value);
                    } else {
                      setState(() {
                        _users = [];
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: _users.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Caută un utilizator pentru a începe o conversație'
                              : 'Nu s-au găsit utilizatori',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final displayName = toTitleCase(user['display_name'] ?? user['full_name'] ?? 
                                             (user['first_name'] != null && user['last_name'] != null
                                                ? '${user['first_name']} ${user['last_name']}'
                                                : user['username'] ?? 'Unknown'));
                          final email = user['email'] ?? '';
                          final isTeacher = user['student_id']?.toString().startsWith('T') ?? false;
                          final schoolType = user['school_type'];
                          final studentClass = user['student_class'];
                          final department = user['department'];

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(displayName[0].toUpperCase()),
                            ),
                            title: Text(displayName),
                            subtitle: Text(
                              isTeacher
                                  ? 'Profesor'
                                  : '${schoolType ?? ''} ${studentClass ?? ''} ${department ?? ''}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      } else {
        // Show chat interface with selected user
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedUser = null;
                  _messages = [];
                });
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toTitleCase(_selectedUser!['display_name'] ?? _selectedUser!['full_name'] ??
                    ((_selectedUser!['first_name'] != null && _selectedUser!['last_name'] != null)
                        ? '${_selectedUser!['first_name']} ${_selectedUser!['last_name']}'
                        : (_selectedUser!['username'] ?? 'Unknown'))),
                ),
                Text(
                  _selectedUser!['student_id']?.toString().startsWith('T') ?? false
                      ? 'Profesor'
                      : '${_selectedUser!['school_type'] ?? ''} ${_selectedUser!['student_class'] ?? ''} ${_selectedUser!['department'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildMessageList(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Scrie un mesaj...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Non-librarian view (simple chat with librarian)
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mesaje cu bibliotecarul'),
        ),
        body: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Scrie un mesaj...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
} 