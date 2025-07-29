import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _pendingRequests = [];
  List<dynamic> _approvedRequests = [];
  List<dynamic> _filteredPendingRequests = [];
  List<dynamic> _filteredApprovedRequests = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
    _searchController.addListener(_filterRequests);
    
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
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all requests to include both pending and approved
      final allRequests = await ApiService.getAllBookRequests();
      setState(() {
        _pendingRequests =
            allRequests.where((r) => r['status'] == 'IN_ASTEPTARE').toList();
        _approvedRequests =
            allRequests.where((r) => r['status'] == 'APROBAT').toList();
        _filteredPendingRequests = _pendingRequests;
        _filteredApprovedRequests = _approvedRequests;
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

  void _filterRequests() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _searchQuery = query;
      
      if (query.isEmpty) {
        _filteredPendingRequests = _pendingRequests;
        _filteredApprovedRequests = _approvedRequests;
      } else {
        _filteredPendingRequests = _pendingRequests.where((request) {
          final bookName = request['book']['name']?.toLowerCase() ?? '';
          final studentName = request['student']['user']['display_name']?.toLowerCase() ?? '';
          return bookName.contains(query) || studentName.contains(query);
        }).toList();
        
        _filteredApprovedRequests = _approvedRequests.where((request) {
          final bookName = request['book']['name']?.toLowerCase() ?? '';
          final studentName = request['student']['user']['display_name']?.toLowerCase() ?? '';
          return bookName.contains(query) || studentName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleRequest(String requestId, bool approve) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (approve) {
        await ApiService.approveRequest(borrowingId: int.parse(requestId));
        if (!mounted) return;
        NotificationService.showSuccess(
          context: context,
          message: AppLocalizations.of(context)!.requestApprovedSuccess,
        );
      } else {
        await ApiService.rejectRequest(borrowingId: int.parse(requestId));
        if (!mounted) return;
        NotificationService.showSuccess(
          context: context,
          message: AppLocalizations.of(context)!.requestRejectedSuccess,
        );
      }
      await _loadRequests();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (!mounted) return;
      NotificationService.showError(
        context: context,
        message: 'Eroare: \\${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsPickedUp(String requestId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.markPickup(int.parse(requestId));
      if (!mounted) return;
      NotificationService.showSuccess(
        context: context,
        message: AppLocalizations.of(context)!.bookMarkedAsPickedUp,
      );
      await _loadRequests();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (!mounted) return;
      NotificationService.showError(
        context: context,
        message: 'Eroare: \\${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        toolbarHeight: ResponsiveService.isSmallPhone ? 70 : 80,
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
                  Icons.pending_actions_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: ResponsiveService.isSmallPhone ? 20 : 24,
                ),
              ),
              SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 12),
              Flexible(
                child: Text(
                  ResponsiveService.isSmallPhone ? AppLocalizations.of(context)!.bookRequestsTitle : AppLocalizations.of(context)!.bookManualsRequestsTitle,
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
              onPressed: () => Navigator.pop(context),
              tooltip: AppLocalizations.of(context)!.back,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveService.isSmallPhone ? 100 : 120),
          child: FadeTransition(
            opacity: _fadeAnimation,
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
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                  letterSpacing: 0.5,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                      child: Icon(
                        Icons.pending_actions_rounded,
                        size: ResponsiveService.isSmallPhone ? 20 : 24,
                      ),
                    ),
                    text: ResponsiveService.isSmallPhone ? AppLocalizations.of(context)!.pending : AppLocalizations.of(context)!.pending,
                  ),
                  Tab(
                    icon: Container(
                      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 6 : 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: ResponsiveService.isSmallPhone ? 20 : 24,
                      ),
                    ),
                    text: AppLocalizations.of(context)!.approved,
                  ),
                ],
              ),
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
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
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
                          AppLocalizations.of(context)!.loadingRequests,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
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
                              onPressed: _loadRequests,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(AppLocalizations.of(context)!.retry),
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
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Search Bar
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveService.isSmallPhone ? 16 : 24, 
                                vertical: ResponsiveService.isSmallPhone ? 6 : 8
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
                                        ? AppLocalizations.of(context)!.searchPlaceholder 
                                        : AppLocalizations.of(context)!.searchDetailedPlaceholder,
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
                            // TabBarView
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildRequestsList(
                                    _filteredPendingRequests,
                                    showActions: true,
                                    emptyMessage: AppLocalizations.of(context)!.noPendingRequests,
                                  ),
                                  _buildRequestsList(
                                    _filteredApprovedRequests,
                                    showActions: false,
                                    emptyMessage: AppLocalizations.of(context)!.noApprovedRequests,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<dynamic> requests,
      {required bool showActions, required String emptyMessage}) {
    if (requests.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(ResponsiveService.isSmallPhone ? 24 : 32),
          padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 20 : 24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: ResponsiveService.isSmallPhone ? 12 : 16,
                offset: Offset(0, ResponsiveService.isSmallPhone ? 4 : 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isNotEmpty 
                      ? Icons.search_off_rounded 
                      : (showActions ? Icons.pending_actions_rounded : Icons.check_circle_rounded),
                  size: ResponsiveService.isSmallPhone ? 40 : 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: ResponsiveService.isSmallPhone ? 16 : 24),
              Text(
                _searchQuery.isNotEmpty 
                    ? AppLocalizations.of(context)!.noSearchResults(_searchQuery)
                    : emptyMessage,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                  fontSize: ResponsiveService.isSmallPhone ? 18 : null,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveService.isSmallPhone ? 6 : 8),
              Text(
                _searchQuery.isNotEmpty
                    ? AppLocalizations.of(context)!.modifySearchTerms
                    : (showActions 
                        ? AppLocalizations.of(context)!.noRequestsNeedApproval
                        : AppLocalizations.of(context)!.noApprovedRequestsCurrently),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveService.isSmallPhone ? 13 : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 16 : 20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
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
                                      size: ResponsiveService.isSmallPhone ? 20 : 24,
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
                                              toTitleCase(request['student']['user']['display_name'] ?? 
                                                  '${request['student']['user']['first_name']} ${request['student']['user']['last_name']}'),
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: ResponsiveService.isSmallPhone ? 16 : 18,
                                              ),
                                            ),
                                            SizedBox(width: ResponsiveService.isSmallPhone ? 8 : 10),
                                            Text(
                                              request['student']['user']['email'] ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                fontWeight: FontWeight.w500,
                                                fontSize: ResponsiveService.isSmallPhone ? 12 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: ResponsiveService.isSmallPhone ? 6 : 8),
                                        // Student class information and status badge
                                        Row(
                                          children: [
                                            // Student class information - bigger
                                            Builder(
                                              builder: (context) {
                                                final studentId = request['student']['student_id']?.toString() ?? '';
                                                final isTeacher = studentId.startsWith('T');
                                                
                                                if (isTeacher) {
                                                  return Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: ResponsiveService.isSmallPhone ? 6 : 8, 
                                                      vertical: ResponsiveService.isSmallPhone ? 3 : 4
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Colors.blue.withOpacity(0.3),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      AppLocalizations.of(context)!.teacher,
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Colors.blue[700],
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: ResponsiveService.isSmallPhone ? 10 : 12,
                                                      ),
                                                    ),
                                                  );
                                                } else if (request['student']['student_class'] != null || request['student']['department'] != null) {
                                                  return Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: ResponsiveService.isSmallPhone ? 6 : 8, 
                                                      vertical: ResponsiveService.isSmallPhone ? 3 : 4
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '${request['student']['school_type'] ?? ''} ${request['student']['student_class'] ?? ''} ${request['student']['department'] ?? ''}'.trim(),
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: ResponsiveService.isSmallPhone ? 10 : 12,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                            const Spacer(),
                                            // Status badge
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: ResponsiveService.isSmallPhone ? 6 : 10, 
                                                vertical: ResponsiveService.isSmallPhone ? 3 : 5
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: showActions 
                                                    ? [const Color(0xFFFFA726), const Color(0xFFFF9800)] // Orange for pending
                                                    : [const Color(0xFF66BB6A), const Color(0xFF4CAF50)], // Green for approved
                                                ),
                                                borderRadius: BorderRadius.circular(ResponsiveService.isSmallPhone ? 14 : 18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (showActions ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)).withOpacity(0.3),
                                                    blurRadius: ResponsiveService.isSmallPhone ? 6 : 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    showActions ? Icons.pending_rounded : Icons.check_circle_rounded,
                                                    color: Colors.white,
                                                    size: ResponsiveService.isSmallPhone ? 12 : 14,
                                                  ),
                                                  SizedBox(width: ResponsiveService.isSmallPhone ? 3 : 5),
                                                  Text(
                                                    showActions ? AppLocalizations.of(context)!.pending : AppLocalizations.of(context)!.approved,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: ResponsiveService.isSmallPhone ? 9 : 11,
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
                                      child: request['book']['thumbnail_url'] != null && request['book']['thumbnail_url'].isNotEmpty
                                          ? Image.network(
                                              request['book']['thumbnail_url'],
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
                                                request['book']['name'] ?? AppLocalizations.of(context)!.unknownBook,
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
                                                request['book']['author'] ?? '',
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
                                // Request Date
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0.08),
                                        Colors.blue.withOpacity(0.02),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.2),
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
                                              Colors.blue.withOpacity(0.15),
                                              Colors.blue.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.calendar_today_rounded,
                                          color: Colors.blue[700],
                                          size: ResponsiveService.isSmallPhone ? 16 : 18,
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveService.isSmallPhone ? 10 : 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            text: AppLocalizations.of(context)!.requestDate,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w700,
                                              fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: request['request_date'] != null
                                                    ? DateTime.parse(request['request_date']).toLocal().toString().split(' ')[0]
                                                    : AppLocalizations.of(context)!.notAvailable,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.blue[600],
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
                                            text: AppLocalizations.of(context)!.dueDate,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w700,
                                              fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: request['due_date'] != null
                                                    ? DateTime.parse(request['due_date']).toLocal().toString().split(' ')[0]
                                                    : AppLocalizations.of(context)!.notAvailable,
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
                                SizedBox(height: ResponsiveService.isSmallPhone ? 8 : 10),
                                // Loan Duration
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(ResponsiveService.isSmallPhone ? 12 : 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.withOpacity(0.08),
                                        Colors.purple.withOpacity(0.02),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.purple.withOpacity(0.2),
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
                                              Colors.purple.withOpacity(0.15),
                                              Colors.purple.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.timer_rounded,
                                          color: Colors.purple[700],
                                          size: ResponsiveService.isSmallPhone ? 16 : 18,
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveService.isSmallPhone ? 10 : 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            text: AppLocalizations.of(context)!.loanDuration,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.purple[700],
                                              fontWeight: FontWeight.w700,
                                              fontSize: ResponsiveService.isSmallPhone ? 13 : 15,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '${request['loan_duration_days'] ?? 14} ${AppLocalizations.of(context)!.days}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.purple[600],
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
                            
                            // Action Buttons
                            if (showActions) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: ResponsiveService.isSmallPhone
                                    ? [
                                        // Stack buttons vertically on small phones
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFFE57373),
                                                      const Color(0xFFE57373).withOpacity(0.8),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFE57373).withOpacity(0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _handleRequest(request['id'].toString(), false),
                                                  icon: Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    AppLocalizations.of(context)!.reject,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF66BB6A),
                                                      const Color(0xFF66BB6A).withOpacity(0.8),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF66BB6A).withOpacity(0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _handleRequest(request['id'].toString(), true),
                                                  icon: Icon(
                                                    Icons.check_rounded,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    AppLocalizations.of(context)!.approve,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
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
                                        ),
                                      ]
                                    : [
                                        // Side by side buttons on larger screens
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFE57373),
                                                const Color(0xFFE57373).withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFE57373).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () => _handleRequest(request['id'].toString(), false),
                                            icon: Icon(
                                              Icons.close_rounded,
                                              size: 20,
                                            ),
                                            label: Text(
                                              AppLocalizations.of(context)!.reject,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF66BB6A),
                                                const Color(0xFF66BB6A).withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF66BB6A).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () => _handleRequest(request['id'].toString(), true),
                                            icon: Icon(
                                              Icons.check_rounded,
                                              size: 20,
                                            ),
                                            label: Text(
                                              AppLocalizations.of(context)!.approve,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                              ),
                            ] else if (request['status'] == 'APROBAT' && request['pickup_date'] == null) ...[
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
                                      onPressed: () => _markAsPickedUp(request['id'].toString()),
                                      icon: Icon(
                                        Icons.check_circle_rounded,
                                        size: ResponsiveService.isSmallPhone ? 18 : 20,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(context)!.markingPickedUp,
                                        style: TextStyle(
                                          fontSize: ResponsiveService.isSmallPhone ? 12 : 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
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
      },
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
