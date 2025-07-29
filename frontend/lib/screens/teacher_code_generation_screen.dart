import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';

class TeacherCodeGenerationScreen extends StatefulWidget {
  const TeacherCodeGenerationScreen({Key? key}) : super(key: key);

  @override
  State<TeacherCodeGenerationScreen> createState() => _TeacherCodeGenerationScreenState();
}

class _TeacherCodeGenerationScreenState extends State<TeacherCodeGenerationScreen>
    with TickerProviderStateMixin, ResponsiveWidget {
  String? _generatedCode;
  bool _isGenerating = false;
  List<dynamic> _codes = [];
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadExistingCodes();
    
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
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCodes() async {
    setState(() => _isLoading = true);
    try {
      final codes = await ApiService.getTeacherCodes();
      setState(() {
        _codes = codes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      NotificationService.showError(
        context: context,
        message: AppLocalizations.of(context)!.loadCodesError(e.toString()),
      );
    }
  }

  Future<void> _generateNewCode() async {
    setState(() => _isGenerating = true);
    try {
      final response = await ApiService.generateTeacherCode();
      setState(() {
        _generatedCode = response['code'];
        _isGenerating = false;
      });
      await _loadExistingCodes(); // Refresh the list
      NotificationService.showSuccess(
        context: context,
        message: AppLocalizations.of(context)!.codeGeneratedSuccess,
      );
      
      // Auto-hide the generated code display after 5 seconds
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _generatedCode = null;
          });
        }
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      NotificationService.showError(
        context: context,
        message: AppLocalizations.of(context)!.generateCodeError(e.toString()),
      );
    }
  }

  Future<void> _copyToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    NotificationService.showSuccess(
      context: context,
      message: AppLocalizations.of(context)!.copyCodeSuccess,
    );
  }

  Future<void> _deleteCode(int codeId) async {
    try {
      // Find the code being deleted to check if it matches the currently displayed one
      final codeToDelete = _codes.firstWhere((code) => code['id'] == codeId, orElse: () => null);
      
      await ApiService.deleteTeacherCode(codeId);
      await _loadExistingCodes();
      
      // If the deleted code matches the currently displayed generated code, clear it
      if (_generatedCode != null && codeToDelete != null && codeToDelete['code'] == _generatedCode) {
        setState(() {
          _generatedCode = null;
        });
      }
      
      NotificationService.showSuccess(
        context: context,
        message: AppLocalizations.of(context)!.deleteCodeSuccess,
      );
    } catch (e) {
      NotificationService.showError(
        context: context,
        message: AppLocalizations.of(context)!.deleteCodeError(e.toString()),
      );
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
                      Colors.indigo,
                      Colors.indigo.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: getResponsiveBorderRadius(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: getResponsiveSpacing(8),
                      offset: Offset(0, getResponsiveSpacing(2)),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: getResponsiveIconSize(24),
                ),
              ),
              SizedBox(width: getResponsiveSpacing(12)),
              Text(
                AppLocalizations.of(context)!.teacherCodes,
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
              tooltip: AppLocalizations.of(context)!.back,
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
              Colors.indigo.withOpacity(0.08),
              Theme.of(context).colorScheme.background,
              Colors.indigo.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Generate New Code Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: getResponsivePadding(all: 16),
                  child: Column(
                    children: [
                      // Info Card
                      Container(
                        padding: getResponsivePadding(all: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.1),
                              Colors.blue.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: getResponsiveBorderRadius(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(getResponsiveSpacing(10)),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: getResponsiveBorderRadius(12),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue,
                                size: getResponsiveIconSize(24),
                              ),
                            ),
                            SizedBox(width: getResponsiveSpacing(16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.aboutTeacherCodes,
                                    style: ResponsiveTextStyles.getResponsiveTextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: getResponsiveSpacing(4)),
                                  Text(
                                    AppLocalizations.of(context)!.teacherCodeDescription,
                                    style: ResponsiveTextStyles.getResponsiveTextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: getResponsiveSpacing(20)),
                      
                      // Generate Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo,
                              Colors.indigo.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: getResponsiveBorderRadius(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: getResponsiveSpacing(8),
                              offset: Offset(0, getResponsiveSpacing(2)),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generateNewCode,
                          icon: _isGenerating
                              ? SizedBox(
                                  width: getResponsiveIconSize(20),
                                  height: getResponsiveIconSize(20),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: getResponsiveIconSize(24),
                                ),
                          label: Text(
                            _isGenerating ? AppLocalizations.of(context)!.generating : AppLocalizations.of(context)!.generateNewCode,
                            style: ResponsiveTextStyles.getResponsiveTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: getResponsiveSpacing(16),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: getResponsiveBorderRadius(16),
                            ),
                          ),
                        ),
                      ),
                      
                      // Generated Code Display
                      if (_generatedCode != null) ...[
                        SizedBox(height: getResponsiveSpacing(20)),
                        Container(
                          padding: getResponsivePadding(all: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: getResponsiveBorderRadius(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(getResponsiveSpacing(8)),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: getResponsiveBorderRadius(8),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: getResponsiveIconSize(20),
                                    ),
                                  ),
                                  SizedBox(width: getResponsiveSpacing(12)),
                                  Text(
                                    AppLocalizations.of(context)!.codeGeneratedSuccess,
                                    style: ResponsiveTextStyles.getResponsiveTextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: getResponsiveSpacing(16)),
                              Container(
                                padding: getResponsivePadding(all: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: getResponsiveBorderRadius(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _generatedCode!,
                                        style: TextStyle(
                                          fontSize: ResponsiveService.getFontSize(18),
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(width: getResponsiveSpacing(12)),
                                    IconButton(
                                      onPressed: () => _copyToClipboard(_generatedCode!),
                                      icon: Icon(
                                        Icons.copy_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: getResponsiveIconSize(20),
                                      ),
                                      tooltip: AppLocalizations.of(context)!.copyCode,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Existing Codes List
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: getResponsivePadding(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: getResponsiveIconSize(24),
                          ),
                          SizedBox(width: getResponsiveSpacing(8)),
                          Text(
                            AppLocalizations.of(context)!.existingCodes,
                            style: ResponsiveTextStyles.getResponsiveTitleStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          if (_codes.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: getResponsiveSpacing(8),
                                vertical: getResponsiveSpacing(4),
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: getResponsiveBorderRadius(12),
                              ),
                              child: Text(
                                '${_codes.length}',
                                style: ResponsiveTextStyles.getResponsiveTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: getResponsiveSpacing(16)),
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : _codes.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(getResponsiveSpacing(20)),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.qr_code_scanner_rounded,
                                            size: getResponsiveIconSize(48),
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                          ),
                                        ),
                                        SizedBox(height: getResponsiveSpacing(16)),
                                        Text(
                                          AppLocalizations.of(context)!.noCodesGenerated,
                                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        SizedBox(height: getResponsiveSpacing(8)),
                                        Text(
                                          AppLocalizations.of(context)!.generateFirstCode,
                                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _codes.length,
                                    itemBuilder: (context, index) {
                                      final code = _codes[index];
                                      return _buildCodeCard(code);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeCard(dynamic code) {
    final createdAt = DateTime.parse(code['created_at']);
    final expiresAt = DateTime.parse(code['expires_at']);
    final isExpired = DateTime.now().isAfter(expiresAt);

    return Container(
      margin: EdgeInsets.only(bottom: getResponsiveSpacing(12)),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: getResponsiveBorderRadius(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: getResponsiveBorderRadius(16),
          ),
          child: Padding(
            padding: getResponsivePadding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status Icon
                    Container(
                      padding: EdgeInsets.all(getResponsiveSpacing(8)),
                      decoration: BoxDecoration(
                        color: (isExpired ? Colors.red : Colors.green).withOpacity(0.1),
                        borderRadius: getResponsiveBorderRadius(8),
                      ),
                      child: Icon(
                        isExpired ? Icons.timer_off_rounded : Icons.qr_code_2_rounded,
                        color: isExpired ? Colors.red : Colors.green,
                        size: getResponsiveIconSize(20),
                      ),
                    ),
                    SizedBox(width: getResponsiveSpacing(12)),
                    
                    // Code and Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                code['code'],
                                style: TextStyle(
                                  fontSize: ResponsiveService.getFontSize(16),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: getResponsiveSpacing(8)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getResponsiveSpacing(8),
                                  vertical: getResponsiveSpacing(2),
                                ),
                                decoration: BoxDecoration(
                                  color: (isExpired ? Colors.red : Colors.green).withOpacity(0.1),
                                  borderRadius: getResponsiveBorderRadius(8),
                                ),
                                child: Text(
                                  isExpired ? AppLocalizations.of(context)!.codeExpired : AppLocalizations.of(context)!.codeAvailable,
                                  style: ResponsiveTextStyles.getResponsiveTextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: getResponsiveSpacing(4)),
                          Text(
                            AppLocalizations.of(context)!.createdAt(_formatDate(createdAt)),
                            style: ResponsiveTextStyles.getResponsiveTextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.expiresAt(_formatDate(expiresAt)),
                            style: ResponsiveTextStyles.getResponsiveTextStyle(
                              fontSize: 12,
                              color: isExpired 
                                ? Colors.red 
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    Row(
                      children: [
                        if (!isExpired)
                          IconButton(
                            onPressed: () => _copyToClipboard(code['code']),
                            icon: Icon(
                              Icons.copy_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: getResponsiveIconSize(20),
                            ),
                            tooltip: AppLocalizations.of(context)!.copyCode,
                          ),
                        IconButton(
                          onPressed: () => _showDeleteConfirmation(code['id']),
                          icon: Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                            size: getResponsiveIconSize(20),
                          ),
                          tooltip: AppLocalizations.of(context)!.deleteCode,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(int codeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteConfirmation),
          content: Text(AppLocalizations.of(context)!.deleteCodeConfirmText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCode(codeId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
