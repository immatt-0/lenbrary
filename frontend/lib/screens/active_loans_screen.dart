import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/responsive_service.dart';
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
  List<dynamic> _filteredActiveLoans = [];
  String? _errorMessage;
  bool _processingAction = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadActiveLoans();
    _searchController.addListener(_filterActiveLoans);
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
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
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
        _filteredActiveLoans = loans;
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

  void _filterActiveLoans() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _filteredActiveLoans = _activeLoans.where((loan) {
        final bookName = loan['book']['name']?.toLowerCase() ?? '';
        return bookName.contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
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
                padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 8 : 10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.book_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: ResponsiveService.isSmallPhone ? 20 : 24,
                ),
              ),
              SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 12),
              Flexible(
                child: Text(
                  ResponsiveService.isSmallPhone ? 'Împrumuturi' : 'Împrumuturi Active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.only(left: ResponsiveService.getSpacing(8)),
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(6)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveService.getIconSize(20),
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
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
                  // Extension requests button section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveService.isSmallPhone ? 16 : 24, 
                        vertical: ResponsiveService.isSmallPhone ? 12 : 16
                      ),
                      child: ResponsiveService.isSmallPhone
                          ? Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.secondary,
                                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ExtensionRequestsScreen(),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSecondary,
                                    ),
                                    label: Text(
                                      'Cereri Extindere',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aici puteți vizualiza cererile de extindere',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.secondary,
                                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ExtensionRequestsScreen(),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.schedule_rounded,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onSecondary,
                                    ),
                                    label: Text(
                                      'Cereri Extindere',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Aici puteți vizualiza cererile de extindere',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  // Search Bar
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveService.isSmallPhone ? 16 : 24, 
                          vertical: ResponsiveService.isSmallPhone ? 12 : 16
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 20 : 25),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                                blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
                                offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: ResponsiveService.isSmallPhone 
                                  ? '🔍 Caută cărți...' 
                                  : '🔍 Caută după numele cărții...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                fontSize: ResponsiveService.isSmallPhone ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                margin: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                                padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: ResponsiveService.isSmallPhone ? 20 : 24,
                                ),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        margin: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 8 : 10),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: ResponsiveService.isSmallPhone ? 18 : 20,
                                          ),
                                          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 4 : 6),
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        ),
                                      ),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 20 : 25),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 20 : 25),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 20 : 25),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                                vertical: ResponsiveService.isSmallPhone ? 14 : 18,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: ResponsiveService.isSmallPhone ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
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
                                        padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                          Icons.error_outline_rounded,
                          size: ResponsiveService.isSmallPhone ? 40 : 48,
                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    );
                                  },
                        ),
                        SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                          ),
                          textAlign: TextAlign.center,
                                  ),
                        ),
                        SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
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
                : _filteredActiveLoans.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveService.isSmallPhone ? 16 : 24,
                          ),
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
                                      padding: EdgeInsets.all(
                                        ResponsiveService.isSmallPhone ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.book_outlined,
                                        size: ResponsiveService.isSmallPhone ? 40 : 48,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  _searchQuery.isNotEmpty 
                                      ? 'Nu s-au găsit rezultate pentru "$_searchQuery"'
                                      : 'Nu există împrumuturi active',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    fontSize: ResponsiveService.isSmallPhone ? 16 : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: ListView.builder(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveService.isSmallPhone ? 16 : 24,
                                      vertical: ResponsiveService.isSmallPhone ? 12 : 16,
                                    ),
                        itemCount: _filteredActiveLoans.length,
                        itemBuilder: (context, index) {
                          final loan = _filteredActiveLoans[index];
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
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveService.isTablet ? 600 : double.infinity,
                              ),
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: ResponsiveService.isSmallPhone ? 16 : 20,
                  ),
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
                    padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 24),
                                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                        // Student Information Section - Compact Top Layout with Background
                        Container(
                          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                Theme.of(context).colorScheme.primary.withOpacity(0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: ResponsiveService.isSmallPhone ? 40 : 48,
                                height: ResponsiveService.isSmallPhone ? 40 : 48,
                                padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 8 : 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: ResponsiveService.isSmallPhone ? 24 : 28,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name and Email on same line
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          toTitleCase(student['user']['display_name'] ?? '${student['user']['first_name']} ${student['user']['last_name']}'),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontSize: ResponsiveService.isSmallPhone ? 16 : 18,
                                          ),
                                        ),
                                        SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 10),
                                        Text(
                                          student['user']['email'] ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: ResponsiveService.isSmallPhone ? 12 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ResponsiveService.isSmallPhone ? 6 : 8),
                                    // Student class information - bigger
                                    Builder(
                                      builder: (context) {
                                        final studentId = student['student_id']?.toString() ?? '';
                                        final isTeacher = studentId.startsWith('T');
                                        
                                        if (isTeacher) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: ResponsiveService.isSmallPhone ? 8 : 10, 
                                              vertical: ResponsiveService.isSmallPhone ? 4 : 6
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              'Profesor',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w700,
                                                fontSize: ResponsiveService.isSmallPhone ? 11 : 13,
                                              ),
                                            ),
                                          );
                                        } else if (student['student_class'] != null || student['department'] != null) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: ResponsiveService.isSmallPhone ? 8 : 10, 
                                              vertical: ResponsiveService.isSmallPhone ? 4 : 6
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              '${student['school_type'] ?? ''} ${student['student_class'] ?? ''} ${student['department'] ?? ''}'.trim(),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: ResponsiveService.isSmallPhone ? 11 : 13,
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
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
                        
                        // Book Information Section - Cover left, Info with background right
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
                                  width: ResponsiveService.isSmallPhone ? 70 : 90,
                                  height: ResponsiveService.isSmallPhone ? 105 : 135,
                                  child: book['thumbnail_url'] != null && book['thumbnail_url'].isNotEmpty
                                      ? Image.network(
                                          book['thumbnail_url'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Icon(Icons.image_not_supported, 
                                                  size: ResponsiveService.isSmallPhone ? 25 : 30),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: Icon(Icons.image_not_supported, 
                                              size: ResponsiveService.isSmallPhone ? 25 : 30),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveService.isSmallPhone ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Book Title and Author with Background - Same height as cover
                                  Container(
                                    height: ResponsiveService.isSmallPhone ? 105 : 135, // Match book cover height
                                    padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                                          Theme.of(context).colorScheme.secondary.withOpacity(0.02),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                                      mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                                      children: [
                                        // Book Title
                                        Center(
                                          child: Text(
                                            book['name'] ?? 'Carte necunoscută',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: ResponsiveService.isSmallPhone ? 14 : 16,
                                            ),
                                            maxLines: 2, // Limit to 2 lines for better layout
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center, // Center the title text
                                          ),
                                        ),
                                        SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 12),
                                        // Author - Centered
                                        Center(
                                          child: Text(
                                            book['author'] ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              fontWeight: FontWeight.w500,
                                              fontSize: ResponsiveService.isSmallPhone ? 12 : 14,
                                            ),
                                            maxLines: 2, // Limit to 2 lines for better layout
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center, // Center the author text
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
                        SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
                        
                        // Dates Section - Below the book info
                        Column(
                          children: [
                            // Pickup Date
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.08),
                                    Colors.green.withOpacity(0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.withOpacity(0.15),
                                          Colors.green.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.green[700],
                                      size: ResponsiveService.isSmallPhone ? 16 : 18,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveService.isSmallPhone ? 10 : 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Data ridicării: ',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w700,
                                          fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: pickupDate != null
                                                ? '${pickupDate.day.toString().padLeft(2, '0')}.${pickupDate.month.toString().padLeft(2, '0')}.${pickupDate.year}'
                                                : 'Nu este disponibilă',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.w600,
                                              fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 10),
                            // Due Date
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.withOpacity(0.08),
                                    Colors.orange.withOpacity(0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.withOpacity(0.15),
                                          Colors.orange.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.event_rounded,
                                      color: Colors.orange[700],
                                      size: ResponsiveService.isSmallPhone ? 16 : 18,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveService.isSmallPhone ? 10 : 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Data scadenței: ',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w700,
                                          fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: dueDate != null
                                                ? '${dueDate.day.toString().padLeft(2, '0')}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}'
                                                : 'Nu este disponibilă',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.orange[600],
                                              fontWeight: FontWeight.w600,
                                              fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 20),
                        
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
                                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 12 : 16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _processingAction ? null : () => _returnBook(loan['id'].toString()),
                                icon: _processingAction 
                                    ? SizedBox(
                                        width: ResponsiveService.isSmallPhone ? 16 : 20,
                                        height: ResponsiveService.isSmallPhone ? 16 : 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                        ),
                                      )
                                    : Icon(
                                        Icons.assignment_return_rounded,
                                        size: ResponsiveService.isSmallPhone ? 18 : 20,
                                      ),
                                label: Text(
                                  _processingAction ? 'Se procesează...' : 'Carte Returnată',
                                  style: TextStyle(
                                    fontSize: ResponsiveService.isSmallPhone ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveService.isSmallPhone ? 16 : 24, 
                                    vertical: ResponsiveService.isSmallPhone ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 12 : 16),
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
