from django.test import TestCase
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from .models import Book, Student, BookBorrowing
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework_simplejwt.tokens import RefreshToken
import json

class LibraryTestCase(APITestCase):
    def setUp(self):
        # Create test users
        self.client = APIClient()
        
        # Create a student user
        self.student_user = User.objects.create_user(
            username='student1',
            password='testpass123',
            email='student1@test.com',
            first_name='Test',
            last_name='Student'
        )
        
        # Get JWT tokens for the user
        refresh = RefreshToken.for_user(self.student_user)
        self.access_token = str(refresh.access_token)
        
        # Create student profile
        self.student = Student.objects.create(
            user=self.student_user,
            student_id='ST12345',
            department='Computer Science'
        )
        
        # Create test books
        self.book1 = Book.objects.create(
            name='Python Programming',
            inventory=5,
            author='John Doe',
            stock=5,
            isbn='1234567890',
            description='A great book about Python',
            category='Programming'
        )
        
        self.book2 = Book.objects.create(
            name='Data Structures',
            inventory=3,
            author='Jane Smith',
            stock=3,
            isbn='0987654321',
            description='Learn about data structures',
            category='Computer Science'
        )

    def test_list_books(self):
        """Test getting list of books"""
        # Authenticate with JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        response = self.client.get(reverse('books'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 2)

    def test_search_books(self):
        """Test searching books"""
        # Authenticate with JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        response = self.client.get(f"{reverse('books')}?search=Python")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]['name'], 'Python Programming')

    def test_get_book_detail(self):
        """Test getting a single book's details"""
        # Authenticate with JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        response = self.client.get(f"{reverse('book')}?id={self.book1.id}")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()['name'], 'Python Programming')

    def test_create_book(self):
        """Test creating a new book"""
        # Authenticate with JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        new_book_data = {
            'name': 'New Book',
            'inventory': 10,
            'author': 'New Author',
            'stock': 10,
            'isbn': '1111111111',
            'category': 'Fiction'
        }
        response = self.client.post(reverse('book'), new_book_data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Book.objects.count(), 3)

    def test_book_borrowing_flow(self):
        """Test the complete flow of borrowing a book"""
        # Login using JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        
        # Request to borrow a book
        response = self.client.post(
            reverse('request_book'),
            {'book_id': self.book1.id},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()['status'], 'PENDING')
        
        # Get student's books
        response = self.client.get(reverse('my_books'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)
        
        # Get the borrowing ID from the response
        borrowing_id = response.json()[0]['id']
        
        # Simulate librarian approving the request (we'll need to update directly)
        borrowing = BookBorrowing.objects.get(id=borrowing_id)
        borrowing.status = 'BORROWED'
        borrowing.save()
        
        # Try to return the book
        response = self.client.post(reverse('return_book', args=[borrowing_id]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()['status'], 'RETURNED')

    def test_unauthorized_access(self):
        """Test that unauthorized users cannot access protected endpoints"""
        # Ensure no authentication
        self.client.credentials()
        
        # Try to request a book without authentication
        response = self.client.post(
            reverse('request_book'),
            {'book_id': self.book1.id},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_duplicate_request(self):
        """Test that a student cannot request the same book twice"""
        # Login using JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        
        # First request
        response = self.client.post(
            reverse('request_book'),
            {'book_id': self.book1.id},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Second request for the same book
        response = self.client.post(
            reverse('request_book'),
            {'book_id': self.book1.id},
            format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_upload_thumbnail(self):
        """Test uploading a book thumbnail"""
        # Authenticate with JWT
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        
        # Create a simple test image
        image_content = b'dummy image content'
        test_image = SimpleUploadedFile(
            name='test_image.jpg',
            content=image_content,
            content_type='image/jpeg'
        )
        
        response = self.client.post(
            reverse('upload_thumbnail'),
            {'thumbnail': test_image},
            format='multipart'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue('thumbnail_url' in response.json())

class RegistrationTestCase(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.register_url = reverse('register_user')
        
    def test_register_student(self):
        """Test registering a new student user"""
        data = {
            'username': 'newstudent',
            'password': 'securepassword123',
            'email': 'student@nlenau.ro',
            'first_name': 'New',
            'last_name': 'Student',
            'department': 'Computer Science',
            'is_teacher': False
        }
        
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['message'], 'Student registered successfully')
        
        # Check that the user was created
        self.assertTrue(User.objects.filter(username='newstudent').exists())
        
        # Check that a student profile was created
        user = User.objects.get(username='newstudent')
        self.assertTrue(hasattr(user, 'student'))
        self.assertEqual(user.student.department, 'Computer Science')
    
    def test_register_teacher(self):
        """Test registering a new teacher user"""
        data = {
            'username': 'newteacher',
            'password': 'securepassword123',
            'email': 'teacher@nlenau.ro',
            'first_name': 'New',
            'last_name': 'Teacher',
            'is_teacher': True,
            'teacher_code': 'Teacher101'
        }
        
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['message'], 'Teacher registered successfully')
        
        # Check that the user was created and is staff
        user = User.objects.get(username='newteacher')
        self.assertTrue(user.is_staff)
        
        # Check that the user is in the Teachers group
        self.assertTrue(user.groups.filter(name='Teachers').exists())
    
    def test_invalid_email_domain(self):
        """Test that email must be from nlenau.ro domain"""
        data = {
            'username': 'invaliduser',
            'password': 'securepassword123',
            'email': 'student@gmail.com',  # Invalid domain
            'first_name': 'Invalid',
            'last_name': 'User',
            'is_teacher': False
        }
        
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue('email' in response.data)
    
    def test_invalid_teacher_code(self):
        """Test that teachers must provide the correct code"""
        data = {
            'username': 'badteacher',
            'password': 'securepassword123',
            'email': 'teacher@nlenau.ro',
            'first_name': 'Bad',
            'last_name': 'Teacher',
            'is_teacher': True,
            'teacher_code': 'WrongCode'  # Invalid code
        }
        
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue('teacher_code' in response.data or 'non_field_errors' in response.data)
