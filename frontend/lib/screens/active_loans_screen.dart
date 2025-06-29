import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'extension_requests_screen.dart';

class ActiveLoansScreen extends StatefulWidget {
  const ActiveLoansScreen({Key? key}) : super(key: key);

  @override
  State<ActiveLoansScreen> createState() => _ActiveLoansScreenState();
}

class _ActiveLoansScreenState extends State<ActiveLoansScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _activeLoans = [];
  String? _errorMessage;
  bool _processingAction = false;
  bool _isLibrarian = false;

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
    _loadActiveLoans();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
      begin: 0.9,
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
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await ApiService.getUserInfo();
      setState(() {
        _isLibrarian = userInfo['is_librarian'] ?? false;
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _loadActiveLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loans = await ApiService.getActiveLoans();
      setState(() {
        _activeLoans = loans;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _returnBook(String loanId) async {
    setState(() {
      _processingAction = true;
    });

    try {
      await ApiService.librarianReturnBook(int.parse(loanId));
      await _loadActiveLoans();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _processingAction = false;
      });
    }
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.book_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Împrumuturi Active',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/success'),
              tooltip: 'Înapoi',
            ),
          ),
        ),
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Se încarcă împrumuturile...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Extension Requests Button Section (for librarians only)
                  if (_isLibrarian)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cereri de Extindere',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gestionează cererile de extindere a termenului de împrumut',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ExtensionRequestsScreen(),
                                        ),
                                      );
                                      await _loadActiveLoans();
                                    },
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                    label: const Text('Accesează'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Main Content
                  Expanded(
                    child: _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 600),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    );
                                  },
                        ),
                        const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                                  ),
                        ),
                        const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: ElevatedButton.icon(
                          onPressed: _loadActiveLoans,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reîncearcă'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _activeLoans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 600),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                              Icons.book_outlined,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        );
                                      },
                            ),
                            const SizedBox(height: 16),
                                    FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Text(
                              'Nu există împrumuturi active',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                        ),
                                  ),
                            ),
                          ],
                        ),
                      )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: _activeLoans.length,
                        itemBuilder: (context, index) {
                          final loan = _activeLoans[index];
                                      return _buildLoanCard(loan, index);
                                    },
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoanCard(dynamic loan, int index) {
                          final book = loan['book'];
                          final student = loan['student'];
                          final pickupDate = loan['pickup_date'] != null
                              ? DateTime.parse(loan['pickup_date']).toLocal()
                              : null;
                          final dueDate = loan['due_date'] != null
                              ? DateTime.parse(loan['due_date']).toLocal()
                              : null;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                                ),
                                child: Padding(
                    padding: const EdgeInsets.all(24),
                                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                        // Student Information Section
                                      Row(
                                        children: [
                                          Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                            ),
                                            child: Icon(
                                              Icons.person_rounded,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                            const SizedBox(width: 20),
                                          Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                      Theme.of(context).colorScheme.primary.withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                            child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                    Text(
                                                        toTitleCase(student['user']['display_name'] ?? '${student['user']['first_name']} ${student['user']['last_name']}'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        letterSpacing: 0.5,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      student['user']['email'] ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Student class information
                                    Builder(
                                      builder: (context) {
                                        final studentId = student['student_id']?.toString() ?? '';
                                        final isTeacher = studentId.startsWith('T');
                                        
                                        if (isTeacher) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Profesor',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        } else if (student['student_class'] != null || student['department'] != null) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '${student['school_type'] ?? ''} ${student['student_class'] ?? ''} ${student['department'] ?? ''}'.trim(),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                        const SizedBox(height: 24),
                        
                        // Book Information Section with Photo First
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book cover image on the left
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 120,
                                  height: 180,
                                  child: book['thumbnail_url'] != null && book['thumbnail_url'].isNotEmpty
                                      ? Image.network(
                                          book['thumbnail_url'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(Icons.image_not_supported, size: 40),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported, size: 40),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Book Title and Author
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                          Theme.of(context).colorScheme.primary.withOpacity(0.02),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                        children: [
                                          Container(
                                          padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.book_rounded,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                book['name'] ?? 'Carte necunoscută',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                                Text(
                                                  book['author'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                    ),
                                      ),
                                      const SizedBox(height: 16),
                                  
                                  // Dates Section
                                  Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.withOpacity(0.08),
                                              Colors.green.withOpacity(0.02),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.withOpacity(0.15),
                                                    Colors.green.withOpacity(0.05),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.calendar_today_rounded,
                                                color: Colors.green[700],
                                                size: 20,
                                              ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Data împrumutului',
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.green[700],
                                                      ),
                                                ),
                                                Text(
                                                  pickupDate != null
                                                      ? pickupDate.toString().split(' ')[0]
                                                      : 'N/A',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.green[600],
                                                      fontWeight: FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.withOpacity(0.08),
                                              Colors.orange.withOpacity(0.02),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.orange.withOpacity(0.15),
                                                    Colors.orange.withOpacity(0.05),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.event_rounded,
                                                color: Colors.orange[700],
                                                size: 20,
                                              ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Data returnării',
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.orange[700],
                                                      ),
                                                ),
                                                Text(
                                                  dueDate != null
                                                      ? dueDate.toString().split(' ')[0]
                                                      : 'N/A',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.orange[600],
                                                      fontWeight: FontWeight.w500,
                                                      ),
                                                ),
                                              ],
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
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Action Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                            onPressed: _processingAction ? null : () => _returnBook(loan['id'].toString()),
                                icon: _processingAction 
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                        ),
                                      )
                                    : const Icon(Icons.assignment_return_rounded),
                                label: Text(_processingAction ? 'Se procesează...' : 'Carte Returnată'),
                                            style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                              shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                              ),
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
      ),
        );
      },
    );
  }
}
