import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/responsive_text_field.dart';
import '../widgets/responsive_dialog.dart';
import './add_exam_model_screen.dart';

class ExamModel {
  String name;
  String type; // 'EN' or 'BAC'
  String pdfFileName;
  ExamModel(
      {required this.name, required this.type, required this.pdfFileName});
}

class ExamModelsAdminScreen extends StatefulWidget {
  const ExamModelsAdminScreen({Key? key}) : super(key: key);

  @override
  State<ExamModelsAdminScreen> createState() => _ExamModelsAdminScreenState();
}

class _ExamModelsAdminScreenState extends State<ExamModelsAdminScreen>
    with TickerProviderStateMixin, ResponsiveWidget {
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
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredModels {
    return _models.where((model) {
      final typeMatch = _selectedType == null || model['type'] == _selectedType;
      final categoryMatch = _selectedCategory == null || model['category'] == _selectedCategory;
      final nameMatch = model['name'] != null && model['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      return typeMatch && categoryMatch && nameMatch;
    }).toList();
  }

  Future<void> _fetchExamModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await ApiService.fetchExamModels();
      print('Fetched models: ' + models.toString());
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching models: ' + e.toString());
      NotificationService.showError(
        context: context,
        message: 'Eroare la încărcarea modelelor: $e',
      );
    }
  }

  Future<void> _addExamModel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExamModelScreen(),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      await _fetchExamModels();
    }
  }

  Future<void> _deleteModel(int id) async {
    try {
      await ApiService.deleteExamModel(id);
      await _fetchExamModels();
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la ștergere: $e',
      );
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
                  Icons.description_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: getResponsiveIconSize(24),
                ),
              ),
              SizedBox(width: getResponsiveSpacing(12)),
              Text(
                'Modele de teste',
                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        leading: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.only(left: getResponsiveSpacing(8)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: getResponsiveBorderRadius(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: getResponsiveIconSize(24),
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Înapoi',
            ),
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.only(right: getResponsiveSpacing(8)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: getResponsiveBorderRadius(10),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: getResponsiveIconSize(24),
                ),
                onPressed: _fetchExamModels,
                tooltip: 'Reîmprospătează',
              ),
            ),
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
        child: Column(
          children: [
            // Search and Filters Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: getResponsivePadding(all: 16),
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
                          borderRadius: getResponsiveBorderRadius(25),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                              blurRadius: getResponsiveSpacing(8),
                              offset: Offset(0, getResponsiveSpacing(2)),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '🔍 Caută modele de teste...',
                            hintStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              margin: EdgeInsets.all(getResponsiveSpacing(8)),
                              padding: EdgeInsets.all(getResponsiveSpacing(10)),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: getResponsiveBorderRadius(12),
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: getResponsiveIconSize(24),
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      margin: EdgeInsets.all(getResponsiveSpacing(8)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: getResponsiveBorderRadius(10),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: getResponsiveIconSize(24),
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
                              borderRadius: getResponsiveBorderRadius(25),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: getResponsiveBorderRadius(25),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: getResponsiveBorderRadius(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: getResponsiveSpacing(20),
                              vertical: getResponsiveSpacing(18),
                            ),
                          ),
                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      SizedBox(height: getResponsiveSpacing(16)),
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
                                borderRadius: getResponsiveBorderRadius(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: getResponsiveSpacing(8),
                                    offset: Offset(0, getResponsiveSpacing(2)),
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
                                  labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: getResponsiveBorderRadius(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: getResponsiveBorderRadius(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: getResponsiveBorderRadius(25),
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
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.category_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(value: null, child: Text('Toate tipurile', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 14))),
                                  DropdownMenuItem(
                                    value: 'EN',
                                    child: Tooltip(
                                      message: 'Evaluare Națională',
                                      child: Row(
                                        children: [
                                          Icon(Icons.school_rounded, color: _getTypeColor('EN'), size: getResponsiveIconSize(16)),
                                          SizedBox(width: getResponsiveSpacing(6)),
                                          Text('EN', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 14)),
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
                                          Icon(Icons.workspace_premium_rounded, color: _getTypeColor('BAC'), size: getResponsiveIconSize(16)),
                                          SizedBox(width: getResponsiveSpacing(6)),
                                          Text('BAC', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(() => _selectedType = value),
                              ),
                            ),
                          ),
                          SizedBox(width: getResponsiveSpacing(8)),
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
                                borderRadius: getResponsiveBorderRadius(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: getResponsiveSpacing(8),
                                    offset: Offset(0, getResponsiveSpacing(2)),
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
                                  labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: getResponsiveBorderRadius(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: getResponsiveBorderRadius(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: getResponsiveBorderRadius(25),
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
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.subject_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(value: null, child: Text('Toate materiile', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 14))),
                                  DropdownMenuItem(
                                    value: 'Matematica',
                                    child: Row(
                                      children: [
                                        Icon(Icons.functions_rounded, color: _getCategoryColor('Matematica'), size: getResponsiveIconSize(16)),
                                        SizedBox(width: getResponsiveSpacing(6)),
                                        Text('Matematică', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Romana',
                                    child: Row(
                                      children: [
                                        Icon(Icons.menu_book_rounded, color: _getCategoryColor('Romana'), size: getResponsiveIconSize(16)),
                                        SizedBox(width: getResponsiveSpacing(6)),
                                        Text('Română', style: ResponsiveTextStyles.getResponsiveTextStyle(fontSize: 14)),
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
                      SizedBox(height: getResponsiveSpacing(16)),
                      // Add Button
                      Container(
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
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: getResponsiveSpacing(8),
                              offset: Offset(0, getResponsiveSpacing(2)),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _addExamModel,
                          icon: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.onPrimary),
                          label: Text(
                            'Adaugă model de examen',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: getResponsiveSpacing(32),
                              vertical: getResponsiveSpacing(16),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: getResponsiveBorderRadius(16),
                            ),
                          ),
                        ),
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
                                  padding: EdgeInsets.all(getResponsiveSpacing(20)),
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
                          SizedBox(height: getResponsiveSpacing(24)),
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
                                duration: const Duration(milliseconds: 800),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  final isSpecialSubject = _searchController.text.isNotEmpty && 
                                      _isSpecialSubject(_searchController.text);
                                  
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: EdgeInsets.all(getResponsiveSpacing(24)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSpecialSubject
                                            ? Icons.schedule_rounded
                                            : (_searchController.text.isNotEmpty || _selectedType != null || _selectedCategory != null
                                                ? Icons.search_off_rounded
                                                : Icons.quiz_outlined),
                                        size: getResponsiveIconSize(56),
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: getResponsiveSpacing(24)),
                              Text(
                                _searchController.text.isNotEmpty && _isSpecialSubject(_searchController.text)
                                    ? 'Vom adăuga testele de ${_getSpecialSubject(_searchController.text)} în viitor'
                                    : (_searchController.text.isNotEmpty || _selectedType != null || _selectedCategory != null
                                        ? 'Nu s-au găsit modele pentru căutarea ta'
                                        : 'Nu există modele de teste'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              Text(
                                _searchController.text.isNotEmpty && _isSpecialSubject(_searchController.text)
                                    ? 'Momentan ne concentrăm pe matematica și română'
                                    : (_searchController.text.isNotEmpty || _selectedType != null || _selectedCategory != null
                                        ? 'Încearcă să modifici termenii de căutare'
                                        : 'Adaugă primul model de examen'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ListView.builder(
                              padding: EdgeInsets.all(getResponsiveSpacing(16)),
                              itemCount: _filteredModels.length,
                              itemBuilder: (context, index) {
                                final model = _filteredModels[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 400 + (index * 100)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, getResponsiveSpacing(20) * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: _buildModelCard(model, index),
                                      ),
                                    );
                                  },
                                );
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

  Widget _buildModelCard(dynamic model, int index) {
    final pdfUrl = model['pdf_file'] != null
        ? (model['pdf_file'].toString().startsWith('http')
            ? model['pdf_file']
            : ApiService.baseUrl + model['pdf_file'])
        : null;
    final typeColor = _getTypeColor(model['type']);
    final categoryColor = _getCategoryColor(model['category']);

    return Container(
      margin: EdgeInsets.only(bottom: getResponsiveSpacing(16)),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: getResponsiveBorderRadius(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: getResponsiveBorderRadius(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(getResponsiveSpacing(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icons and title
                Row(
                  children: [
                    // Type Icon
                    Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(12)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor,
                            typeColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: getResponsiveBorderRadius(12),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withOpacity(0.3),
                            blurRadius: getResponsiveSpacing(8),
                            offset: Offset(0, getResponsiveSpacing(2)),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getTypeIcon(model['type']),
                        color: Colors.white,
                        size: getResponsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: getResponsiveSpacing(12)),
                    // Category Icon
                    Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(12)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: getResponsiveBorderRadius(12),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: getResponsiveSpacing(8),
                            offset: Offset(0, getResponsiveSpacing(2)),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(model['category']),
                        color: Colors.white,
                        size: getResponsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: getResponsiveSpacing(16)),
                    // Title and Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['name'] ?? 'Model fără nume',
                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: getResponsiveSpacing(8)),
                          Wrap(
                            spacing: getResponsiveSpacing(8),
                            runSpacing: getResponsiveSpacing(4),
                            children: [
                              Tooltip(
                                message: model['type'] == 'EN' ? 'Evaluare Națională' : 'Bacalaureat',
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: getResponsiveSpacing(8), vertical: getResponsiveSpacing(4)),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: getResponsiveBorderRadius(12),
                                    border: Border.all(
                                      color: typeColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    model['type'] == 'EN' ? 'EN' : 'BAC',
                                    style: ResponsiveTextStyles.getResponsiveTextStyle(
                                      fontSize: 12,
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: getResponsiveSpacing(8), vertical: getResponsiveSpacing(4)),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: getResponsiveBorderRadius(12),
                                  border: Border.all(
                                    color: categoryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  model['category'] == 'Matematica' ? 'Matematică' : 'Română',
                                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                                    fontSize: 12,
                                    color: categoryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PDF Button
                        if (pdfUrl != null)
                          Container(
                            margin: EdgeInsets.only(right: getResponsiveSpacing(8)),
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
                            child: IconButton(
                              icon: Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.white,
                                size: getResponsiveIconSize(24),
                              ),
                              onPressed: () => _openPdf(pdfUrl),
                              tooltip: 'Deschide PDF',
                            ),
                          ),
                        // Delete Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.error,
                                Theme.of(context).colorScheme.error.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: getResponsiveBorderRadius(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                                blurRadius: getResponsiveSpacing(8),
                                offset: Offset(0, getResponsiveSpacing(2)),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: getResponsiveIconSize(24),
                            ),
                            onPressed: () => _deleteModel(model['id']),
                            tooltip: 'Șterge model',
                          ),
                        ),
                      ],
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
        return Icons.quiz_rounded;
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

  Future<void> _openPdf(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        NotificationService.showWarning(
          context: context,
          message: 'Nu s-a putut deschide PDF-ul.',
        );
      }
    } catch (e) {
      NotificationService.showWarning(
        context: context,
        message: 'Eroare la deschiderea PDF: ${e.toString()}',
      );
    }
  }
}
