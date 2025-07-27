import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_book_card.dart';
import 'book_details_screen.dart';

class SearchBooksScreen extends StatefulWidget {
  const SearchBooksScreen({Key? key}) : super(key: key);

  @override
  State<SearchBooksScreen> createState() => _SearchBooksScreenState();
}

class _SearchBooksScreenState extends State<SearchBooksScreen>
    with TickerProviderStateMixin, ResponsiveWidget {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _filteredResults = [];
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = '';
  Timer? _debounceTimer;
  List<dynamic> _allBooks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Initialize category based on initial tab (first tab is carti)
    _selectedCategory = 'carte'; // Default to carte tab
    
    _loadBooks(); // Load all books when screen opens
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _tabController.index == 0 ? 'carte' : 'manual';
        _isLoading = true;
        // Clear search when changing tabs
        _searchQuery = '';
      });
      
      // Clear search controller
      _searchController.clear();
      
      // Apply filtering for the new tab
      _filterBooks();
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterBooks() {
    try {
      List<dynamic> filtered = _allBooks;
      
      // Filter by category (tab)
      if (_selectedCategory.isNotEmpty) {
        filtered = filtered.where((book) {
          final bookType = book['type'] ?? 'carte';
          return bookType == _selectedCategory;
        }).toList();
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((book) {
          try {
            final title = (book['name'] ?? '').toString().toLowerCase();
            final author = (book['author'] ?? '').toString().toLowerCase();
            final category = (book['category'] ?? '').toString().toLowerCase();
            final bookClass = (book['book_class'] ?? '').toString().toLowerCase();
            
            final query = _searchQuery.toLowerCase();
            
            // Check if query matches title, author, or category
            if (title.contains(query) || author.contains(query) || category.contains(query)) {
              return true;
            }
            
            // For manuals, also check class (both Roman and Arabic numerals)
            if (book['type'] == 'manual' && bookClass.isNotEmpty) {
              try {
                // Convert Roman numerals to Arabic for comparison
                final arabicClass = _romanToArabic(bookClass.toUpperCase()).toString();
                if (bookClass.contains(query) || arabicClass.contains(query)) {
                  return true;
                }
              } catch (e) {
                // If conversion fails, just check the original class string
                if (bookClass.contains(query)) {
                  return true;
                }
              }
            }
            
            return false;
          } catch (e) {
            return false;
          }
        }).toList();
      }
      
      setState(() {
        _filteredResults = filtered;
      });
    } catch (e) {
      setState(() {
        _filteredResults = [];
      });
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await ApiService.getBooks();
      
      if (!mounted) return;

      setState(() {
        _allBooks = books;
        _isLoading = false;
      });
      
      // Apply initial filtering after loading books
      _filterBooks();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _allBooks = [];
        _isLoading = false;
        _errorMessage = 'Eroare la încărcarea cărților: ${e.toString()}';
      });
    }
  }

  Future<void> _showLoanDurationDialog(int bookId) async {
    int selectedDuration = 14; // Default to 2 weeks

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selectează durata împrumutului'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<int>(
                  title: const Text('1 Săptămână'),
                  value: 7,
                  groupValue: selectedDuration,
                  onChanged: (value) =>
                      setState(() => selectedDuration = value!),
                ),
                RadioListTile<int>(
                  title: const Text('2 Săptămâni'),
                  value: 14,
                  groupValue: selectedDuration,
                  onChanged: (value) =>
                      setState(() => selectedDuration = value!),
                ),
                RadioListTile<int>(
                  title: const Text('1 Lună'),
                  value: 30,
                  groupValue: selectedDuration,
                  onChanged: (value) =>
                      setState(() => selectedDuration = value!),
                ),
                RadioListTile<int>(
                  title: const Text('2 Luni'),
                  value: 60,
                  groupValue: selectedDuration,
                  onChanged: (value) =>
                      setState(() => selectedDuration = value!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedDuration),
            child: const Text('Confirmă'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _requestBook(bookId, result);
    }
  }

  Future<void> _requestBook(int bookId, [int loanDurationDays = 14]) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.requestBook(
        bookId: bookId,
        loanDurationDays: loanDurationDays,
      );

      if (!mounted) return;

      NotificationService.showSuccess(
        context: context,
        message: 'Cerere de împrumut înregistrată cu succes!',
      );
    } catch (e) {
      if (!mounted) return;

      NotificationService.showError(
        context: context,
        message: 'Eroare la solicitarea cărții/manualului: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
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
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: getResponsiveIconSize(24),
                ),
              ),
              SizedBox(width: getResponsiveSpacing(12)),
              Text(
                'Căutare Cărți',
                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          automaticallyImplyLeading: false,
          leading: Container(
          margin: EdgeInsets.only(left: getResponsiveSpacing(8)),
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: getResponsiveBorderRadius(6),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: getResponsiveIconSize(20),
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Înapoi',
          ),
        ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(getResponsiveSpacing(120)),
            child: Container(
              margin: getResponsivePadding(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
                borderRadius: getResponsiveBorderRadius(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                    blurRadius: getResponsiveSpacing(16),
                    offset: Offset(0, getResponsiveSpacing(6)),
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
                  borderRadius: getResponsiveBorderRadius(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: getResponsiveSpacing(8),
                      offset: Offset(0, getResponsiveSpacing(2)),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(8)),
                      child: Icon(
                        Icons.book_rounded,
                        size: getResponsiveIconSize(24),
                      ),
                    ),
                    text: 'Cărți',
                  ),
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(8)),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: getResponsiveIconSize(24),
                      ),
                    ),
                    text: 'Manuale',
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
                padding: getResponsivePadding(all: 16),
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
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: getResponsiveSpacing(12),
                        offset: Offset(0, getResponsiveSpacing(4)),
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
                          ? 'Caută cărți și manuale...'
                          : 'Caută după titlu, autor, categorie sau clasă (ex: VIII sau 8)...',
                      hintStyle: ResponsiveTextStyles.getResponsiveTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
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
                      suffixIcon: _searchController.text.isNotEmpty
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
                                    size: getResponsiveIconSize(20),
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
                        borderRadius: getResponsiveBorderRadius(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: getResponsiveBorderRadius(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: getResponsiveBorderRadius(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: getResponsiveSpacing(20),
                        vertical: getResponsiveSpacing(16),
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
      ),
    );
  }

  Widget _buildTabContent(String category) {
    // DO NOT update _selectedCategory or call _filterBooks here!
    // Just use the filtered list as is.

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    // Only show the list if not loading and there are results
    if (!_isLoading && _filteredResults.isEmpty) {
      return Center(child: Text('Nu există cărți/manuale.'));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    try {
      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: getResponsiveSpacing(12),
          vertical: getResponsiveSpacing(8),
        ),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) {
          if (index < _filteredResults.length) {
            return _buildBookCard(_filteredResults[index]);
          } else {
            return Container(); // Return empty container if index is out of bounds
          }
        },
      );
    } catch (e) {
      return Center(child: Text('Eroare la afișare: $e'));
    }
  }

  Widget _buildBookCard(dynamic book) {
    try {
      // Validate book data
      if (book == null) {
        return Container(
          margin: EdgeInsets.only(bottom: getResponsiveSpacing(6)),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(getResponsiveSpacing(16)),
              child: Text(
                'Carte invalidă',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        );
      }

      // Construct thumbnail URL robustly
      final thumbnailUrl = book['thumbnail_url'] != null && book['thumbnail_url'].toString().isNotEmpty
          ? (book['thumbnail_url'].toString().startsWith('http')
              ? book['thumbnail_url']
              : ApiService.baseUrl + '/media/' + book['thumbnail_url'].toString().replaceAll(RegExp(r'^/?media/'), ''))
          : null;
      
      return Container(
        margin: EdgeInsets.only(bottom: getResponsiveSpacing(6)),
        child: ResponsiveBookCard(
          title: book['name']?.toString() ?? 'Carte necunoscută',
          author: book['author']?.toString() ?? 'Autor necunoscut',
          category: book['category']?.toString() ?? 'Fără categorie',
          thumbnailUrl: thumbnailUrl,
          bookClass: book['book_class']?.toString(),
          bookType: book['type']?.toString() ?? 'carte',
          availableCopies: book['available_copies'] is int ? book['available_copies'] : null,
          totalCopies: null, // Only show available copies, not total
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookDetailsScreen(book: book),
              ),
            );
          },
          onViewPdf: null,
          onRequestBook: (book['id'] != null) ? () => _showLoanDurationDialog(book['id']) : null,
          showActions: false,
          isLoading: _isLoading,
        ),
      );
    } catch (e) {
      return Container(
        margin: EdgeInsets.only(bottom: getResponsiveSpacing(6)),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(getResponsiveSpacing(16)),
            child: Text(
              'Eroare la afișarea cărții',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }
  }
}

// Utility function to convert Roman numerals to Arabic numerals
int _romanToArabic(String roman) {
  if (roman.isEmpty) return 0;
  
  final romanNumerals = {
    'I': 1,
    'V': 5,
    'X': 10,
    'L': 50,
    'C': 100,
    'D': 500,
    'M': 1000,
  };

  int result = 0;
  int prevValue = 0;

  for (int i = roman.length - 1; i >= 0; i--) {
    final currentChar = roman[i];
    final currentValue = romanNumerals[currentChar] ?? 0;
    
    if (currentValue == 0) {
      // Invalid character, skip it
      continue;
    }
    
    if (currentValue >= prevValue) {
      result += currentValue;
    } else {
      result -= currentValue;
    }
    prevValue = currentValue;
  }

  return result;
}
