import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/responsive_service.dart';
import 'edit_book_screen.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({Key? key}) : super(key: key);

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _allBooks = [];
  List<dynamic> _filteredResults = [];
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _selectedCategory = 'carte';
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging && _tabController.index >= 0 && _tabController.index < 2) {
      final newIndex = _tabController.index;
      setState(() {
        _selectedCategory = newIndex == 0 ? 'carte' : 'manual';
        _searchQuery = '';
      });
      _searchController.clear();
      _filterBooks();
    }
  }

  void _filterBooks() {
    try {
      List<dynamic> filtered = List.from(_allBooks);
      if (_selectedCategory.isNotEmpty) {
        filtered = filtered.where((book) => (book['type'] ?? 'carte') == _selectedCategory).toList();
      }
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((book) {
          final title = (book['name'] ?? '').toString().toLowerCase();
          final author = (book['author'] ?? '').toString().toLowerCase();
          final category = (book['category'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || author.contains(query) || category.contains(query);
        }).toList();
      }
      if (mounted) {
        setState(() {
          _filteredResults = filtered;
        });
      }
    } catch (e) {
      print('Error filtering books: $e');
      if (mounted) {
        setState(() {
          _filteredResults = [];
        });
      }
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final books = await ApiService.getBooks();
      setState(() {
        _allBooks = books;
        _isLoading = false;
      });
      _filterBooks();
    } catch (e) {
      setState(() {
        _allBooks = [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _filterBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
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
                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: ResponsiveService.isSmallPhone ? 20 : 24,
              ),
            ),
            SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 12),
            Flexible(
              child: Text(
                ResponsiveService.isSmallPhone ? AppLocalizations.of(context)!.manageBooksShort : AppLocalizations.of(context)!.manageBooksLong,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: ResponsiveService.isSmallPhone ? 18 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: AppLocalizations.of(context)!.backTooltip,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveService.isSmallPhone ? 100 : 120),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveService.isSmallPhone ? 16 : 20, 
              vertical: ResponsiveService.isSmallPhone ? 16 : 24
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                  blurRadius: ResponsiveService.isSmallPhone ? 12 : 16,
                  offset: Offset(0, ResponsiveService.isSmallPhone ? 4 : 6),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
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
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                ),
                unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                      child: Icon(
                        Icons.book_rounded,
                        size: ResponsiveService.isSmallPhone ? 20 : 24,
                      ),
                    ),
                    text: AppLocalizations.of(context)!.books,
                  ),
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: ResponsiveService.isSmallPhone ? 20 : 24,
                      ),
                    ),
                    text: AppLocalizations.of(context)!.manuals,
                  ),
                ],
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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveService.isSmallPhone ? 12 : 16, 
                  ResponsiveService.isSmallPhone ? 6 : 8, 
                  ResponsiveService.isSmallPhone ? 12 : 16, 
                  ResponsiveService.isSmallPhone ? 8 : 12
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
                        offset: Offset(0, ResponsiveService.isSmallPhone ? 2 : 4),
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
                          ? AppLocalizations.of(context)!.searchBooksShort
                          : AppLocalizations.of(context)!.searchBooksLong,
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        fontSize: ResponsiveService.isSmallPhone ? 14 : null,
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
                                  onPressed: () {
                                    _debounceTimer?.cancel();
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _filterBooks();
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
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                        vertical: ResponsiveService.isSmallPhone ? 12 : 16,
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      setState(() {
                        _searchQuery = value;
                      });
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _filterBooks();
                        }
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Cărți Tab
                    _buildTabContent('carte'),
                    // Manuale Tab
                    _buildTabContent('manual'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildTabContent(String category) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (!_isLoading && _filteredResults.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category == 'carte' ? Icons.book_rounded : Icons.menu_book_rounded,
                size: ResponsiveService.isSmallPhone ? 48 : 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
              Text(
                _searchQuery.isNotEmpty 
                    ? AppLocalizations.of(context)!.noBookFoundFor(_searchQuery)
                    : category == 'carte' ? AppLocalizations.of(context)!.noBooksInLibrary : AppLocalizations.of(context)!.noManualsInLibrary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveService.isSmallPhone ? 48 : 64,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveService.isSmallPhone ? 12 : 16),
              ElevatedButton.icon(
                onPressed: _loadBooks,
                icon: Icon(Icons.refresh, size: ResponsiveService.isSmallPhone ? 16 : 18),
                label: Text(
                  AppLocalizations.of(context)!.reload,
                  style: TextStyle(fontSize: ResponsiveService.isSmallPhone ? 12 : null),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveService.isSmallPhone ? 16 : 20,
                    vertical: ResponsiveService.isSmallPhone ? 8 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveService.isSmallPhone ? 12 : 16, 
        vertical: ResponsiveService.isSmallPhone ? 6 : 8
      ),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) {
          if (index >= _filteredResults.length) {
            return const SizedBox.shrink();
          }
          final book = _filteredResults[index];
          return Padding(
            padding: EdgeInsets.only(bottom: ResponsiveService.isSmallPhone ? 12 : 16),
            child: _buildBookCard(book),
          );
        },
      ),
    );
  }

  Widget _buildBookCard(dynamic book) {
    final String? thumbnailUrl = book['thumbnail_url'] != null
        ? (book['thumbnail_url'].toString().startsWith('http')
            ? book['thumbnail_url']
            : ApiService.baseUrl + '/media/' + book['thumbnail_url'].toString().replaceAll(RegExp(r'^/?media/'), ''))
        : null;

    return GestureDetector(
      onTap: () => _navigateToEditBook(book),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: ResponsiveService.isSmallPhone ? 120 : 140,
          maxWidth: MediaQuery.of(context).size.width - (ResponsiveService.isSmallPhone ? 24 : 32),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: ResponsiveService.isSmallPhone ? 8 : 12,
              offset: Offset(0, ResponsiveService.isSmallPhone ? 2 : 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
          child: ResponsiveService.isSmallPhone 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover and basic info row for small screens
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Cover
                        Container(
                          width: ResponsiveService.isSmallPhone ? 50 : 60,
                          height: ResponsiveService.isSmallPhone ? 70 : 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                                offset: Offset(0, ResponsiveService.isSmallPhone ? 3 : 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 10 : 12),
                            child: thumbnailUrl != null
                                ? Image.network(
                                    thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          book['type'] == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                          size: ResponsiveService.isSmallPhone ? 24 : 30,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      book['type'] == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                      size: ResponsiveService.isSmallPhone ? 24 : 30,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: ResponsiveService.isSmallPhone ? 10 : 12),
                        // Basic Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                book['name'] ?? AppLocalizations.of(context)!.unknownBook,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: ResponsiveService.isSmallPhone ? 14 : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: ResponsiveService.isSmallPhone ? 2 : 4),
                              // Author
                              Text(
                                book['author'] ?? AppLocalizations.of(context)!.unknownAuthor,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: ResponsiveService.isSmallPhone ? 12 : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 12),
                    // Category and Class tags
                    Wrap(
                      spacing: ResponsiveService.isSmallPhone ? 6 : 8,
                      runSpacing: ResponsiveService.isSmallPhone ? 6 : 8,
                      children: [
                        // Category
                        if (book['category'] != null && book['category'].toString().isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveService.isSmallPhone ? 8 : 10, 
                              vertical: ResponsiveService.isSmallPhone ? 3 : 4
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 8 : 10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              book['category'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveService.isSmallPhone ? 10 : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        // Class info for manuals
                        if (book['type'] == 'manual' && book['book_class'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveService.isSmallPhone ? 8 : 10, 
                              vertical: ResponsiveService.isSmallPhone ? 3 : 4
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 8 : 10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: ResponsiveService.isSmallPhone ? 10 : 12,
                                ),
                                SizedBox(width: ResponsiveService.isSmallPhone ? 1 : 2),
                                Text(
                                  AppLocalizations.of(context)!.classLabel(book['book_class']),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: ResponsiveService.isSmallPhone ? 10 : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 12),
                    // Stock and action buttons
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 5 : 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 8 : 10),
                          ),
                          child: Icon(
                            Icons.inventory_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: ResponsiveService.isSmallPhone ? 14 : 16,
                          ),
                        ),
                        SizedBox(width: ResponsiveService.isSmallPhone ? 6 : 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.stockLabel(book['stock'].toString(), book['inventory'].toString()),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: ResponsiveService.isSmallPhone ? 9 : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: ResponsiveService.isSmallPhone ? 6 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveService.isSmallPhone ? 8 : 12, 
                            vertical: ResponsiveService.isSmallPhone ? 4 : 6
                          ),
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
                                blurRadius: ResponsiveService.isSmallPhone ? 4 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: ResponsiveService.isSmallPhone ? 12 : 14,
                              ),
                              SizedBox(width: ResponsiveService.isSmallPhone ? 3 : 4),
                              Text(
                                AppLocalizations.of(context)!.edit,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveService.isSmallPhone ? 10 : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover
                    Container(
                      width: ResponsiveService.isMediumPhone ? 70 : 80,
                      height: ResponsiveService.isMediumPhone ? 105 : 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: thumbnailUrl != null
                            ? Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      book['type'] == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                      size: ResponsiveService.isMediumPhone ? 35 : 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  book['type'] == 'manual' ? Icons.menu_book_rounded : Icons.book_rounded,
                                  size: ResponsiveService.isMediumPhone ? 35 : 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: ResponsiveService.isMediumPhone ? 12 : 16),
                    // Book Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            book['name'] ?? AppLocalizations.of(context)!.unknownBook,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: ResponsiveService.isMediumPhone ? 18 : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveService.isMediumPhone ? 6 : 8),
                          // Author
                          Text(
                            book['author'] ?? AppLocalizations.of(context)!.unknownAuthor,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveService.isMediumPhone ? 14 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: ResponsiveService.isMediumPhone ? 10 : 12),
                          // Category and Class Info Row
                          Wrap(
                            spacing: ResponsiveService.isMediumPhone ? 6 : 8,
                            runSpacing: ResponsiveService.isMediumPhone ? 6 : 8,
                            children: [
                              // Category
                              if (book['category'] != null && book['category'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    book['category'],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              // Class info for manuals
                              if (book['type'] == 'manual' && book['book_class'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!.classLabel(book['book_class']),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stock info and Edit button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.stockLabel(book['stock'].toString(), book['inventory'].toString()),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: ResponsiveService.isMediumPhone ? 12 : 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context)!.edit,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
        ),
      ),
    );
  }

  Future<void> _navigateToEditBook(dynamic book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookScreen(book: book),
      ),
    );
    if (result != null) {
      _loadBooks();
    }
  }
}
