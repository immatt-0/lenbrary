import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/responsive_service.dart';

class LanguageSwitcher extends StatelessWidget with ResponsiveWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  // Flag emojis for each language
  static const Map<String, String> languageFlags = {
    'ro': '🇷🇴',
    'en': '🇺🇸',
    'de': '🇩🇪',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return PopupMenuButton<String>(
          tooltip: 'Change Language',
          icon: Container(
            padding: getResponsivePadding(all: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: getResponsiveBorderRadius(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageFlags[languageService.locale.languageCode] ?? '🌐',
                  style: TextStyle(fontSize: getResponsiveFontSize(18)),
                ),
                SizedBox(width: getResponsiveSpacing(4.0)),
                Icon(
                  Icons.expand_more,
                  size: getResponsiveIconSize(16),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
          onSelected: (String languageCode) {
            languageService.changeLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return LanguageService.supportedLocales.map((Locale locale) {
              final languageCode = locale.languageCode;
              final languageName = LanguageService.languageNames[languageCode] ?? languageCode;
              final flag = languageFlags[languageCode] ?? '🌐';
              final isSelected = languageService.locale.languageCode == languageCode;

              return PopupMenuItem<String>(
                value: languageCode,
                child: Container(
                  padding: getResponsivePadding(vertical: 8.0, horizontal: 4.0),
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
                        style: TextStyle(fontSize: getResponsiveFontSize(20)),
                      ),
                      SizedBox(width: getResponsiveSpacing(12.0)),
                      Expanded(
                        child: Text(
                          languageName,
                          style: ResponsiveTextStyles.getResponsiveTextStyle(
                            fontSize: 16,
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
                          size: getResponsiveIconSize(18),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          shape: RoundedRectangleBorder(
            borderRadius: getResponsiveBorderRadius(12),
          ),
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }
}
