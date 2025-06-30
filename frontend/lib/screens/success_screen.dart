import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin, ResponsiveWidget {
  bool _isLibrarian = false;
  String _userName = '';
  bool _isLoading = true;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();
  bool _isFirstLoad = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUnreadCounts();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible (but not on first load)
    if (!_isFirstLoad) {
      _refreshData();
    } else {
      _isFirstLoad = false;
    }
  }

  Future<void> _refreshData() async {
    // Refresh unread counts and user info
    await _loadUnreadCounts();
    await _loadUserInfo();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
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

      if (!mounted) return;

      setState(() {
        _unreadNotifications = _notificationService.unreadCount;
      });
    } catch (e) {
      // Handle errors silently to not disrupt the UI
      debugPrint('Error loading unread counts: $e');
      if (mounted) {
        setState(() {
          _unreadNotifications = 0;
        });
      }
    }
  }

  Widget _buildNotificationBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(getResponsiveSpacing(4)),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: getResponsiveBorderRadius(10),
      ),
      constraints: BoxConstraints(
        minWidth: getResponsiveSpacing(16),
        minHeight: getResponsiveSpacing(16),
      ),
      child: Text(
        count.toString(),
        style: ResponsiveTextStyles.getResponsiveTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
              icon: Icon(
                Icons.notifications, 
                size: getResponsiveIconSize(28)
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                _refreshData(); // Refresh all data when returning
              },
            ),
            Positioned(
              right: getResponsiveSpacing(8),
              top: getResponsiveSpacing(8),
              child: _buildNotificationBadge(_unreadNotifications),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Se încarcă...',
            style: ResponsiveTextStyles.getResponsiveTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Center(
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getResponsiveSpacing(16.0), 
              vertical: getResponsiveSpacing(8.0)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: getResponsiveBorderRadius(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: getResponsiveSpacing(8),
                        offset: Offset(0, getResponsiveSpacing(2)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: getResponsiveIconSize(28),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  'Lenbrary',
                  style: ResponsiveTextStyles.getResponsiveTitleStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          _buildAppBarActions(),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(getResponsiveSpacing(8)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: getResponsiveBorderRadius(8),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: getResponsiveIconSize(24),
              ),
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Setări',
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(getResponsiveSpacing(8)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: getResponsiveBorderRadius(8),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
                size: getResponsiveIconSize(24),
              ),
            ),
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
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.secondary.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: getResponsivePadding(all: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced Welcome Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: EdgeInsets.only(bottom: getResponsiveSpacing(40.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withOpacity(0.95),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: getResponsiveBorderRadius(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                blurRadius: getResponsiveSpacing(24),
                                offset: Offset(0, getResponsiveSpacing(10)),
                                spreadRadius: 3,
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: getResponsivePadding(all: 36.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(getResponsiveSpacing(16)),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: getResponsiveBorderRadius(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                            blurRadius: getResponsiveSpacing(12),
                                            offset: Offset(0, getResponsiveSpacing(4)),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: getResponsiveIconSize(32),
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                    SizedBox(width: getResponsiveSpacing(20)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bun venit, $_userName!',
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              letterSpacing: -0.5,
                                              fontSize: 28,
                                            ),
                                          ),
                                          SizedBox(height: getResponsiveSpacing(12.0)),
                                          Text(
                                            'Ce doriți să faceți astăzi?',
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Enhanced Menu Sections
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search Books Button
                            _buildEnhancedMenuButton(
                              icon: Icons.search_rounded,
                              title: 'Caută cărți',
                              description: 'Explorează catalogul bibliotecii',
                              color: Colors.green[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/search-books');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // My Requests Button
                            _buildEnhancedMenuButton(
                              icon: Icons.book_rounded,
                              title: 'Cererile mele',
                              description: 'Vizualizează și gestionează cererile tale',
                              color: Colors.orange[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/my-requests');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Exam Models Button
                            _buildEnhancedMenuButton(
                              icon: Icons.description_rounded,
                              title: 'Modele de examene',
                              description: 'Găsește modele de examene pentru studiu',
                              color: Colors.purple[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/exam-models');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarianView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getResponsiveSpacing(16.0), 
              vertical: getResponsiveSpacing(8.0)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: getResponsiveBorderRadius(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: getResponsiveSpacing(8),
                        offset: Offset(0, getResponsiveSpacing(2)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: getResponsiveIconSize(28),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(12)),
                Text(
                  'Lenbrary',
                  style: ResponsiveTextStyles.getResponsiveTitleStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          _buildAppBarActions(),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(getResponsiveSpacing(8)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: getResponsiveBorderRadius(8),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: getResponsiveIconSize(24),
              ),
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Setări',
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(getResponsiveSpacing(8)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: getResponsiveBorderRadius(8),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
                size: getResponsiveIconSize(24),
              ),
            ),
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
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.secondary.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: getResponsivePadding(all: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced Welcome Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: EdgeInsets.only(bottom: getResponsiveSpacing(40.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withOpacity(0.95),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: getResponsiveBorderRadius(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                blurRadius: getResponsiveSpacing(24),
                                offset: Offset(0, getResponsiveSpacing(10)),
                                spreadRadius: 3,
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: getResponsivePadding(all: 36.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(getResponsiveSpacing(16)),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: getResponsiveBorderRadius(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                            blurRadius: getResponsiveSpacing(12),
                                            offset: Offset(0, getResponsiveSpacing(4)),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: getResponsiveIconSize(32),
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                    SizedBox(width: getResponsiveSpacing(20)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bun venit, $_userName!',
                                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          SizedBox(height: getResponsiveSpacing(12.0)),
                                          Text(
                                            'Panou de administrare bibliotă',
                                            style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Enhanced Menu Sections
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Add Book Button
                            _buildEnhancedMenuButton(
                              icon: Icons.add_circle_rounded,
                              title: 'Adaugă carte',
                              description: 'Adaugă o nouă carte în catalog',
                              color: Colors.green[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/add-book');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Manage Books Button
                            _buildEnhancedMenuButton(
                              icon: Icons.library_books_rounded,
                              title: 'Gestionează cărți',
                              description: 'Editează și șterge cărți din catalog',
                              color: Colors.blue[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/manage-books');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Pending Requests Button
                            _buildEnhancedMenuButton(
                              icon: Icons.pending_actions_rounded,
                              title: 'Cereri în așteptare',
                              description: 'Gestionează cererile de împrumut',
                              color: Colors.orange[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/pending-requests');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Active Loans Button
                            _buildEnhancedMenuButton(
                              icon: Icons.book_online_rounded,
                              title: 'Împrumuturi active',
                              description: 'Vizualizează împrumuturile curente',
                              color: Colors.purple[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/active-loans');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Loan History Button
                            _buildEnhancedMenuButton(
                              icon: Icons.history_rounded,
                              title: 'Istoric împrumuturi',
                              description: 'Vizualizează istoricul împrumuturilor',
                              color: Colors.indigo[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/loan-history');
                              },
                            ),
                            SizedBox(height: getResponsiveSpacing(16.0)),

                            // Exam Models Admin Button
                            _buildEnhancedMenuButton(
                              icon: Icons.description_rounded,
                              title: 'Modele de teste',
                              description: 'Gestionează modelele de teste',
                              color: Colors.teal[600]!,
                              onTap: () {
                                Navigator.pushNamed(context, '/admin-exam-models');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMenuButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: ResponsiveService.cardMaxWidth,
      margin: EdgeInsets.only(bottom: getResponsiveSpacing(8.0)),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    color.withOpacity(0.01),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: getResponsiveBorderRadius(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: getResponsiveSpacing(12),
                    offset: Offset(0, getResponsiveSpacing(4)),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: getResponsiveSpacing(8),
                    offset: Offset(0, getResponsiveSpacing(2)),
                  ),
                ],
                border: Border.all(
                  color: color.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: getResponsiveBorderRadius(16),
                  child: Padding(
                    padding: getResponsivePadding(all: 20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(getResponsiveSpacing(12)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.12),
                                color.withOpacity(0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: getResponsiveBorderRadius(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: getResponsiveSpacing(8),
                                offset: Offset(0, getResponsiveSpacing(2)),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: getResponsiveIconSize(24),
                            color: color,
                          ),
                        ),
                        SizedBox(width: getResponsiveSpacing(16.0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: getResponsiveSpacing(4)),
                              Text(
                                description,
                                style: ResponsiveTextStyles.getResponsiveBodyStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(getResponsiveSpacing(8)),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: getResponsiveBorderRadius(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: getResponsiveIconSize(16),
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
