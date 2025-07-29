import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/responsive_service.dart';
import 'services/language_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/success_screen.dart';
import 'screens/add_book_screen.dart';
import 'screens/manage_books_screen.dart';
import 'screens/pending_requests_screen.dart';
import 'screens/active_loans_screen.dart';
import 'screens/loan_history_screen.dart';
import 'screens/search_books_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/exam_models_screen.dart';
import 'screens/exam_models_admin_screen.dart';
import 'screens/add_exam_model_screen.dart';
import 'screens/teacher_code_generation_screen.dart';
import 'screens/settings_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize language service
  final languageService = LanguageService();
  await languageService.initializeLanguage();
  
  runApp(MyApp(languageService: languageService));
}

class MyApp extends StatelessWidget {
  final LanguageService languageService;
  
  const MyApp({Key? key, required this.languageService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: languageService),
      ],
      child: Consumer2<ThemeProvider, LanguageService>(
        builder: (context, themeProvider, languageService, child) {
          // Initialize responsive service
          ResponsiveService.init(context);
          
          return MaterialApp(
            title: 'Lenbrary',
            theme: themeProvider.currentTheme,
            locale: languageService.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageService.supportedLocales,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/success': (context) => const SuccessScreen(),
              '/settings': (context) => const SettingsScreen(),

              // Librarian routes
              '/add-book': (context) => const AddBookScreen(),
              '/manage-books': (context) => const ManageBooksScreen(),
              '/pending-requests': (context) => const PendingRequestsScreen(),
              '/active-loans': (context) => const ActiveLoansScreen(),
              '/loan-history': (context) => const LoanHistoryScreen(),

              // User routes
              '/search-books': (context) => const SearchBooksScreen(),
              '/my-requests': (context) => const MyRequestsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/exam-models': (context) => const ExamModelsScreen(),
              '/admin-exam-models': (context) => const ExamModelsAdminScreen(),
              '/add-exam-model': (context) => const AddExamModelScreen(),
              '/teacher-code-generation': (context) => const TeacherCodeGenerationScreen(),
            },
          );
        },
      ),
    );
  }
}
