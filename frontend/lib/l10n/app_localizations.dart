import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ro')
  ];

  /// No description provided for @registerAsTeacher.
  ///
  /// In en, this message translates to:
  /// **'Register as teacher'**
  String get registerAsTeacher;

  /// No description provided for @enterTeacherCode.
  ///
  /// In en, this message translates to:
  /// **'Enter teacher code'**
  String get enterTeacherCode;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lenbrary'**
  String get appTitle;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @addCover.
  ///
  /// In en, this message translates to:
  /// **'Add Cover'**
  String get addCover;

  /// No description provided for @chooseCoverMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to add the book cover:'**
  String get chooseCoverMethod;

  /// No description provided for @addPdf.
  ///
  /// In en, this message translates to:
  /// **'Add PDF'**
  String get addPdf;

  /// No description provided for @choosePdfMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to add the PDF:'**
  String get choosePdfMethod;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @isbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbn;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequests;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @usernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get usernameOrEmail;

  /// No description provided for @enterUsernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username or email address'**
  String get enterUsernameOrEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegister;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get enterFirstName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get enterLastName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmail;

  /// No description provided for @schoolType.
  ///
  /// In en, this message translates to:
  /// **'School Type'**
  String get schoolType;

  /// No description provided for @selectSchoolType.
  ///
  /// In en, this message translates to:
  /// **'Please select a school type'**
  String get selectSchoolType;

  /// No description provided for @classLevel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLevel;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select Class'**
  String get selectClass;

  /// No description provided for @selectProfile.
  ///
  /// In en, this message translates to:
  /// **'Please select a profile'**
  String get selectProfile;

  /// No description provided for @classLetter.
  ///
  /// In en, this message translates to:
  /// **'Class Letter'**
  String get classLetter;

  /// No description provided for @selectClassLetter.
  ///
  /// In en, this message translates to:
  /// **'Please select a class letter'**
  String get selectClassLetter;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code'**
  String get invitationCode;

  /// No description provided for @enterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the invitation code'**
  String get enterInvitationCode;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get creatingAccount;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registrationTitle;

  /// No description provided for @registrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details to register'**
  String get registrationSubtitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @searchBooks.
  ///
  /// In en, this message translates to:
  /// **'Search books'**
  String get searchBooks;

  /// No description provided for @requestBook.
  ///
  /// In en, this message translates to:
  /// **'Request Book'**
  String get requestBook;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @bookAdded.
  ///
  /// In en, this message translates to:
  /// **'Book added'**
  String get bookAdded;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully!'**
  String get requestSent;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request'**
  String get requestFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @noActiveLoans.
  ///
  /// In en, this message translates to:
  /// **'No active loans'**
  String get noActiveLoans;

  /// No description provided for @selectDuration.
  ///
  /// In en, this message translates to:
  /// **'Select loan duration'**
  String get selectDuration;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get oneWeek;

  /// No description provided for @twoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 Weeks'**
  String get twoWeeks;

  /// No description provided for @oneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get oneMonth;

  /// No description provided for @twoMonths.
  ///
  /// In en, this message translates to:
  /// **'2 Months'**
  String get twoMonths;

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @activeLoans.
  ///
  /// In en, this message translates to:
  /// **'Active loans'**
  String get activeLoans;

  /// No description provided for @loadingLoans.
  ///
  /// In en, this message translates to:
  /// **'Loading loans...'**
  String get loadingLoans;

  /// No description provided for @loanHistory.
  ///
  /// In en, this message translates to:
  /// **'Loan history'**
  String get loanHistory;

  /// No description provided for @pickupAndLoans.
  ///
  /// In en, this message translates to:
  /// **'Pickup & Loans'**
  String get pickupAndLoans;

  /// No description provided for @manageBooks.
  ///
  /// In en, this message translates to:
  /// **'Manage books'**
  String get manageBooks;

  /// No description provided for @addBook.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get addBook;

  /// No description provided for @editBook.
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get editBook;

  /// No description provided for @deleteBook.
  ///
  /// In en, this message translates to:
  /// **'Delete Book'**
  String get deleteBook;

  /// No description provided for @bookDetails.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetails;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get takePicture;

  /// No description provided for @addFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Add from Gallery'**
  String get addFromGallery;

  /// No description provided for @addPDF.
  ///
  /// In en, this message translates to:
  /// **'Add PDF'**
  String get addPDF;

  /// No description provided for @choosePDFFile.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF File'**
  String get choosePDFFile;

  /// No description provided for @resourceType.
  ///
  /// In en, this message translates to:
  /// **'Resource Type'**
  String get resourceType;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get required;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @stockInfo.
  ///
  /// In en, this message translates to:
  /// **'Stock Information'**
  String get stockInfo;

  /// No description provided for @totalInventory.
  ///
  /// In en, this message translates to:
  /// **'Total Inventory'**
  String get totalInventory;

  /// No description provided for @availableStock.
  ///
  /// In en, this message translates to:
  /// **'Available Stock'**
  String get availableStock;

  /// No description provided for @fillBookDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details for the new book/manual'**
  String get fillBookDetails;

  /// No description provided for @requiredFields.
  ///
  /// In en, this message translates to:
  /// **'Fields marked with * are required'**
  String get requiredFields;

  /// No description provided for @emailDomainError.
  ///
  /// In en, this message translates to:
  /// **'Email must be from nlenau.ro domain'**
  String get emailDomainError;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordMinLength;

  /// No description provided for @teacherAccount.
  ///
  /// In en, this message translates to:
  /// **'Teacher account'**
  String get teacherAccount;

  /// No description provided for @studentInformation.
  ///
  /// In en, this message translates to:
  /// **'Student information'**
  String get studentInformation;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreated;

  /// No description provided for @generalSchool.
  ///
  /// In en, this message translates to:
  /// **'General School'**
  String get generalSchool;

  /// No description provided for @highSchool.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get highSchool;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeUser(Object userName);

  /// No description provided for @whatDoYouWantToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do today?'**
  String get whatDoYouWantToday;

  /// No description provided for @searchBooksShort.
  ///
  /// In en, this message translates to:
  /// **'Search books and manuals...'**
  String get searchBooksShort;

  /// No description provided for @addNewBook.
  ///
  /// In en, this message translates to:
  /// **'Add a new book to catalog'**
  String get addNewBook;

  /// No description provided for @viewRequests.
  ///
  /// In en, this message translates to:
  /// **'View Requests'**
  String get viewRequests;

  /// No description provided for @examModels.
  ///
  /// In en, this message translates to:
  /// **'Test models'**
  String get examModels;

  /// No description provided for @generateCodes.
  ///
  /// In en, this message translates to:
  /// **'Generate Codes'**
  String get generateCodes;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @pleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get pleaseEnter;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchByBookName.
  ///
  /// In en, this message translates to:
  /// **'🔍 Search by book name...'**
  String get searchByBookName;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @borrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get borrowed;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @bookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Title'**
  String get bookTitle;

  /// No description provided for @publicationYear.
  ///
  /// In en, this message translates to:
  /// **'Publication Year'**
  String get publicationYear;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @requestDuration.
  ///
  /// In en, this message translates to:
  /// **'Request Duration'**
  String get requestDuration;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @noBooks.
  ///
  /// In en, this message translates to:
  /// **'No books available'**
  String get noBooks;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @readNotifications.
  ///
  /// In en, this message translates to:
  /// **'Read notifications'**
  String get readNotifications;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unread notifications'**
  String get unreadNotifications;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @romanian.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get romanian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System Mode'**
  String get systemMode;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive digital library management system'**
  String get appDescription;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalidInput;

  /// No description provided for @mustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get mustBeNumber;

  /// No description provided for @cannotExceed.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed'**
  String get cannotExceed;

  /// No description provided for @unknownBook.
  ///
  /// In en, this message translates to:
  /// **'Unknown book'**
  String get unknownBook;

  /// No description provided for @pickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup date:'**
  String get pickupDate;

  /// No description provided for @bookAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Book/manual has been added successfully!'**
  String get bookAddedSuccessfully;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date: '**
  String get dueDate;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @bookReturned.
  ///
  /// In en, this message translates to:
  /// **'Book returned'**
  String get bookReturned;

  /// No description provided for @gimnaziuV.
  ///
  /// In en, this message translates to:
  /// **'Middle School V'**
  String get gimnaziuV;

  /// No description provided for @gimnaziuVI.
  ///
  /// In en, this message translates to:
  /// **'Middle School VI'**
  String get gimnaziuVI;

  /// No description provided for @gimnaziuVII.
  ///
  /// In en, this message translates to:
  /// **'Middle School VII'**
  String get gimnaziuVII;

  /// No description provided for @gimnaziuVIII.
  ///
  /// In en, this message translates to:
  /// **'Middle School VIII'**
  String get gimnaziuVIII;

  /// No description provided for @liceulIX.
  ///
  /// In en, this message translates to:
  /// **'High School IX'**
  String get liceulIX;

  /// No description provided for @liceulX.
  ///
  /// In en, this message translates to:
  /// **'High School X'**
  String get liceulX;

  /// No description provided for @liceulXI.
  ///
  /// In en, this message translates to:
  /// **'High School XI'**
  String get liceulXI;

  /// No description provided for @liceulXII.
  ///
  /// In en, this message translates to:
  /// **'High School XII'**
  String get liceulXII;

  /// No description provided for @bookUpdated.
  ///
  /// In en, this message translates to:
  /// **'Book updated'**
  String get bookUpdated;

  /// No description provided for @bookDeleted.
  ///
  /// In en, this message translates to:
  /// **'Book deleted'**
  String get bookDeleted;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected successfully!'**
  String get requestRejected;

  /// No description provided for @extensionRequested.
  ///
  /// In en, this message translates to:
  /// **'Extension request'**
  String get extensionRequested;

  /// No description provided for @extensionApproved.
  ///
  /// In en, this message translates to:
  /// **'Extension approved'**
  String get extensionApproved;

  /// No description provided for @extensionRejected.
  ///
  /// In en, this message translates to:
  /// **'Extension rejected'**
  String get extensionRejected;

  /// No description provided for @bookType.
  ///
  /// In en, this message translates to:
  /// **'Book Type'**
  String get bookType;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @choosePdfFile.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF file'**
  String get choosePdfFile;

  /// No description provided for @totalCopies.
  ///
  /// In en, this message translates to:
  /// **'Total number of copies'**
  String get totalCopies;

  /// No description provided for @availableCopies.
  ///
  /// In en, this message translates to:
  /// **'Number of copies available for borrowing'**
  String get availableCopies;

  /// No description provided for @stockCannotExceedInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock cannot be greater than inventory'**
  String get stockCannotExceedInventory;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @extensionRequests.
  ///
  /// In en, this message translates to:
  /// **'Extension requests'**
  String get extensionRequests;

  /// No description provided for @extensionRequestDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can view extension requests'**
  String get extensionRequestDescription;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @approveRequest.
  ///
  /// In en, this message translates to:
  /// **'Approve Request'**
  String get approveRequest;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequest;

  /// No description provided for @requestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get requestedOn;

  /// No description provided for @requestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get requestedBy;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @extend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get extend;

  /// No description provided for @extensionReason.
  ///
  /// In en, this message translates to:
  /// **'Extension Reason'**
  String get extensionReason;

  /// No description provided for @newDuration.
  ///
  /// In en, this message translates to:
  /// **'New Duration'**
  String get newDuration;

  /// No description provided for @requestExtension.
  ///
  /// In en, this message translates to:
  /// **'Request Extension'**
  String get requestExtension;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Library administration panel'**
  String get adminPanel;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @manageRequests.
  ///
  /// In en, this message translates to:
  /// **'Manage Requests'**
  String get manageRequests;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Password cannot contain spaces'**
  String get passwordNoSpaces;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordUppercase;

  /// No description provided for @passwordDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one digit'**
  String get passwordDigit;

  /// No description provided for @passwordSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordSpecialChar;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseSelectTitle;

  /// No description provided for @pleaseSelectAuthor.
  ///
  /// In en, this message translates to:
  /// **'Please enter an author'**
  String get pleaseSelectAuthor;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseSelectDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseSelectDescription;

  /// No description provided for @pleaseEnterValidYear.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid year'**
  String get pleaseEnterValidYear;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @stockInformation.
  ///
  /// In en, this message translates to:
  /// **'Stock Information'**
  String get stockInformation;

  /// No description provided for @pleaseEnterTotalInventory.
  ///
  /// In en, this message translates to:
  /// **'Please enter total inventory'**
  String get pleaseEnterTotalInventory;

  /// No description provided for @inventoryMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Inventory must be a number'**
  String get inventoryMustBeNumber;

  /// No description provided for @totalCopiesNumber.
  ///
  /// In en, this message translates to:
  /// **'Total number of copies'**
  String get totalCopiesNumber;

  /// No description provided for @pleaseEnterAvailableStock.
  ///
  /// In en, this message translates to:
  /// **'Please enter available stock'**
  String get pleaseEnterAvailableStock;

  /// No description provided for @stockMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Stock must be a number'**
  String get stockMustBeNumber;

  /// No description provided for @availableCopiesNumber.
  ///
  /// In en, this message translates to:
  /// **'Number of copies available for loan'**
  String get availableCopiesNumber;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get adding;

  /// No description provided for @errorCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Error accessing camera'**
  String get errorCameraAccess;

  /// No description provided for @errorGalleryAccess.
  ///
  /// In en, this message translates to:
  /// **'Error accessing gallery'**
  String get errorGalleryAccess;

  /// No description provided for @errorReadingPdf.
  ///
  /// In en, this message translates to:
  /// **'Error reading PDF file'**
  String get errorReadingPdf;

  /// No description provided for @errorAccessingPdf.
  ///
  /// In en, this message translates to:
  /// **'Error accessing PDF file'**
  String get errorAccessingPdf;

  /// No description provided for @errorSelectingPdf.
  ///
  /// In en, this message translates to:
  /// **'Error selecting PDF file'**
  String get errorSelectingPdf;

  /// No description provided for @choosePdfForManual.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF file for manual:'**
  String get choosePdfForManual;

  /// No description provided for @pleaseSelectClass.
  ///
  /// In en, this message translates to:
  /// **'Please select class'**
  String get pleaseSelectClass;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseEnterAuthor.
  ///
  /// In en, this message translates to:
  /// **'Please enter an author'**
  String get pleaseEnterAuthor;

  /// No description provided for @pleaseEnterCategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category'**
  String get pleaseEnterCategory;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @manualPDF.
  ///
  /// In en, this message translates to:
  /// **'Manual PDF'**
  String get manualPDF;

  /// No description provided for @uploadManualPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Upload the manual PDF file'**
  String get uploadManualPdfFile;

  /// No description provided for @pdfFileSize.
  ///
  /// In en, this message translates to:
  /// **'PDF file ({size} KB)'**
  String pdfFileSize(String size);

  /// No description provided for @pdfFileSelected.
  ///
  /// In en, this message translates to:
  /// **'PDF file selected'**
  String get pdfFileSelected;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @uploadPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF file'**
  String get uploadPdfFile;

  /// No description provided for @selectManualPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Select the manual PDF file'**
  String get selectManualPdfFile;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @pdfSuccessfullyAdded.
  ///
  /// In en, this message translates to:
  /// **'PDF successfully added'**
  String get pdfSuccessfullyAdded;

  /// No description provided for @pleaseSelectPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a PDF file.'**
  String get pleaseSelectPdfFile;

  /// No description provided for @pleaseSelectExamType.
  ///
  /// In en, this message translates to:
  /// **'Please select the exam type.'**
  String get pleaseSelectExamType;

  /// No description provided for @pleaseSelectSubject.
  ///
  /// In en, this message translates to:
  /// **'Please select the subject.'**
  String get pleaseSelectSubject;

  /// No description provided for @errorAddingItem.
  ///
  /// In en, this message translates to:
  /// **'Error adding item: {error}'**
  String errorAddingItem(String error);

  /// No description provided for @addExamModel.
  ///
  /// In en, this message translates to:
  /// **'Add Exam Model'**
  String get addExamModel;

  /// No description provided for @newExamModel.
  ///
  /// In en, this message translates to:
  /// **'New Exam Model'**
  String get newExamModel;

  /// No description provided for @fillExamModelDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in the exam model details'**
  String get fillExamModelDetails;

  /// No description provided for @examModelName.
  ///
  /// In en, this message translates to:
  /// **'Exam model name'**
  String get examModelName;

  /// No description provided for @enterExamModelName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterExamModelName;

  /// No description provided for @examType.
  ///
  /// In en, this message translates to:
  /// **'Exam Type'**
  String get examType;

  /// No description provided for @nationalEvaluation.
  ///
  /// In en, this message translates to:
  /// **'National Evaluation (EN)'**
  String get nationalEvaluation;

  /// No description provided for @baccalaureate.
  ///
  /// In en, this message translates to:
  /// **'Baccalaureate (BAC)'**
  String get baccalaureate;

  /// No description provided for @selectExamTypeValidator.
  ///
  /// In en, this message translates to:
  /// **'Select the exam type'**
  String get selectExamTypeValidator;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @mathematics.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get mathematics;

  /// No description provided for @selectSubjectValidator.
  ///
  /// In en, this message translates to:
  /// **'Select the subject'**
  String get selectSubjectValidator;

  /// No description provided for @addModel.
  ///
  /// In en, this message translates to:
  /// **'Add model'**
  String get addModel;

  /// No description provided for @tapToSelectPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a PDF file'**
  String get tapToSelectPdfFile;

  /// No description provided for @requestLoan.
  ///
  /// In en, this message translates to:
  /// **'Request Loan'**
  String get requestLoan;

  /// No description provided for @loanDuration.
  ///
  /// In en, this message translates to:
  /// **'Loan duration: '**
  String get loanDuration;

  /// No description provided for @messageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (optional):'**
  String get messageOptional;

  /// No description provided for @writeMessageForLibrarian.
  ///
  /// In en, this message translates to:
  /// **'Write a message for the librarian... (optional)'**
  String get writeMessageForLibrarian;

  /// No description provided for @loanRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Loan request registered successfully!'**
  String get loanRequestSuccess;

  /// No description provided for @errorRequestingBook.
  ///
  /// In en, this message translates to:
  /// **'Error requesting book/manual: {error}'**
  String errorRequestingBook(String error);

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class {className}'**
  String classLabel(String className);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String available(int count);

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @pdfOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open PDF.'**
  String get pdfOpenError;

  /// No description provided for @pdfOpenErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error opening PDF: {error}'**
  String pdfOpenErrorDetails(String error);

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @searchExamModels.
  ///
  /// In en, this message translates to:
  /// **'🔍 Search exam models...'**
  String get searchExamModels;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @allSubjects.
  ///
  /// In en, this message translates to:
  /// **'All subjects'**
  String get allSubjects;

  /// No description provided for @math.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get math;

  /// No description provided for @mate.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get mate;

  /// No description provided for @deleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get deleteModel;

  /// No description provided for @examModelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Models'**
  String get examModelsTitle;

  /// No description provided for @searchExamModelsHint.
  ///
  /// In en, this message translates to:
  /// **'Search test models...'**
  String get searchExamModelsHint;

  /// No description provided for @testType.
  ///
  /// In en, this message translates to:
  /// **'Test type'**
  String get testType;

  /// No description provided for @allTestTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTestTypes;

  /// No description provided for @modelWithoutName.
  ///
  /// In en, this message translates to:
  /// **'Model without name'**
  String get modelWithoutName;

  /// No description provided for @noTestsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tests available'**
  String get noTestsAvailable;

  /// No description provided for @noTestsForSearch.
  ///
  /// In en, this message translates to:
  /// **'No tests found for your search'**
  String get noTestsForSearch;

  /// No description provided for @modelsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Models will appear here after they are added'**
  String get modelsWillAppear;

  /// No description provided for @modifySearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try modifying the search terms'**
  String get modifySearchTerms;

  /// No description provided for @couldNotOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Could not open PDF.'**
  String get couldNotOpenPdf;

  /// No description provided for @extensionRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension Requests'**
  String get extensionRequestsTitle;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @loadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Loading requests...'**
  String get loadingRequests;

  /// No description provided for @noExtensionRequests.
  ///
  /// In en, this message translates to:
  /// **'No extension requests'**
  String get noExtensionRequests;

  /// No description provided for @extensionRequestsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Extension requests will appear here'**
  String get extensionRequestsWillAppear;

  /// No description provided for @alreadyExtendedMessage.
  ///
  /// In en, this message translates to:
  /// **'This book has already been extended once. It cannot be extended again.'**
  String get alreadyExtendedMessage;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To:'**
  String get toLabel;

  /// No description provided for @extensionRequestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension request details'**
  String get extensionRequestDetailsTitle;

  /// No description provided for @currentReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Current return date'**
  String get currentReturnDate;

  /// No description provided for @extendedReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Extended return date'**
  String get extendedReturnDate;

  /// No description provided for @studentMessage.
  ///
  /// In en, this message translates to:
  /// **'Student message'**
  String get studentMessage;

  /// No description provided for @extensionApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Extension approved successfully!'**
  String get extensionApprovedMessage;

  /// No description provided for @approving.
  ///
  /// In en, this message translates to:
  /// **'Approving...'**
  String get approving;

  /// No description provided for @extensionRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Extension rejected successfully!'**
  String get extensionRejectedMessage;

  /// No description provided for @rejecting.
  ///
  /// In en, this message translates to:
  /// **'Rejecting...'**
  String get rejecting;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @alreadyExtended.
  ///
  /// In en, this message translates to:
  /// **'Already extended'**
  String get alreadyExtended;

  /// No description provided for @errorRejecting.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting: {error}'**
  String errorRejecting(String error);

  /// No description provided for @addExamModelButton.
  ///
  /// In en, this message translates to:
  /// **'Add exam model'**
  String get addExamModelButton;

  /// No description provided for @loadingModels.
  ///
  /// In en, this message translates to:
  /// **'Loading models...'**
  String get loadingModels;

  /// No description provided for @futureSubject.
  ///
  /// In en, this message translates to:
  /// **'We will add {subject} tests in the future'**
  String futureSubject(String subject);

  /// No description provided for @noModelsFound.
  ///
  /// In en, this message translates to:
  /// **'No models found for your search'**
  String get noModelsFound;

  /// No description provided for @noModelsExist.
  ///
  /// In en, this message translates to:
  /// **'No exam models exist'**
  String get noModelsExist;

  /// No description provided for @focusOnMainSubjects.
  ///
  /// In en, this message translates to:
  /// **'Currently we focus on mathematics and Romanian'**
  String get focusOnMainSubjects;

  /// No description provided for @tryModifyingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try modifying the search terms'**
  String get tryModifyingSearch;

  /// No description provided for @addFirstModel.
  ///
  /// In en, this message translates to:
  /// **'Add the first exam model'**
  String get addFirstModel;

  /// No description provided for @openPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdfTooltip;

  /// No description provided for @deleteModelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get deleteModelTooltip;

  /// No description provided for @errorLoadingModels.
  ///
  /// In en, this message translates to:
  /// **'Error loading models: {error}'**
  String errorLoadingModels(String error);

  /// No description provided for @errorDeleting.
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {error}'**
  String errorDeleting(String error);

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add {item}'**
  String addItem(String item);

  /// No description provided for @loanHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan History'**
  String get loanHistoryTitle;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(String count);

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @searchBooksPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'🔍 Search by name, author or title...'**
  String get searchBooksPlaceholder;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get loadingHistory;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noSearchResults(String query);

  /// No description provided for @noLoanHistory.
  ///
  /// In en, this message translates to:
  /// **'No loan history exists'**
  String get noLoanHistory;

  /// No description provided for @tryModifyingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try modifying the search terms'**
  String get tryModifyingSearchTerms;

  /// No description provided for @historyWillAppear.
  ///
  /// In en, this message translates to:
  /// **'History will appear here after loans are made'**
  String get historyWillAppear;

  /// No description provided for @notReturnedYet.
  ///
  /// In en, this message translates to:
  /// **'Not returned yet'**
  String get notReturnedYet;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @unknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get unknownAuthor;

  /// No description provided for @requestDate.
  ///
  /// In en, this message translates to:
  /// **'Request date: '**
  String get requestDate;

  /// No description provided for @loginHintShort.
  ///
  /// In en, this message translates to:
  /// **'first.last'**
  String get loginHintShort;

  /// No description provided for @loginHintLong.
  ///
  /// In en, this message translates to:
  /// **'first.last or first.last@nlenau.ro'**
  String get loginHintLong;

  /// No description provided for @manageBooksShort.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageBooksShort;

  /// No description provided for @manageBooksLong.
  ///
  /// In en, this message translates to:
  /// **'Manage Books'**
  String get manageBooksLong;

  /// No description provided for @manuals.
  ///
  /// In en, this message translates to:
  /// **'Manuals'**
  String get manuals;

  /// No description provided for @searchBooksLong.
  ///
  /// In en, this message translates to:
  /// **'Search by title, author, category or class (e.g. VIII or 8)...'**
  String get searchBooksLong;

  /// No description provided for @noBookFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No book found for \"{query}\"'**
  String noBookFoundFor(String query);

  /// No description provided for @noBooksInLibrary.
  ///
  /// In en, this message translates to:
  /// **'No books in library'**
  String get noBooksInLibrary;

  /// No description provided for @noManualsInLibrary.
  ///
  /// In en, this message translates to:
  /// **'No manuals in library'**
  String get noManualsInLibrary;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {current}/{total}'**
  String stockLabel(String current, String total);

  /// No description provided for @noLoanRequests.
  ///
  /// In en, this message translates to:
  /// **'You have no loan requests'**
  String get noLoanRequests;

  /// No description provided for @requestsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your requests will appear here after you request books'**
  String get requestsWillAppear;

  /// No description provided for @readyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get readyForPickup;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @tapToExtend.
  ///
  /// In en, this message translates to:
  /// **'Tap to extend'**
  String get tapToExtend;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @confirmCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request?'**
  String get confirmCancelRequest;

  /// No description provided for @messageForLibrarian.
  ///
  /// In en, this message translates to:
  /// **'Message for librarian (optional):'**
  String get messageForLibrarian;

  /// No description provided for @addMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a message...'**
  String get addMessage;

  /// No description provided for @giveUp.
  ///
  /// In en, this message translates to:
  /// **'Give up'**
  String get giveUp;

  /// No description provided for @requestCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request has been cancelled successfully.'**
  String get requestCancelledSuccess;

  /// No description provided for @cancelError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling: {error}'**
  String cancelError(String error);

  /// No description provided for @extendLoan.
  ///
  /// In en, this message translates to:
  /// **'Extend loan'**
  String get extendLoan;

  /// No description provided for @extensionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Extension period:'**
  String get extensionPeriod;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysLabel(int days);

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitRequest;

  /// No description provided for @extensionRequestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Extension request has been sent successfully!'**
  String get extensionRequestSuccess;

  /// No description provided for @bookAlreadyExtended.
  ///
  /// In en, this message translates to:
  /// **'This book has already been extended once and cannot be extended again.'**
  String get bookAlreadyExtended;

  /// No description provided for @loadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get loadingNotifications;

  /// No description provided for @notificationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications: {error}'**
  String notificationLoadError(String error);

  /// No description provided for @markAsReadError.
  ///
  /// In en, this message translates to:
  /// **'Error marking notification as read: {error}'**
  String markAsReadError(String error);

  /// No description provided for @markAllAsReadError.
  ///
  /// In en, this message translates to:
  /// **'Error marking notifications as read: {error}'**
  String markAllAsReadError(String error);

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications have been marked as read'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date;

  /// No description provided for @bookRequested.
  ///
  /// In en, this message translates to:
  /// **'Book request'**
  String get bookRequested;

  /// No description provided for @bookAccepted.
  ///
  /// In en, this message translates to:
  /// **'Book accepted'**
  String get bookAccepted;

  /// No description provided for @bookRejected.
  ///
  /// In en, this message translates to:
  /// **'Book rejected'**
  String get bookRejected;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get requestCancelled;

  /// No description provided for @teacherRegistered.
  ///
  /// In en, this message translates to:
  /// **'Teacher registered'**
  String get teacherRegistered;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @unknownNotification.
  ///
  /// In en, this message translates to:
  /// **'Unknown notification'**
  String get unknownNotification;

  /// No description provided for @notificationWithType.
  ///
  /// In en, this message translates to:
  /// **'Notification ({type})'**
  String notificationWithType(String type);

  /// No description provided for @filterNotifications.
  ///
  /// In en, this message translates to:
  /// **'Filter notifications'**
  String get filterNotifications;

  /// No description provided for @showingAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Showing all notifications ({count})'**
  String showingAllNotifications(int count);

  /// No description provided for @activeFilter.
  ///
  /// In en, this message translates to:
  /// **'Active filter: {filterName} ({count})'**
  String activeFilter(String filterName, int count);

  /// No description provided for @noNotificationsOfType.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications of this type'**
  String get noNotificationsOfType;

  /// No description provided for @allNotificationsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'All your notifications will appear here'**
  String get allNotificationsWillAppear;

  /// No description provided for @tryChangingFilter.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filter to see other notifications'**
  String get tryChangingFilter;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @newNotification.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newNotification;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get allNotifications;

  /// No description provided for @registeredTeachers.
  ///
  /// In en, this message translates to:
  /// **'Registered teachers'**
  String get registeredTeachers;

  /// No description provided for @bookRequests.
  ///
  /// In en, this message translates to:
  /// **'Book requests'**
  String get bookRequests;

  /// No description provided for @acceptedBooks.
  ///
  /// In en, this message translates to:
  /// **'Accepted books'**
  String get acceptedBooks;

  /// No description provided for @rejectedBooks.
  ///
  /// In en, this message translates to:
  /// **'Rejected books'**
  String get rejectedBooks;

  /// No description provided for @returnedBooks.
  ///
  /// In en, this message translates to:
  /// **'Returned books'**
  String get returnedBooks;

  /// No description provided for @approvedExtensions.
  ///
  /// In en, this message translates to:
  /// **'Approved extensions'**
  String get approvedExtensions;

  /// No description provided for @rejectedExtensions.
  ///
  /// In en, this message translates to:
  /// **'Rejected extensions'**
  String get rejectedExtensions;

  /// No description provided for @cancelledRequests.
  ///
  /// In en, this message translates to:
  /// **'Cancelled requests'**
  String get cancelledRequests;

  /// No description provided for @approvedRequests.
  ///
  /// In en, this message translates to:
  /// **'Approved requests'**
  String get approvedRequests;

  /// No description provided for @addedBooks.
  ///
  /// In en, this message translates to:
  /// **'Added books'**
  String get addedBooks;

  /// No description provided for @updatedBooks.
  ///
  /// In en, this message translates to:
  /// **'Updated books'**
  String get updatedBooks;

  /// No description provided for @deletedBooks.
  ///
  /// In en, this message translates to:
  /// **'Deleted books'**
  String get deletedBooks;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @otherNotifications.
  ///
  /// In en, this message translates to:
  /// **'Other notifications'**
  String get otherNotifications;

  /// No description provided for @requestApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request approved successfully!'**
  String get requestApprovedSuccess;

  /// No description provided for @requestRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request rejected successfully!'**
  String get requestRejectedSuccess;

  /// No description provided for @bookRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Requests'**
  String get bookRequestsTitle;

  /// No description provided for @bookManualsRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Book and Manual Requests'**
  String get bookManualsRequestsTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'🔍 Search...'**
  String get searchPlaceholder;

  /// No description provided for @searchDetailedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'🔍 Search by book name or student name...'**
  String get searchDetailedPlaceholder;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @noApprovedRequests.
  ///
  /// In en, this message translates to:
  /// **'No approved requests'**
  String get noApprovedRequests;

  /// No description provided for @noRequestsNeedApproval.
  ///
  /// In en, this message translates to:
  /// **'No requests need approval'**
  String get noRequestsNeedApproval;

  /// No description provided for @noApprovedRequestsCurrently.
  ///
  /// In en, this message translates to:
  /// **'No approved requests at the moment'**
  String get noApprovedRequestsCurrently;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date: '**
  String get dueDateLabel;

  /// No description provided for @loanDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan duration: '**
  String get loanDurationLabel;

  /// No description provided for @markAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark as picked up'**
  String get markAsPickedUp;

  /// No description provided for @bookMarkedAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'The book/manual has been marked as picked up!'**
  String get bookMarkedAsPickedUp;

  /// No description provided for @markingPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark Picked Up'**
  String get markingPickedUp;

  /// No description provided for @searchBookStudentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by book name or student name...'**
  String get searchBookStudentPlaceholder;

  /// No description provided for @toPickup.
  ///
  /// In en, this message translates to:
  /// **'To Pickup'**
  String get toPickup;

  /// No description provided for @noPickupRequests.
  ///
  /// In en, this message translates to:
  /// **'No pickup requests'**
  String get noPickupRequests;

  /// No description provided for @approvedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved at'**
  String get approvedAt;

  /// No description provided for @dueAt.
  ///
  /// In en, this message translates to:
  /// **'Due at'**
  String get dueAt;

  /// No description provided for @borrowedAt.
  ///
  /// In en, this message translates to:
  /// **'Borrowed at'**
  String get borrowedAt;

  /// No description provided for @loan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get loan;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @classLabel2.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel2;

  /// No description provided for @schoolTypeGenerala.
  ///
  /// In en, this message translates to:
  /// **'Middle School'**
  String get schoolTypeGenerala;

  /// No description provided for @schoolTypeLiceu.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get schoolTypeLiceu;

  /// No description provided for @passwordNeedsUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordNeedsUppercase;

  /// No description provided for @passwordNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordNeedsNumber;

  /// No description provided for @passwordNeedsSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordNeedsSpecialChar;

  /// No description provided for @emailMustBeNlenau.
  ///
  /// In en, this message translates to:
  /// **'Email must be from the nlenau.ro domain'**
  String get emailMustBeNlenau;

  /// No description provided for @pleaseSelectSchoolType.
  ///
  /// In en, this message translates to:
  /// **'Please select school type'**
  String get pleaseSelectSchoolType;

  /// No description provided for @pleaseSelectProfile.
  ///
  /// In en, this message translates to:
  /// **'Please select profile'**
  String get pleaseSelectProfile;

  /// No description provided for @pleaseSelectClassLetter.
  ///
  /// In en, this message translates to:
  /// **'Please select class letter'**
  String get pleaseSelectClassLetter;

  /// No description provided for @pleaseEnterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter invitation code'**
  String get pleaseEnterInvitationCode;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Registration error. Please try again.'**
  String get registrationError;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Check your inbox to activate your account.'**
  String get registrationSuccess;

  /// No description provided for @searchBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Books'**
  String get searchBooksTitle;

  /// No description provided for @selectLoanDuration.
  ///
  /// In en, this message translates to:
  /// **'Select loan duration'**
  String get selectLoanDuration;

  /// No description provided for @bookRequestError.
  ///
  /// In en, this message translates to:
  /// **'Error requesting book/manual: {error}'**
  String bookRequestError(Object error);

  /// No description provided for @loadBooksError.
  ///
  /// In en, this message translates to:
  /// **'Error loading books: {error}'**
  String loadBooksError(Object error);

  /// No description provided for @noBooksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No books/manuals available.'**
  String get noBooksAvailable;

  /// No description provided for @displayError.
  ///
  /// In en, this message translates to:
  /// **'Display error: {error}'**
  String displayError(Object error);

  /// No description provided for @invalidBook.
  ///
  /// In en, this message translates to:
  /// **'Invalid book'**
  String get invalidBook;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @bookDisplayError.
  ///
  /// In en, this message translates to:
  /// **'Error displaying book'**
  String get bookDisplayError;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @lightThemeActive.
  ///
  /// In en, this message translates to:
  /// **'Light theme activated'**
  String get lightThemeActive;

  /// No description provided for @darkThemeActive.
  ///
  /// In en, this message translates to:
  /// **'Dark theme activated'**
  String get darkThemeActive;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @languageChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChangedSuccess;

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get themeDescription;

  /// No description provided for @libraryManagementSystem.
  ///
  /// In en, this message translates to:
  /// **'Library Management System'**
  String get libraryManagementSystem;

  /// No description provided for @welcomeLibrarian.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Mrs. Librarian!'**
  String get welcomeLibrarian;

  /// No description provided for @viewManageRequests.
  ///
  /// In en, this message translates to:
  /// **'View and manage your requests'**
  String get viewManageRequests;

  /// No description provided for @findExamModels.
  ///
  /// In en, this message translates to:
  /// **'Find test models for studying'**
  String get findExamModels;

  /// No description provided for @editDeleteBooks.
  ///
  /// In en, this message translates to:
  /// **'Edit and delete books from catalog'**
  String get editDeleteBooks;

  /// No description provided for @manageLoanRequests.
  ///
  /// In en, this message translates to:
  /// **'Manage loan requests'**
  String get manageLoanRequests;

  /// No description provided for @viewCurrentLoans.
  ///
  /// In en, this message translates to:
  /// **'View current loans'**
  String get viewCurrentLoans;

  /// No description provided for @viewLoanHistory.
  ///
  /// In en, this message translates to:
  /// **'View loan history'**
  String get viewLoanHistory;

  /// No description provided for @manageExamModels.
  ///
  /// In en, this message translates to:
  /// **'Manage test models'**
  String get manageExamModels;

  /// No description provided for @exploreCatalog.
  ///
  /// In en, this message translates to:
  /// **'Explore library catalog'**
  String get exploreCatalog;

  /// No description provided for @generateTeacherCodes.
  ///
  /// In en, this message translates to:
  /// **'Generate registration codes for teachers'**
  String get generateTeacherCodes;

  /// No description provided for @teacherCodes.
  ///
  /// In en, this message translates to:
  /// **'Teacher codes'**
  String get teacherCodes;

  /// No description provided for @aboutTeacherCodes.
  ///
  /// In en, this message translates to:
  /// **'About teacher codes'**
  String get aboutTeacherCodes;

  /// No description provided for @teacherCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Generated codes are used by teachers to register in the system. Each code can be used only once and expires after 6 hours.'**
  String get teacherCodeDescription;

  /// No description provided for @generateNewCode.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get generateNewCode;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @codeGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code generated successfully!'**
  String get codeGeneratedSuccess;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @existingCodes.
  ///
  /// In en, this message translates to:
  /// **'Existing codes'**
  String get existingCodes;

  /// No description provided for @noCodesGenerated.
  ///
  /// In en, this message translates to:
  /// **'No codes generated'**
  String get noCodesGenerated;

  /// No description provided for @generateFirstCode.
  ///
  /// In en, this message translates to:
  /// **'Generate the first code for teachers'**
  String get generateFirstCode;

  /// No description provided for @codeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get codeAvailable;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get codeExpired;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdAt(Object date);

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresAt(Object date);

  /// No description provided for @deleteCode.
  ///
  /// In en, this message translates to:
  /// **'Delete code'**
  String get deleteCode;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete confirmation'**
  String get deleteConfirmation;

  /// No description provided for @deleteCodeConfirmText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this code? This action cannot be undone.'**
  String get deleteCodeConfirmText;

  /// No description provided for @loadCodesError.
  ///
  /// In en, this message translates to:
  /// **'Error loading codes: {error}'**
  String loadCodesError(Object error);

  /// No description provided for @generateCodeError.
  ///
  /// In en, this message translates to:
  /// **'Error generating code: {error}'**
  String generateCodeError(Object error);

  /// No description provided for @copyCodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard!'**
  String get copyCodeSuccess;

  /// No description provided for @deleteCodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code deleted successfully!'**
  String get deleteCodeSuccess;

  /// No description provided for @deleteCodeError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting code: {error}'**
  String deleteCodeError(Object error);

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light Mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark Mode'**
  String get switchToDarkMode;

  /// No description provided for @settingsMenu.
  ///
  /// In en, this message translates to:
  /// **'Settings Menu'**
  String get settingsMenu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
