# Lenbrary - Library Management System

Lenbrary is a comprehensive library management system designed for educational institutions, allowing students to borrow books and librarians to manage the inventory efficiently.

## Project Structure

- **Backend**: Django REST API with SQLite database
- **Frontend**: Cross-platform Flutter application

## Setup Instructions

### Prerequisites

- Python 3.8+ for the backend
- Flutter 2.0+ for the frontend
- Git (optional)

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd backend
   ```

2. Install dependencies:
   ```
   pip install django djangorestframework djangorestframework-simplejwt django-cors-headers
   ```

3. Set up the database:
   ```
   python manage.py migrate
   ```
   
   Alternatively, use the provided utility script:
   ```
   python reset_db.py
   ```

4. Create test data (optional):
   ```
   python create_test_data.py
   ```

5. Run the server:
   ```
   python run_server.py
   ```

### Frontend Setup

1. Navigate to the frontend directory:
   ```
   cd frontend
   ```

2. Install Flutter dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

## Testing Credentials

The system comes with pre-configured users:

1. **Librarian**
   - Email: librarian@nlenau.ro
   - Password: Librarian123

2. **Teacher**
   - Email: teacher@nlenau.ro
   - Password: Teacher123

3. **Student**
   - Email: student@nlenau.ro
   - Password: Student123

## Features

### Student Features
- Browse the book catalog
- Request to borrow books
- Return borrowed books
- View borrowing history

### Teacher Features
- All student features
- Extended borrowing periods
- Higher borrowing limits

### Librarian Features
- Complete inventory management
- Approve/reject borrowing requests
- Process book pickups and returns
- Add/edit/remove books in the library
- Manage user accounts

## Utility Scripts

The backend includes several utility scripts:

- `run_server.py` - Start the Django server
- `reset_db.py` - Reset the database to default state
- `create_test_data.py` - Populate database with test data
- `create_librarian.py` - Create a librarian account
- `list_users.py` - List all users in the system
- `list_users_groups.py` - List users and their permission groups
- `check_user_relations.py` - Check user relationships
- `update_student.py` - Update student information

## API Endpoints

The backend exposes the following main API endpoints:

- `POST /api/token/` - Authentication and token retrieval
- `GET /book-library/books` - List all available books
- `POST /book-library/request-book` - Request to borrow a book
- `GET /book-library/my-books` - View user's borrowed books
- `POST /book-library/return-book` - Return a borrowed book

For complete API documentation, run the backend server and visit:
http://localhost:8000/api-auth/login/

## Troubleshooting

### Backend Issues

- Database errors:
  ```
  python reset_db.py
  ```

- Permission issues:
  ```
  python check_profiles.py
  ```

### Frontend Issues

- Connection issues:
  1. Verify backend server is running on expected port
  2. Check API base URL in `frontend/lib/services/api_service.dart`
  3. For physical devices, use the correct network IP address instead of localhost

## License

This project is provided for educational purposes only. 
