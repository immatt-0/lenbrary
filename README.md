# Lenbrary - Library Management System

Lenbrary is a comprehensive library management system designed for educational institutions, allowing students to borrow books and librarians to manage the inventory efficiently. The system includes advanced features like email verification, invitation codes for teachers, and automated cleanup processes.

## 🏗️ Project Structure

- **Backend**: Django REST API with SQLite database
- **Frontend**: Cross-platform Flutter application
- **Authentication**: JWT-based with email verification
- **User Management**: Role-based access control (Students, Teachers, Librarians)

## 🚀 Quick Start

### Prerequisites

- Python 3.8+ for the backend
- Flutter 2.0+ for the frontend
- Git (optional)

### Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up the database:**
   ```bash
   python manage.py migrate
   ```

4. **Create a superuser (admin):**
   ```bash
   python manage.py createsuperuser
   ```

5. **Run the server:**
   ```bash
   python manage.py runserver
   ```

### Frontend Setup

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

## 👥 User Roles & Features

### Student Features
- Browse the book catalog
- Request to borrow books
- Return borrowed books
- View borrowing history
- Request loan extensions
- Send messages to librarians

### Teacher Features
- All student features
- Extended borrowing periods
- Higher borrowing limits
- Registration via invitation codes

### Librarian Features
- Complete inventory management
- Approve/reject borrowing requests
- Process book pickups and returns
- Add/edit/remove books
- Manage user accounts
- Create invitation codes for teachers
- View system statistics

### Admin Features
- All librarian features
- Full system administration
- User management
- Database management

## 🔐 Authentication & Security

### Email Verification System
- **6-hour expiration**: Email verification links expire after 6 hours
- **Automatic cleanup**: Expired unverified accounts are automatically deleted
- **User-friendly messages**: Clear error messages when links expire

**How it works:**
1. User registers → EmailVerification record created with 6-hour expiration
2. User clicks verification link → Account verified
3. If link expires → Account automatically deleted
4. User can re-register with same email

### Invitation Code System
- **Single-use codes**: Each invitation code can only be used once
- **6-hour expiration**: Codes automatically expire after 6 hours
- **Admin control**: Only admins and librarians can create invitation codes
- **Teacher registration**: Teachers must use valid invitation codes

**How it works:**
1. Admin/librarian creates invitation code
2. System generates unique 8-character uppercase code
3. Teacher uses code during registration
4. Code is consumed and cannot be reused

## 🛠️ Management Commands

### User Management
```bash
# View all users (verified and unverified)
python manage.py view_all_users

# View all users and automatically delete expired ones
python manage.py view_all_users --delete-expired

# View all invitation codes
python manage.py view_invitation_codes
```

### Cleanup Commands
```bash
# Clean up expired email verifications
python manage.py cleanup_expired_verifications

# Clean up expired invitation codes
python manage.py cleanup_expired_invitations

# Clean up unverified accounts
python manage.py cleanup_unverified_accounts
```

### Database Management
```bash
# Reset database to default state
python manage.py flush

# Create test data
python manage.py shell
# Then run: exec(open('create_test_data.py').read())
```

## 📡 API Endpoints

### Authentication
- `POST /api/token/` - Get JWT token
- `POST /api/token/refresh/` - Refresh JWT token
- `POST /api/register/` - User registration
- `POST /api/verify-email/` - Email verification

### Books
- `GET /book-library/books/` - List all books
- `POST /book-library/books/` - Add new book (librarian only)
- `PUT /book-library/books/{id}/` - Update book (librarian only)
- `DELETE /book-library/books/{id}/` - Delete book (librarian only)

### Borrowing
- `POST /book-library/request-book/` - Request to borrow a book
- `GET /book-library/my-books/` - View user's borrowed books
- `POST /book-library/return-book/` - Return a borrowed book
- `POST /book-library/approve-request/` - Approve borrowing request (librarian only)
- `POST /book-library/reject-request/` - Reject borrowing request (librarian only)

### Invitation Codes
- `POST /book-library/invitation-codes/create/` - Create invitation code (admin/librarian only)
- `GET /book-library/invitation-codes/` - List invitation codes (admin/librarian only)
- `DELETE /book-library/invitation-codes/{id}/delete/` - Delete invitation code (admin/librarian only)
- `POST /book-library/invitation-codes/cleanup/` - Clean up expired codes (admin/librarian only)

