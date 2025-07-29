import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageDebugWidget extends StatelessWidget {
  const LanguageDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final locale = languageService.locale;
        final appLocalizations = AppLocalizations.of(context);
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐛 LANGUAGE DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Current Locale: ${locale.languageCode}'),
              Text('AppLocalizations available: ${appLocalizations != null}'),
              if (appLocalizations != null) ...[
                Text('Login text: ${appLocalizations.login}'),
                Text('Email text: ${appLocalizations.email}'),
                Text('Password text: ${appLocalizations.password}'),
              ],
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await languageService.changeLanguage('en');
                  debugPrint('Changed to English');
                },
                child: Text('Force English'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await languageService.changeLanguage('ro');
                  debugPrint('Changed to Romanian');
                },
                child: Text('Force Romanian'),
              ),
            ],
          ),
        );
      },
    );
  }
}
