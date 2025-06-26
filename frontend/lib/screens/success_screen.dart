import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool _isLibrarian = false;
  String _userName = '';
  bool _isLoading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUnreadCounts();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userInfo = await ApiService.getUserInfo();
      setState(() {
        _isLibrarian = userInfo['is_librarian'] ?? false;
        _userName = userInfo['name'] ?? 'User';
      });
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      // Load notifications
      await _notificationService.loadNotifications();

      // Load messages and calculate unread count
      final messages = await ApiService.getMessages();
      int unreadMessages = 0;

      if (messages is List) {
        unreadMessages = messages.where((m) => m['is_read'] == false).length;
      }

      if (!mounted) return;

      setState(() {
        _unreadNotifications = _notificationService.unreadCount;
        _unreadMessages = unreadMessages;
      });
    } catch (e) {
      // Handle errors silently to not disrupt the UI
      debugPrint('Error loading unread counts: $e');
      if (mounted) {
        setState(() {
          _unreadNotifications = 0;
          _unreadMessages = 0;
        });
      }
    }
  }

  Widget _buildNotificationBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Row(
      children: [
        // Notifications bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                _loadUnreadCounts(); // Refresh counts when returning
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _buildNotificationBadge(_unreadNotifications),
            ),
          ],
        ),
        // Messages icon
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
                _loadUnreadCounts(); // Refresh counts when returning
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _buildNotificationBadge(_unreadMessages),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Se încarcă...'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLibrarian
        ? _buildLibrarianView(context)
        : _buildUserView(context);
  }

  Widget _buildUserView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lenbrary',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          _buildAppBarActions(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Deconectare',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bun venit, $_userName!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Ce doriți să faceți astăzi?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48.0),

                // Centered buttons container
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Books Button
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.search_rounded,
                        title: 'Caută cărți',
                        description: 'Explorează catalogul bibliotecii',
                        onTap: () {
                          Navigator.pushNamed(context, '/search-books');
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // My Requests Button
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.book_rounded,
                        title: 'Cererile mele',
                        description:
                            'Vizualizează și gestionează cererile tale',
                        onTap: () {
                          Navigator.pushNamed(context, '/my-requests');
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Exam Models Button
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.description_rounded,
                        title: 'Modele de examene',
                        description: 'Găsește modele de examene pentru studiu',
                        onTap: () {
                          Navigator.pushNamed(context, '/exam-models');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarianView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lenbrary',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          _buildAppBarActions(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Deconectare',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bun venit, Bibliotecar $_userName!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Gestionează resursele bibliotecii și cererile de cărți',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48.0),

                // Centered buttons container
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Book Management section
                    Text(
                      'Gestiunea cărților',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16.0),

                    // Add new book
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.add_circle_rounded,
                        title: 'Adaugă carte nouă',
                        description:
                            'Adaugă o carte nouă în catalogul bibliotecii',
                        onTap: () {
                          Navigator.pushNamed(context, '/add-book');
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // View all books
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.library_books_rounded,
                        title: 'Gestionare cărți',
                        description:
                            'Vizualizează, editează sau șterge cărți din catalog',
                        onTap: () {
                          Navigator.pushNamed(context, '/manage-books');
                        },
                      ),
                    ),

                    const SizedBox(height: 32.0),

                    // Book Request section
                    Text(
                      'Cereri de cărți',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16.0),

                    // Pending requests
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.pending_actions_rounded,
                        title: 'Cereri în așteptare',
                        description:
                            'Vizualizează și aprobă cererile de cărți în așteptare',
                        onTap: () {
                          Navigator.pushNamed(context, '/pending-requests');
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Active loans
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.assignment_returned_rounded,
                        title: 'Împrumuturi active',
                        description:
                            'Vizualizează toate cărțile împrumutate în prezent',
                        onTap: () {
                          Navigator.pushNamed(context, '/active-loans');
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Return history
                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.history_rounded,
                        title: 'Istoric împrumuturi',
                        description:
                            'Vizualizează istoricul împrumuturilor finalizate',
                        onTap: () {
                          Navigator.pushNamed(context, '/loan-history');
                        },
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Exam Models Admin Button
                    Text(
                      'Modele de examene',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16.0),

                    SizedBox(
                      width: 400,
                      child: _buildMenuButton(
                        icon: Icons.description_outlined,
                        title: 'Modele de examene',
                        description: 'Adaugă sau gestionează modele de examene',
                        onTap: () {
                          Navigator.pushNamed(context, '/admin-exam-models');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 0.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await ApiService.clearTokens();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
