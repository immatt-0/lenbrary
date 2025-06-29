import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';

class ExamModelsScreen extends StatefulWidget {
  const ExamModelsScreen({Key? key}) : super(key: key);

  @override
  State<ExamModelsScreen> createState() => _ExamModelsScreenState();
}

class _ExamModelsScreenState extends State<ExamModelsScreen>
    with TickerProviderStateMixin {
  List<dynamic> _models = [];
  bool _isLoading = true;
  String? _selectedType; // 'EN' or 'BAC'
  String? _selectedCategory; // 'Matematica' or 'Romana'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _fetchExamModels();
    
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
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExamModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await ApiService.fetchExamModels();
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la încărcarea modelelor: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<dynamic> get _filteredModels {
    return _models.where((model) {
      final typeMatch = _selectedType == null || model['type'] == _selectedType;
      final categoryMatch = _selectedCategory == null || model['category'] == _selectedCategory;
      final nameMatch = model['name'] != null && model['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      return typeMatch && categoryMatch && nameMatch;
    }).toList();
  }

  void _openPdf(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nu s-a putut deschide PDF-ul.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'EN':
        return const Color(0xFF10B981); // Green
      case 'BAC':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Theme.of(context).colorScheme.tertiary; // Lighter Blue
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Matematica':
        return const Color(0xFF3B82F6); // Blue
      case 'Romana':
        return const Color(0xFFEF4444); // Red
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'EN':
        return Icons.school_rounded;
      case 'BAC':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Matematica':
        return Icons.functions_rounded;
      case 'Romana':
        return Icons.menu_book_rounded;
      default:
        return Icons.subject_rounded;
    }
  }

  // Helper method to check if the search is for a special subject
  bool _isSpecialSubject(String query) {
    final specialSubjects = [
      'istorie', 'geografie', 'biologie', 'chimie', 'fizica', 'filosofie',
      'sociologie', 'psihologie', 'economie', 'drept', 'medicina', 'inginerie',
      'informatica', 'programare', 'arte', 'muzica', 'sport', 'religie'
    ];
    
    final normalizedQuery = query.toLowerCase().trim();
    return specialSubjects.any((subject) => normalizedQuery.contains(subject));
  }

  // Helper method to get the special subject name from query
  String? _getSpecialSubject(String query) {
    final specialSubjects = [
      'istorie', 'geografie', 'biologie', 'chimie', 'fizica', 'filosofie',
      'sociologie', 'psihologie', 'economie', 'drept', 'medicina', 'inginerie',
      'informatica', 'programare', 'arte', 'muzica', 'sport', 'religie'
    ];
    
    final normalizedQuery = query.toLowerCase().trim();
    for (final subject in specialSubjects) {
      if (normalizedQuery.contains(subject)) {
        return subject;
      }
    }
    return null;
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Modele de examene',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        leading: Container(
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
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Înapoi',
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
        child: Column(
          children: [
            // Search and Filters Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                            hintText: '🔍 Caută modele de examene...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filters Row
                      Row(
                        children: [
                          Flexible(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.surface,
                                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Tip examen',
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.category_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Toate tipurile', style: TextStyle(fontSize: 14))),
                                  DropdownMenuItem(
                                    value: 'EN',
                                    child: Tooltip(
                                      message: 'Evaluare Națională',
                                      child: Row(
                                        children: [
                                          Icon(Icons.school_rounded, color: _getTypeColor('EN'), size: 16),
                                          const SizedBox(width: 6),
                                          const Text('EN', style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'BAC',
                                    child: Tooltip(
                                      message: 'Bacalaureat',
                                      child: Row(
                                        children: [
                                          Icon(Icons.workspace_premium_rounded, color: _getTypeColor('BAC'), size: 16),
                                          const SizedBox(width: 6),
                                          const Text('BAC', style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(() => _selectedType = value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.surface,
                                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Materia',
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.subject_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Toate materiile', style: TextStyle(fontSize: 14))),
                                  DropdownMenuItem(
                                    value: 'Matematica',
                                    child: Row(
                                      children: [
                                        Icon(Icons.functions_rounded, color: _getCategoryColor('Matematica'), size: 16),
                                        const SizedBox(width: 6),
                                        const Text('Matematică', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Romana',
                                    child: Row(
                                      children: [
                                        Icon(Icons.menu_book_rounded, color: _getCategoryColor('Romana'), size: 16),
                                        const SizedBox(width: 6),
                                        const Text('Română', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(() => _selectedCategory = value),
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
            // Content Section
            Expanded(
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
                          Text(
                            'Se încarcă modelele...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredModels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  final isSpecialSubject = _searchController.text.isNotEmpty && 
                                      _isSpecialSubject(_searchController.text);
                                  
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSpecialSubject
                                            ? Icons.schedule_rounded
                                            : (_searchController.text.isNotEmpty || _selectedType != null || _selectedCategory != null
                                                ? Icons.search_off_rounded
                                                : Icons.description_rounded),
                                        size: 56,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchController.text.isNotEmpty && _isSpecialSubject(_searchController.text)
                                    ? 'Vom adăuga examenele de ${_getSpecialSubject(_searchController.text)} în viitor'
                                    : (_searchController.text.isNotEmpty || _selectedType != null || _selectedCategory != null
                                        ? 'Nu s-au găsit modele pentru căutarea ta'
                                        : 'Nu există modele de examene disponibile'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty && _isSpecialSubject(_searchController.text)
                                    ? 'Momentan ne concentrăm pe matematica și română'
                                    : (_searchController.text.isNotEmpty || _selectedType != null || _selectedCategory != null
                                        ? 'Încearcă să modifici termenii de căutare'
                                        : 'Modelele vor apărea aici după ce vor fi adăugate'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredModels.length,
                          itemBuilder: (context, index) {
                            final model = _filteredModels[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 500 + (index * 100)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildExamModelCard(model),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamModelCard(dynamic model) {
    final pdfUrl = model['pdf_file'] != null
        ? (model['pdf_file'].toString().startsWith('http')
            ? model['pdf_file']
            : ApiService.baseUrl + model['pdf_file'])
        : null;
    final typeColor = _getTypeColor(model['type']);
    final categoryColor = _getCategoryColor(model['category']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icons and title
                Row(
                  children: [
                    // Type Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor,
                            typeColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getTypeIcon(model['type']),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(model['category']),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['name'] ?? 'Model fără nume',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Tooltip(
                                message: model['type'] == 'EN' ? 'Evaluare Națională' : 'Bacalaureat',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: typeColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    model['type'] == 'EN' ? 'EN' : 'BAC',
                                    style: TextStyle(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: categoryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  model['category'] == 'Matematica' ? 'Matematică' : 'Română',
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // PDF Button
                    if (pdfUrl != null)
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
                        child: IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _openPdf(pdfUrl),
                          tooltip: 'Deschide PDF',
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
}
