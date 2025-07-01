import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<dynamic> _searchResults = [];
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
    
    print('Initializing SearchBooksScreen - Category: $_selectedCategory');
    _testAuthentication();
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
      print('Filtering books...');
      print('All books: ${_allBooks.length}');
      print('Search query: "$_searchQuery"');
      print('Selected category: $_selectedCategory');
      
      List<dynamic> filtered = _allBooks;
      
      // Filter by category (tab)
      if (_selectedCategory.isNotEmpty) {
        filtered = filtered.where((book) {
          try {
            final bookType = book['type'] ?? 'carte';
            print('Book: ${book['name']}, Type: $bookType, Selected: $_selectedCategory');
            return bookType == _selectedCategory;
          } catch (e) {
            print('Error filtering book by category: $e');
            return false;
          }
        }).toList();
        print('After category filter: ${filtered.length}');
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
            print('Error filtering book by search query: $e');
            return false;
          }
        }).toList();
        print('After search filter: ${filtered.length}');
      }
      
      setState(() {
        _filteredResults = filtered;
      });
      
      print('Final filtered results: ${_filteredResults.length}');
    } catch (e) {
      print('Error in _filterBooks: $e');
      setState(() {
        _filteredResults = [];
      });
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== LOADING BOOKS DEBUG ===');
      print('Loading books...');
      
      // Check authentication first
      final token = await ApiService.getAccessToken();
      print('Authentication token: ${token != null ? "Present" : "Missing"}');
      if (token != null) {
        print('Token preview: ${token.substring(0, 20)}...');
      }
      
      final books = await ApiService.getBooks();
      print('Books loaded: ${books.length}');
      print('Books data: $books');
      
      if (!mounted) return;

      // Add some test data if no books are loaded
      List<dynamic> finalBooks = books;
      if (books.isEmpty) {
        print('No books from API, adding test data');
        finalBooks = [
          {
            'id': 1,
            'name': 'Test Carte 1',
            'author': 'Test Autor 1',
            'category': 'Ficțiune',
            'type': 'carte',
            'thumbnail_url': null,
            'available_copies': 5,
            'inventory': 10,
          },
          {
            'id': 2,
            'name': 'Test Manual 1',
            'author': 'Test Autor 2',
            'category': 'Matematică',
            'type': 'manual',
            'book_class': 'VIII',
            'thumbnail_url': null,
            'available_copies': 3,
            'inventory': 8,
          },
          {
            'id': 3,
            'name': 'Test Carte 2',
            'author': 'Test Autor 3',
            'category': 'Istorie',
            'type': 'carte',
            'thumbnail_url': null,
            'available_copies': 0,
            'inventory': 5,
          },
        ];
      }

      setState(() {
        _allBooks = finalBooks;
        _isLoading = false;
      });
      
      // Apply initial filtering after loading books
      _filterBooks();
      
      print('Books set in state: ${_allBooks.length}');
      print('Filtered results: ${_filteredResults.length}');
      print('=== END LOADING BOOKS DEBUG ===');
    } catch (e) {
      print('=== ERROR LOADING BOOKS ===');
      print('Error loading books: $e');
      print('Error type: ${e.runtimeType}');
      if (!mounted) return;
      
      // Add test data even if API fails
      print('API failed, adding test data');
      final testBooks = [
        {
          'id': 1,
          'name': 'Test Carte 1',
          'author': 'Test Autor 1',
          'category': 'Ficțiune',
          'type': 'carte',
          'thumbnail_url': null,
          'available_copies': 5,
          'inventory': 10,
        },
        {
          'id': 2,
          'name': 'Test Manual 1',
          'author': 'Test Autor 2',
          'category': 'Matematică',
          'type': 'manual',
          'book_class': 'VIII',
          'thumbnail_url': null,
          'available_copies': 3,
          'inventory': 8,
        },
      ];
      
      setState(() {
        _allBooks = testBooks;
        _isLoading = false;
        _errorMessage = null;
      });
      
      // Apply initial filtering after loading test data
      _filterBooks();
      
      print('=== END ERROR LOADING BOOKS ===');
    }
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Do immediate local filtering for responsive UI
    _filterBooks();
    
    // If search is empty, just apply local filtering without reloading from server
    if (value.isEmpty) {
      // Don't reload from server, just show all books for current category
      return;
    }
    
    // Set a new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadBooks();
      }
    });
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

  void _viewPdf(String pdfUrl) async {
    try {
      if (await canLaunch(pdfUrl)) {
        await launch(pdfUrl);
      } else {
        NotificationService.showError(
          context: context,
          message: 'Nu s-a putut deschide PDF-ul.',
        );
      }
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: 'Eroare la deschiderea PDF-ului: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    print('Building SearchBooksScreen');
    print('Filtered results count: ${_filteredResults.length}');
    print('Is loading: $_isLoading');
    
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
    print('Building tab content for category: $category');
    print('Filtered results: ${_filteredResults.length}');
    
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
    print('Rendering ListView with itemCount: ${_filteredResults.length}');
    try {
      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: getResponsiveSpacing(12),
          vertical: getResponsiveSpacing(8),
        ),
        itemCount: _filteredResults.length,
        itemBuilder: (context, index) {
          print('Building item $index of ${_filteredResults.length}');
          if (index < _filteredResults.length) {
            return _buildBookCard(_filteredResults[index]);
          } else {
            return Container(); // Return empty container if index is out of bounds
          }
        },
      );
    } catch (e, st) {
      print('ERROR in ListView.builder: $e\n$st');
      return Center(child: Text('Eroare la afișare: $e'));
    }
  }

  Widget _buildBookCard(dynamic book) {
    try {
      // Validate book data
      if (book == null) {
        print('Book is null');
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

      // Construct PDF URL like in exam models
      final pdfUrl = book['pdf_file'] != null && book['pdf_file'].toString().isNotEmpty
          ? (book['pdf_file'].toString().startsWith('http')
              ? book['pdf_file']
              : ApiService.baseUrl + book['pdf_file'])
          : null;
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
      print('Error building book card: $e');
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

  void _openPdf(String pdfUrl) async {
    print('Opening PDF: $pdfUrl');
    try {
      if (await canLaunch(pdfUrl)) {
        await launch(pdfUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nu s-a putut deschide PDF-ul.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print('Error opening PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la deschiderea PDF-ului: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _testAuthentication() async {
    try {
      print('=== TESTING AUTHENTICATION ===');
      final token = await ApiService.getAccessToken();
      print('Token exists: ${token != null}');
      if (token != null) {
        print('Token length: ${token.length}');
        print('Token preview: ${token.substring(0, 20)}...');
      }
      print('=== END AUTHENTICATION TEST ===');
    } catch (e) {
      print('Authentication test error: $e');
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

// Utility function to convert Arabic numerals to Roman numerals
String _arabicToRoman(int arabic) {
  if (arabic <= 0) return '';
  
  final romanNumerals = [
    [1000, 'M'],
    [900, 'CM'],
    [500, 'D'],
    [400, 'CD'],
    [100, 'C'],
    [90, 'XC'],
    [50, 'L'],
    [40, 'XL'],
    [10, 'X'],
    [9, 'IX'],
    [5, 'V'],
    [4, 'IV'],
    [1, 'I'],
  ];

  String result = '';
  int remaining = arabic;

  for (final pair in romanNumerals) {
    final value = pair[0] as int;
    final numeral = pair[1] as String;
    while (remaining >= value) {
      result += numeral;
      remaining -= value;
    }
  }

  return result;
}
