// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get registerAsTeacher => 'Register as teacher';

  @override
  String get enterTeacherCode => 'Enter teacher code';

  @override
  String get back => 'Back';

  @override
  String get appTitle => 'Lenbrary';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get addCover => 'Add Cover';

  @override
  String get chooseCoverMethod => 'Choose how you want to add the book cover:';

  @override
  String get addPdf => 'Add PDF';

  @override
  String get choosePdfMethod => 'Choose how you want to add the PDF:';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get selectFile => 'Select File';

  @override
  String get isbn => 'ISBN';

  @override
  String get title => 'Title';

  @override
  String get author => 'Author';

  @override
  String get description => 'Description';

  @override
  String get pages => 'Pages';

  @override
  String get language => 'Language';

  @override
  String get category => 'Category';

  @override
  String get price => 'Price';

  @override
  String get stock => 'Stock';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get books => 'Books';

  @override
  String get teacher => 'Teacher';

  @override
  String get myRequests => 'My requests';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get register => 'Register';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get usernameOrEmail => 'Username or Email';

  @override
  String get enterUsernameOrEmail =>
      'Please enter your username or email address';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get authentication => 'Authentication';

  @override
  String get noAccountRegister => 'Don\'t have an account? Register';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get enterFirstName => 'Please enter your first name';

  @override
  String get enterLastName => 'Please enter your last name';

  @override
  String get enterEmail => 'Please enter your email address';

  @override
  String get schoolType => 'School Type';

  @override
  String get selectSchoolType => 'Please select a school type';

  @override
  String get classLevel => 'Class';

  @override
  String get selectClass => 'Select Class';

  @override
  String get selectProfile => 'Please select a profile';

  @override
  String get classLetter => 'Class Letter';

  @override
  String get selectClassLetter => 'Please select a class letter';

  @override
  String get invitationCode => 'Invitation Code';

  @override
  String get enterInvitationCode => 'Please enter the invitation code';

  @override
  String get createAccount => 'Create Account';

  @override
  String get creatingAccount => 'Creating account...';

  @override
  String get registrationTitle => 'Create your account';

  @override
  String get registrationSubtitle => 'Fill in the details to register';

  @override
  String get loading => 'Loading...';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get searchBooks => 'Search books';

  @override
  String get requestBook => 'Request Book';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get theme => 'Theme';

  @override
  String get bookAdded => 'Book added';

  @override
  String get requestSent => 'Request sent successfully!';

  @override
  String get requestFailed => 'Failed to send request';

  @override
  String get retry => 'Retry';

  @override
  String get noResults => 'No results found';

  @override
  String noResultsFor(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get noActiveLoans => 'No active loans';

  @override
  String get selectDuration => 'Select loan duration';

  @override
  String get oneWeek => '1 Week';

  @override
  String get twoWeeks => '2 Weeks';

  @override
  String get oneMonth => '1 Month';

  @override
  String get twoMonths => '2 Months';

  @override
  String get loans => 'Loans';

  @override
  String get activeLoans => 'Active loans';

  @override
  String get loadingLoans => 'Loading loans...';

  @override
  String get loanHistory => 'Loan history';

  @override
  String get pickupAndLoans => 'Pickup & Loans';

  @override
  String get manageBooks => 'Manage books';

  @override
  String get addBook => 'Add book';

  @override
  String get editBook => 'Edit Book';

  @override
  String get deleteBook => 'Delete Book';

  @override
  String get bookDetails => 'Book Details';

  @override
  String get takePicture => 'Take Picture';

  @override
  String get addFromGallery => 'Add from Gallery';

  @override
  String get addPDF => 'Add PDF';

  @override
  String get choosePDFFile => 'Choose PDF File';

  @override
  String get resourceType => 'Resource Type';

  @override
  String get required => 'required';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get additionalDetails => 'Additional Details';

  @override
  String get stockInfo => 'Stock Information';

  @override
  String get totalInventory => 'Total Inventory';

  @override
  String get availableStock => 'Available Stock';

  @override
  String get fillBookDetails => 'Fill in the details for the new book/manual';

  @override
  String get requiredFields => 'Fields marked with * are required';

  @override
  String get emailDomainError => 'Email must be from nlenau.ro domain';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters long';

  @override
  String get teacherAccount => 'Teacher account';

  @override
  String get studentInformation => 'Student information';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get generalSchool => 'General School';

  @override
  String get highSchool => 'High School';

  @override
  String welcomeUser(Object userName) {
    return 'Welcome, $userName!';
  }

  @override
  String get whatDoYouWantToday => 'What would you like to do today?';

  @override
  String get searchBooksShort => 'Search books and manuals...';

  @override
  String get addNewBook => 'Add a new book to catalog';

  @override
  String get viewRequests => 'View Requests';

  @override
  String get examModels => 'Test models';

  @override
  String get generateCodes => 'Generate Codes';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get pleaseEnter => 'Please enter';

  @override
  String get book => 'Book';

  @override
  String get manual => 'Manual';

  @override
  String get name => 'Name';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get searchByBookName => '🔍 Search by book name...';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get borrowed => 'Borrowed';

  @override
  String get returned => 'Returned';

  @override
  String get bookTitle => 'Book Title';

  @override
  String get publicationYear => 'Publication Year';

  @override
  String get inventory => 'Inventory';

  @override
  String get requestDuration => 'Request Duration';

  @override
  String get days => 'days';

  @override
  String get message => 'Message';

  @override
  String get noBooks => 'No books available';

  @override
  String get noBooksFound => 'No books found';

  @override
  String get noRequests => 'No requests';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get readNotifications => 'Read notifications';

  @override
  String get unreadNotifications => 'Unread notifications';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get romanian => 'Romanian';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get systemMode => 'System Mode';

  @override
  String get aboutApp => 'About App';

  @override
  String get version => 'Version';

  @override
  String get appDescription =>
      'A comprehensive digital library management system';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get optional => 'optional';

  @override
  String get invalidInput => 'Invalid input';

  @override
  String get mustBeNumber => 'Must be a number';

  @override
  String get cannotExceed => 'Cannot exceed';

  @override
  String get unknownBook => 'Unknown book';

  @override
  String get pickupDate => 'Pickup date:';

  @override
  String get bookAddedSuccessfully =>
      'Book/manual has been added successfully!';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get dueDate => 'Due date: ';

  @override
  String get notAvailable => 'Not available';

  @override
  String get processing => 'Processing...';

  @override
  String get bookReturned => 'Book returned';

  @override
  String get gimnaziuV => 'Middle School V';

  @override
  String get gimnaziuVI => 'Middle School VI';

  @override
  String get gimnaziuVII => 'Middle School VII';

  @override
  String get gimnaziuVIII => 'Middle School VIII';

  @override
  String get liceulIX => 'High School IX';

  @override
  String get liceulX => 'High School X';

  @override
  String get liceulXI => 'High School XI';

  @override
  String get liceulXII => 'High School XII';

  @override
  String get bookUpdated => 'Book updated';

  @override
  String get bookDeleted => 'Book deleted';

  @override
  String get requestApproved => 'Request approved';

  @override
  String get requestRejected => 'Request rejected successfully!';

  @override
  String get extensionRequested => 'Extension request';

  @override
  String get extensionApproved => 'Extension approved';

  @override
  String get extensionRejected => 'Extension rejected';

  @override
  String get bookType => 'Book Type';

  @override
  String get cover => 'Cover';

  @override
  String get choosePdfFile => 'Choose PDF file';

  @override
  String get totalCopies => 'Total number of copies';

  @override
  String get availableCopies => 'Number of copies available for borrowing';

  @override
  String get stockCannotExceedInventory =>
      'Stock cannot be greater than inventory';

  @override
  String get pendingRequests => 'Pending requests';

  @override
  String get extensionRequests => 'Extension requests';

  @override
  String get extensionRequestDescription =>
      'Here you can view extension requests';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get reason => 'Reason';

  @override
  String get approveRequest => 'Approve Request';

  @override
  String get rejectRequest => 'Reject Request';

  @override
  String get requestedOn => 'Requested on';

  @override
  String get requestedBy => 'Requested by';

  @override
  String get duration => 'Duration';

  @override
  String get extend => 'Extend';

  @override
  String get extensionReason => 'Extension Reason';

  @override
  String get newDuration => 'New Duration';

  @override
  String get requestExtension => 'Request Extension';

  @override
  String get viewDetails => 'View Details';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get adminPanel => 'Library administration panel';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get manageRequests => 'Manage Requests';

  @override
  String get reports => 'Reports';

  @override
  String get statistics => 'Statistics';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get passwordNoSpaces => 'Password cannot contain spaces';

  @override
  String get passwordUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordDigit => 'Password must contain at least one digit';

  @override
  String get passwordSpecialChar =>
      'Password must contain at least one special character';

  @override
  String get pleaseConfirmPassword => 'Please confirm the password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseSelectTitle => 'Please enter a title';

  @override
  String get pleaseSelectAuthor => 'Please enter an author';

  @override
  String get pleaseSelectCategory => 'Please enter a category';

  @override
  String get pleaseSelectDescription => 'Please enter a description';

  @override
  String get pleaseEnterValidYear => 'Please enter a valid year';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get stockInformation => 'Stock Information';

  @override
  String get pleaseEnterTotalInventory => 'Please enter total inventory';

  @override
  String get inventoryMustBeNumber => 'Inventory must be a number';

  @override
  String get totalCopiesNumber => 'Total number of copies';

  @override
  String get pleaseEnterAvailableStock => 'Please enter available stock';

  @override
  String get stockMustBeNumber => 'Stock must be a number';

  @override
  String get availableCopiesNumber => 'Number of copies available for loan';

  @override
  String get adding => 'Adding...';

  @override
  String get errorCameraAccess => 'Error accessing camera';

  @override
  String get errorGalleryAccess => 'Error accessing gallery';

  @override
  String get errorReadingPdf => 'Error reading PDF file';

  @override
  String get errorAccessingPdf => 'Error accessing PDF file';

  @override
  String get errorSelectingPdf => 'Error selecting PDF file';

  @override
  String get choosePdfForManual => 'Choose PDF file for manual:';

  @override
  String get pleaseSelectClass => 'Please select class';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pleaseEnterAuthor => 'Please enter an author';

  @override
  String get pleaseEnterCategory => 'Please enter a category';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get manualPDF => 'Manual PDF';

  @override
  String get uploadManualPdfFile => 'Upload the manual PDF file';

  @override
  String pdfFileSize(String size) {
    return 'PDF file ($size KB)';
  }

  @override
  String get pdfFileSelected => 'PDF file selected';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get uploadPdfFile => 'Upload PDF file';

  @override
  String get selectManualPdfFile => 'Select the manual PDF file';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get pdfSuccessfullyAdded => 'PDF successfully added';

  @override
  String get pleaseSelectPdfFile => 'Please select a PDF file.';

  @override
  String get pleaseSelectExamType => 'Please select the exam type.';

  @override
  String get pleaseSelectSubject => 'Please select the subject.';

  @override
  String errorAddingItem(String error) {
    return 'Error adding item: $error';
  }

  @override
  String get addExamModel => 'Add Exam Model';

  @override
  String get newExamModel => 'New Exam Model';

  @override
  String get fillExamModelDetails => 'Fill in the exam model details';

  @override
  String get examModelName => 'Exam model name';

  @override
  String get enterExamModelName => 'Enter a name';

  @override
  String get examType => 'Exam Type';

  @override
  String get nationalEvaluation => 'National Evaluation (EN)';

  @override
  String get baccalaureate => 'Baccalaureate (BAC)';

  @override
  String get selectExamTypeValidator => 'Select the exam type';

  @override
  String get subject => 'Subject';

  @override
  String get mathematics => 'Mathematics';

  @override
  String get selectSubjectValidator => 'Select the subject';

  @override
  String get addModel => 'Add model';

  @override
  String get tapToSelectPdfFile => 'Tap to select a PDF file';

  @override
  String get requestLoan => 'Request Loan';

  @override
  String get loanDuration => 'Loan duration: ';

  @override
  String get messageOptional => 'Message (optional):';

  @override
  String get writeMessageForLibrarian =>
      'Write a message for the librarian... (optional)';

  @override
  String get loanRequestSuccess => 'Loan request registered successfully!';

  @override
  String errorRequestingBook(String error) {
    return 'Error requesting book/manual: $error';
  }

  @override
  String classLabel(String className) {
    return 'Class $className';
  }

  @override
  String available(int count) {
    return 'Available: $count';
  }

  @override
  String get unavailable => 'Unavailable';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get pdfOpenError => 'Could not open PDF.';

  @override
  String pdfOpenErrorDetails(String error) {
    return 'Error opening PDF: $error';
  }

  @override
  String get sending => 'Sending...';

  @override
  String get refresh => 'Refresh';

  @override
  String get searchExamModels => '🔍 Search exam models...';

  @override
  String get allTypes => 'All Types';

  @override
  String get allSubjects => 'All subjects';

  @override
  String get math => 'Math';

  @override
  String get mate => 'Math';

  @override
  String get deleteModel => 'Delete model';

  @override
  String get examModelsTitle => 'Test Models';

  @override
  String get searchExamModelsHint => 'Search test models...';

  @override
  String get testType => 'Test type';

  @override
  String get allTestTypes => 'All types';

  @override
  String get modelWithoutName => 'Model without name';

  @override
  String get noTestsAvailable => 'No tests available';

  @override
  String get noTestsForSearch => 'No tests found for your search';

  @override
  String get modelsWillAppear => 'Models will appear here after they are added';

  @override
  String get modifySearchTerms => 'Try modifying the search terms';

  @override
  String get couldNotOpenPdf => 'Could not open PDF.';

  @override
  String get extensionRequestsTitle => 'Extension Requests';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get loadingRequests => 'Loading requests...';

  @override
  String get noExtensionRequests => 'No extension requests';

  @override
  String get extensionRequestsWillAppear =>
      'Extension requests will appear here';

  @override
  String get alreadyExtendedMessage =>
      'This book has already been extended once. It cannot be extended again.';

  @override
  String get student => 'Student';

  @override
  String get fromLabel => 'From:';

  @override
  String get toLabel => 'To:';

  @override
  String get extensionRequestDetailsTitle => 'Extension request details';

  @override
  String get currentReturnDate => 'Current return date';

  @override
  String get extendedReturnDate => 'Extended return date';

  @override
  String get studentMessage => 'Student message';

  @override
  String get extensionApprovedMessage => 'Extension approved successfully!';

  @override
  String get approving => 'Approving...';

  @override
  String get extensionRejectedMessage => 'Extension rejected successfully!';

  @override
  String get rejecting => 'Rejecting...';

  @override
  String get unknown => 'Unknown';

  @override
  String get alreadyExtended => 'Already extended';

  @override
  String errorRejecting(String error) {
    return 'Error rejecting: $error';
  }

  @override
  String get addExamModelButton => 'Add exam model';

  @override
  String get loadingModels => 'Loading models...';

  @override
  String futureSubject(String subject) {
    return 'We will add $subject tests in the future';
  }

  @override
  String get noModelsFound => 'No models found for your search';

  @override
  String get noModelsExist => 'No exam models exist';

  @override
  String get focusOnMainSubjects =>
      'Currently we focus on mathematics and Romanian';

  @override
  String get tryModifyingSearch => 'Try modifying the search terms';

  @override
  String get addFirstModel => 'Add the first exam model';

  @override
  String get openPdfTooltip => 'Open PDF';

  @override
  String get deleteModelTooltip => 'Delete model';

  @override
  String errorLoadingModels(String error) {
    return 'Error loading models: $error';
  }

  @override
  String errorDeleting(String error) {
    return 'Error deleting: $error';
  }

  @override
  String addItem(String item) {
    return 'Add $item';
  }

  @override
  String get loanHistoryTitle => 'Loan History';

  @override
  String recordsCount(String count) {
    return '$count records';
  }

  @override
  String get backTooltip => 'Back';

  @override
  String get searchBooksPlaceholder => '🔍 Search by name, author or title...';

  @override
  String get loadingHistory => 'Loading history...';

  @override
  String noSearchResults(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get noLoanHistory => 'No loan history exists';

  @override
  String get tryModifyingSearchTerms => 'Try modifying the search terms';

  @override
  String get historyWillAppear =>
      'History will appear here after loans are made';

  @override
  String get notReturnedYet => 'Not returned yet';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get unknownAuthor => 'Unknown author';

  @override
  String get requestDate => 'Request date: ';

  @override
  String get loginHintShort => 'first.last';

  @override
  String get loginHintLong => 'first.last or first.last@nlenau.ro';

  @override
  String get manageBooksShort => 'Manage';

  @override
  String get manageBooksLong => 'Manage Books';

  @override
  String get manuals => 'Manuals';

  @override
  String get searchBooksLong =>
      'Search by title, author, category or class (e.g. VIII or 8)...';

  @override
  String noBookFoundFor(String query) {
    return 'No book found for \"$query\"';
  }

  @override
  String get noBooksInLibrary => 'No books in library';

  @override
  String get noManualsInLibrary => 'No manuals in library';

  @override
  String get reload => 'Reload';

  @override
  String stockLabel(String current, String total) {
    return 'Stock: $current/$total';
  }

  @override
  String get noLoanRequests => 'You have no loan requests';

  @override
  String get requestsWillAppear =>
      'Your requests will appear here after you request books';

  @override
  String get readyForPickup => 'Ready for pickup';

  @override
  String get overdue => 'Overdue';

  @override
  String get request => 'Request';

  @override
  String get estimated => 'Estimated';

  @override
  String get tapToExtend => 'Tap to extend';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get confirmCancelRequest =>
      'Are you sure you want to cancel this request?';

  @override
  String get messageForLibrarian => 'Message for librarian (optional):';

  @override
  String get addMessage => 'Add a message...';

  @override
  String get giveUp => 'Give up';

  @override
  String get requestCancelledSuccess =>
      'Request has been cancelled successfully.';

  @override
  String cancelError(String error) {
    return 'Error cancelling: $error';
  }

  @override
  String get extendLoan => 'Extend loan';

  @override
  String get extensionPeriod => 'Extension period:';

  @override
  String daysLabel(int days) {
    return '$days days';
  }

  @override
  String get submitRequest => 'Submit request';

  @override
  String get extensionRequestSuccess =>
      'Extension request has been sent successfully!';

  @override
  String get bookAlreadyExtended =>
      'This book has already been extended once and cannot be extended again.';

  @override
  String get loadingNotifications => 'Loading notifications...';

  @override
  String notificationLoadError(String error) {
    return 'Error loading notifications: $error';
  }

  @override
  String markAsReadError(String error) {
    return 'Error marking notification as read: $error';
  }

  @override
  String markAllAsReadError(String error) {
    return 'Error marking notifications as read: $error';
  }

  @override
  String get allNotificationsMarkedAsRead =>
      'All notifications have been marked as read';

  @override
  String get date => 'Date:';

  @override
  String get bookRequested => 'Book request';

  @override
  String get bookAccepted => 'Book accepted';

  @override
  String get bookRejected => 'Book rejected';

  @override
  String get requestCancelled => 'Request cancelled';

  @override
  String get teacherRegistered => 'Teacher registered';

  @override
  String get newMessage => 'New message';

  @override
  String get unknownNotification => 'Unknown notification';

  @override
  String notificationWithType(String type) {
    return 'Notification ($type)';
  }

  @override
  String get filterNotifications => 'Filter notifications';

  @override
  String showingAllNotifications(int count) {
    return 'Showing all notifications ($count)';
  }

  @override
  String activeFilter(String filterName, int count) {
    return 'Active filter: $filterName ($count)';
  }

  @override
  String get noNotificationsOfType => 'You have no notifications of this type';

  @override
  String get allNotificationsWillAppear =>
      'All your notifications will appear here';

  @override
  String get tryChangingFilter =>
      'Try changing the filter to see other notifications';

  @override
  String get read => 'Read';

  @override
  String get newNotification => 'New';

  @override
  String get now => 'Now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get allNotifications => 'All notifications';

  @override
  String get registeredTeachers => 'Registered teachers';

  @override
  String get bookRequests => 'Book requests';

  @override
  String get acceptedBooks => 'Accepted books';

  @override
  String get rejectedBooks => 'Rejected books';

  @override
  String get returnedBooks => 'Returned books';

  @override
  String get approvedExtensions => 'Approved extensions';

  @override
  String get rejectedExtensions => 'Rejected extensions';

  @override
  String get cancelledRequests => 'Cancelled requests';

  @override
  String get approvedRequests => 'Approved requests';

  @override
  String get addedBooks => 'Added books';

  @override
  String get updatedBooks => 'Updated books';

  @override
  String get deletedBooks => 'Deleted books';

  @override
  String get messages => 'Messages';

  @override
  String get otherNotifications => 'Other notifications';

  @override
  String get requestApprovedSuccess => 'Request approved successfully!';

  @override
  String get requestRejectedSuccess => 'Request rejected successfully!';

  @override
  String get bookRequestsTitle => 'Book Requests';

  @override
  String get bookManualsRequestsTitle => 'Book and Manual Requests';

  @override
  String get searchPlaceholder => '🔍 Search...';

  @override
  String get searchDetailedPlaceholder =>
      '🔍 Search by book name or student name...';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get noApprovedRequests => 'No approved requests';

  @override
  String get noRequestsNeedApproval => 'No requests need approval';

  @override
  String get noApprovedRequestsCurrently =>
      'No approved requests at the moment';

  @override
  String get dueDateLabel => 'Due date: ';

  @override
  String get loanDurationLabel => 'Loan duration: ';

  @override
  String get markAsPickedUp => 'Mark as picked up';

  @override
  String get bookMarkedAsPickedUp =>
      'The book/manual has been marked as picked up!';

  @override
  String get markingPickedUp => 'Mark Picked Up';

  @override
  String get searchBookStudentPlaceholder =>
      'Search by book name or student name...';

  @override
  String get toPickup => 'To Pickup';

  @override
  String get noPickupRequests => 'No pickup requests';

  @override
  String get approvedAt => 'Approved at';

  @override
  String get dueAt => 'Due at';

  @override
  String get borrowedAt => 'Borrowed at';

  @override
  String get loan => 'Loan';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get classLabel2 => 'Class';

  @override
  String get schoolTypeGenerala => 'Middle School';

  @override
  String get schoolTypeLiceu => 'High School';

  @override
  String get passwordNeedsUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordNeedsNumber => 'Password must contain at least one number';

  @override
  String get passwordNeedsSpecialChar =>
      'Password must contain at least one special character';

  @override
  String get emailMustBeNlenau => 'Email must be from the nlenau.ro domain';

  @override
  String get pleaseSelectSchoolType => 'Please select school type';

  @override
  String get pleaseSelectProfile => 'Please select profile';

  @override
  String get pleaseSelectClassLetter => 'Please select class letter';

  @override
  String get pleaseEnterInvitationCode => 'Please enter invitation code';

  @override
  String get registrationError => 'Registration error. Please try again.';

  @override
  String get registrationSuccess =>
      'Registration successful! Check your inbox to activate your account.';

  @override
  String get searchBooksTitle => 'Search Books';

  @override
  String get selectLoanDuration => 'Select loan duration';

  @override
  String bookRequestError(Object error) {
    return 'Error requesting book/manual: $error';
  }

  @override
  String loadBooksError(Object error) {
    return 'Error loading books: $error';
  }

  @override
  String get noBooksAvailable => 'No books/manuals available.';

  @override
  String displayError(Object error) {
    return 'Display error: $error';
  }

  @override
  String get invalidBook => 'Invalid book';

  @override
  String get noCategory => 'No category';

  @override
  String get bookDisplayError => 'Error displaying book';

  @override
  String get appSettings => 'App Settings';

  @override
  String get appTheme => 'App Theme';

  @override
  String get lightThemeActive => 'Light theme activated';

  @override
  String get darkThemeActive => 'Dark theme activated';

  @override
  String get appLanguage => 'App Language';

  @override
  String get languageChangedSuccess => 'Language changed successfully';

  @override
  String get themeDescription => 'Switch between light and dark theme';

  @override
  String get libraryManagementSystem => 'Library Management System';

  @override
  String get welcomeLibrarian => 'Welcome, Mrs. Librarian!';

  @override
  String get viewManageRequests => 'View and manage your requests';

  @override
  String get findExamModels => 'Find test models for studying';

  @override
  String get editDeleteBooks => 'Edit and delete books from catalog';

  @override
  String get manageLoanRequests => 'Manage loan requests';

  @override
  String get viewCurrentLoans => 'View current loans';

  @override
  String get viewLoanHistory => 'View loan history';

  @override
  String get manageExamModels => 'Manage test models';

  @override
  String get exploreCatalog => 'Explore library catalog';

  @override
  String get generateTeacherCodes => 'Generate registration codes for teachers';

  @override
  String get teacherCodes => 'Teacher codes';

  @override
  String get aboutTeacherCodes => 'About teacher codes';

  @override
  String get teacherCodeDescription =>
      'Generated codes are used by teachers to register in the system. Each code can be used only once and expires after 6 hours.';

  @override
  String get generateNewCode => 'Generate new code';

  @override
  String get generating => 'Generating...';

  @override
  String get codeGeneratedSuccess => 'Code generated successfully!';

  @override
  String get copyCode => 'Copy code';

  @override
  String get existingCodes => 'Existing codes';

  @override
  String get noCodesGenerated => 'No codes generated';

  @override
  String get generateFirstCode => 'Generate the first code for teachers';

  @override
  String get codeAvailable => 'Available';

  @override
  String get codeExpired => 'Expired';

  @override
  String createdAt(Object date) {
    return 'Created: $date';
  }

  @override
  String expiresAt(Object date) {
    return 'Expires: $date';
  }

  @override
  String get deleteCode => 'Delete code';

  @override
  String get deleteConfirmation => 'Delete confirmation';

  @override
  String get deleteCodeConfirmText =>
      'Are you sure you want to delete this code? This action cannot be undone.';

  @override
  String loadCodesError(Object error) {
    return 'Error loading codes: $error';
  }

  @override
  String generateCodeError(Object error) {
    return 'Error generating code: $error';
  }

  @override
  String get copyCodeSuccess => 'Code copied to clipboard!';

  @override
  String get deleteCodeSuccess => 'Code deleted successfully!';

  @override
  String deleteCodeError(Object error) {
    return 'Error deleting code: $error';
  }

  @override
  String get switchToLightMode => 'Switch to Light Mode';

  @override
  String get switchToDarkMode => 'Switch to Dark Mode';

  @override
  String get settingsMenu => 'Settings Menu';
}
