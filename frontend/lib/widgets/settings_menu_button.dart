import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../providers/theme_provider.dart';
import '../services/responsive_service.dart';
import '../l10n/app_localizations.dart';

class SettingsMenuButton extends StatelessWidget with ResponsiveWidget {
  const SettingsMenuButton({Key? key}) : super(key: key);

  // Flag emojis for each language
  static const Map<String, String> languageFlags = {
    'ro': '🇷🇴',
    'en': '🇺🇸',
    'de': '🇩🇪',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ThemeProvider>(
      builder: (context, languageService, themeProvider, child) {
        return PopupMenuButton<String>(
          tooltip: AppLocalizations.of(context)!.settingsMenu,
          icon: Container(
            padding: getResponsivePadding(all: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: getResponsiveBorderRadius(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.menu,
              color: Theme.of(context).colorScheme.onPrimary,
              size: getResponsiveIconSize(20),
            ),
          ),
          onSelected: (String value) {
            if (value == 'toggle_theme') {
              themeProvider.toggleTheme();
            } else if (LanguageService.supportedLocales.any((locale) => locale.languageCode == value)) {
              languageService.changeLanguage(value);
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              // Language section header
              PopupMenuItem<String>(
                enabled: false,
                child: Padding(
                  padding: getResponsivePadding(vertical: 4.0),
                  child: Text(
                    'Language',
                    style: ResponsiveTextStyles.getResponsiveTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              // Language options
              ...LanguageService.supportedLocales.map((Locale locale) {
                final languageCode = locale.languageCode;
                final languageName = LanguageService.languageNames[languageCode] ?? languageCode;
                final flag = languageFlags[languageCode] ?? '🌐';
                final isSelected = languageService.locale.languageCode == languageCode;

                return PopupMenuItem<String>(
                  value: languageCode,
                  child: Container(
                    padding: getResponsivePadding(vertical: 4.0, horizontal: 4.0),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: getResponsiveBorderRadius(8),
                          )
                        : null,
                    child: Row(
                      children: [
                        Text(
                          flag,
                          style: TextStyle(fontSize: getResponsiveFontSize(18)),
                        ),
                        SizedBox(width: getResponsiveSpacing(12.0)),
                        Expanded(
                          child: Text(
                            languageName,
                            style: ResponsiveTextStyles.getResponsiveTextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: getResponsiveIconSize(16),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              // Divider
              const PopupMenuDivider(),
              
              // Theme section header
              PopupMenuItem<String>(
                enabled: false,
                child: Padding(
                  padding: getResponsivePadding(vertical: 4.0),
                  child: Text(
                    'Theme',
                    style: ResponsiveTextStyles.getResponsiveTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              // Theme toggle option
              PopupMenuItem<String>(
                value: 'toggle_theme',
                child: Container(
                  padding: getResponsivePadding(vertical: 4.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        size: getResponsiveIconSize(20),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: getResponsiveSpacing(12.0)),
                      Expanded(
                        child: Text(
                          themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: getResponsiveIconSize(12),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          shape: RoundedRectangleBorder(
            borderRadius: getResponsiveBorderRadius(12),
          ),
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          constraints: BoxConstraints(
            minWidth: getResponsiveSpacing(200),
            maxWidth: getResponsiveSpacing(250),
          ),
        );
      },
    );
  }
}
