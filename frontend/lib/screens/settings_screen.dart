import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/responsive_service.dart';
import '../widgets/responsive_button.dart';
import '../widgets/responsive_text_field.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with TickerProviderStateMixin, ResponsiveWidget {
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Set loading to false after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Setări',
            style: ResponsiveTextStyles.getResponsiveTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  Icons.settings_rounded,
                  size: getResponsiveIconSize(28),
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: getResponsiveSpacing(12)),
              Text(
                'Setări',
                style: ResponsiveTextStyles.getResponsiveTitleStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(getResponsiveSpacing(8)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: getResponsiveBorderRadius(8),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: getResponsiveIconSize(24),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.primary.withOpacity(0.01),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: getResponsivePadding(all: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Settings Section
                  _buildSectionHeader('Setări aplicație', Icons.app_settings_alt_rounded),
                  SizedBox(height: getResponsiveSpacing(16.0)),
                  
                  // Theme Toggle Card
                  _buildThemeToggleCard(),
                  SizedBox(height: getResponsiveSpacing(32.0)),
                  
                  // About Section
                  _buildSectionHeader('Despre aplicație', Icons.info_rounded),
                  SizedBox(height: getResponsiveSpacing(16.0)),
                  
                  // App Info Card
                  _buildAppInfoCard(),
                  SizedBox(height: getResponsiveSpacing(32)),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.logout_rounded, color: Colors.white),
                      label: Text('Deconectare', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _logout,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(getResponsiveSpacing(8)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: getResponsiveBorderRadius(8),
          ),
          child: Icon(
            icon,
            size: getResponsiveIconSize(20),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ),
        SizedBox(width: getResponsiveSpacing(12)),
        Text(
          title,
          style: ResponsiveTextStyles.getResponsiveTitleStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggleCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: getResponsiveBorderRadius(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                blurRadius: getResponsiveSpacing(24),
                offset: Offset(0, getResponsiveSpacing(10)),
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: getResponsiveSpacing(12),
                offset: Offset(0, getResponsiveSpacing(6)),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: getResponsivePadding(all: 24.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(12)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDarkMode ? Colors.purple[600]! : Colors.orange[600]!,
                        isDarkMode ? Colors.purple[400]! : Colors.orange[400]!,
                      ],
                    ),
                    borderRadius: getResponsiveBorderRadius(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isDarkMode ? Colors.purple : Colors.orange).withOpacity(0.3),
                        blurRadius: getResponsiveSpacing(8),
                        offset: Offset(0, getResponsiveSpacing(2)),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: getResponsiveIconSize(24),
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(16.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temă aplicație',
                        style: ResponsiveTextStyles.getResponsiveTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: getResponsiveSpacing(4)),
                      Text(
                        isDarkMode ? 'Temă întunecată activată' : 'Temă deschisă activată',
                        style: ResponsiveTextStyles.getResponsiveBodyStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                    NotificationService.showSuccess(
                      context: context,
                      message: isDarkMode ? 'Tema deschisă activată' : 'Tema întunecată activată',
                    );
                  },
                  activeColor: Colors.purple[600],
                  activeTrackColor: Colors.purple[200],
                  inactiveThumbColor: Colors.orange[600],
                  inactiveTrackColor: Colors.orange[200],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: getResponsiveBorderRadius(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            blurRadius: getResponsiveSpacing(24),
            offset: Offset(0, getResponsiveSpacing(10)),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: getResponsiveSpacing(12),
            offset: Offset(0, getResponsiveSpacing(6)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: getResponsivePadding(all: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getResponsiveSpacing(12)),
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
                    size: getResponsiveIconSize(24),
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: getResponsiveSpacing(16.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lenbrary',
                        style: ResponsiveTextStyles.getResponsiveTitleStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Sistem de gestionare bibliotecă',
                        style: ResponsiveTextStyles.getResponsiveBodyStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: getResponsiveSpacing(20)),
            _buildInfoRow('Versiune', '0.1.0'),
            SizedBox(height: getResponsiveSpacing(12)),
            _buildInfoRow('Dezvoltat de', 'Anghel Filip Neo & Burghiu Matei'),
            SizedBox(height: getResponsiveSpacing(12)),
            _buildInfoRow('An', '2024'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ResponsiveTextStyles.getResponsiveBodyStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: ResponsiveTextStyles.getResponsiveBodyStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
} 