### Messages
- `GET /book-library/messages/` - Get user messages
- `POST /book-library/messages/` - Send message

## 🔧 Configuration

### Email Settings
Configure email settings in `backend/lenbrary_api/settings.py`:
```python
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'your-smtp-server.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'your-email@domain.com'
EMAIL_HOST_PASSWORD = 'your-password'
```

### Frontend Configuration
Update API base URL in `frontend/lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-server-ip:8000';
```

## 🧹 Automated Cleanup

### Setting Up Automatic Cleanup

#### Option 1: Cron Job (Linux/Mac)
```bash
# Edit crontab
crontab -e

# Add these lines (adjust paths as needed)
0 * * * * cd /path/to/lenbrary/backend && python manage.py cleanup_expired_verifications
15 * * * * cd /path/to/lenbrary/backend && python manage.py cleanup_expired_invitations
30 * * * * cd /path/to/lenbrary/backend && python manage.py cleanup_unverified_accounts
```

#### Option 2: Windows Task Scheduler
1. Open Task Scheduler
2. Create new Basic Tasks for each cleanup command
3. Set triggers to run every hour
4. Set actions to run the respective management commands

#### Option 3: Systemd Timer (Linux)
Create service files for each cleanup command and set up timers to run them hourly.

## 🧪 Testing

### Test Credentials
After setup, you can use these test accounts:

1. **Admin/Superuser**
   - Email: `admin@nlenau.ro`
   - Password: `adminpass123`

2. **Librarian**
   - Email: `librarian@nlenau.ro`
   - Password: `Library1!`

3. **Teacher**
   - Email: `teacher@nlenau.ro`
   - Password: `Teacher1!`

4. **Student**
   - Email: `student@nlenau.ro`
   - Password: `Student1!`

### Running Tests
```bash
# Test invitation code system
python test_invitation_system.py

# Test email verification
python manage.py test booklibrary.tests
```

## 🐛 Troubleshooting

### Common Issues

#### Backend Issues
- **Database errors**: Run `python manage.py migrate`
- **Permission issues**: Check user groups and roles
- **Email not sending**: Verify email configuration in settings.py

#### Frontend Issues
- **Connection errors**: Check API base URL and server status
- **Build errors**: Run `flutter clean && flutter pub get`
- **Device connection**: Use network IP instead of localhost for physical devices

#### Email Verification Issues
- **Links not working**: Check email configuration
- **Expired links**: Users can re-register after 6 hours
- **Cleanup not working**: Verify cron jobs or scheduled tasks

### Error Messages

#### Email Verification
- **Expired Link**: "Linkul de verificare a expirat (6 ore). Contul tău a fost șters automat. Poți să te înregistrezi din nou."
- **Expired Login**: "Linkul de verificare a expirat (6 ore). Contul a fost șters automat. Poți să te înregistrezi din nou."

#### Invitation Codes
- **Invalid Code**: "Invalid invitation code"
- **Expired Code**: "This invitation code has expired"
- **Used Code**: "This invitation code has already been used"
- **Missing Code**: "Invitation code is required for teacher registration"

## 📊 Database Models

### Core Models
- **User**: Django's built-in user model with custom fields
- **Student**: Student-specific information (department, class, school type)
- **Book**: Book information (title, author, stock, category)
- **BookBorrowing**: Borrowing records and status tracking
- **Message**: User-to-user messaging system
- **Notification**: System notifications for users

### Security Models
- **EmailVerification**: Email verification tokens with expiration
- **InvitationCode**: Single-use invitation codes for teacher registration

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Email Verification**: Prevents fake accounts
- **Invitation Codes**: Controlled teacher registration
- **Role-based Access**: Different permissions for different user types
- **Automatic Cleanup**: Prevents database bloat from expired data
- **Input Validation**: Server-side validation for all inputs

## 📈 Performance

- **Database Optimization**: Proper indexing and relationships
- **Caching**: Django's built-in caching system
- **Cleanup Automation**: Regular cleanup prevents performance degradation
- **Efficient Queries**: Optimized database queries

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided for educational purposes only.

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review error messages carefully
3. Check Django and Flutter documentation
4. Create an issue in the repository

---

**Last Updated**: January 2025
**Version**: 2.0.0
