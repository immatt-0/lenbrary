import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from django.contrib.auth.models import User, Group
from booklibrary.models import Book, Student, BookBorrowing

def create_test_data():
    print("Creating test data...")
    
    # Create teacher account
    try:
        teacher = User.objects.create_user(
            username='teacher',
            email='teacher@nlenau.ro',
            password='Teacher123',
            first_name='Test',
            last_name='Teacher',
            is_staff=True
        )
        teacher_group, _ = Group.objects.get_or_create(name='Teachers')
        teacher.groups.add(teacher_group)
        print(f"Created teacher: {teacher.username}")
    except Exception as e:
        print(f"Error creating teacher: {e}")

    # Create librarian account
    try:
        librarian = User.objects.create_user(
            username='librarian',
            email='librarian@nlenau.ro',
            password='Librarian123',
            first_name='Test',
            last_name='Librarian',
            is_staff=True
        )
        librarian_group, _ = Group.objects.get_or_create(name='Librarians')
        librarian.groups.add(librarian_group)
        print(f"Created librarian: {librarian.username}")
    except Exception as e:
        print(f"Error creating librarian: {e}")

    # Create student account
    try:
        student_user = User.objects.create_user(
            username='student',
            email='student@nlenau.ro',
            password='Student123',
            first_name='Test',
            last_name='Student'
        )
        student = Student.objects.create(
            user=student_user,
            student_id='ST100001',
            department='Computer Science',
            phone_number='123456789'
        )
        print(f"Created student: {student_user.username}")
    except Exception as e:
        print(f"Error creating student: {e}")
    
    # Create some sample books
    books_data = [
        {
            "name": "The Great Gatsby",
            "author": "F. Scott Fitzgerald", 
            "inventory": 5,
            "stock": 5,
            "description": "Set in the Jazz Age, this novel tells the tragic story of Jay Gatsby and his obsession with Daisy Buchanan.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg",
            "category": "Fiction",
            "publication_year": 1925
        },
        {
            "name": "To Kill a Mockingbird",
            "author": "Harper Lee",
            "inventory": 3,
            "stock": 3,
            "description": "The story of racial injustice and the loss of innocence in the American South during the Great Depression.",
            "thumbnail_url": "https://upload.wikimedia.org/wikipedia/commons/4/4f/To_Kill_a_Mockingbird_%28first_edition_cover%29.jpg",
            "category": "Fiction",
            "publication_year": 1960
        },
        {
            "name": "1984",
            "author": "George Orwell",
            "inventory": 7,
            "stock": 7,
            "description": "A dystopian novel set in a totalitarian society ruled by the Party, which has total control over every action and thought of its people.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/71kxa1-0mfL._AC_UF1000,1000_QL80_.jpg",
            "category": "Fiction",
            "publication_year": 1949
        },
        {
            "name": "The Hobbit",
            "author": "J.R.R. Tolkien",
            "inventory": 4,
            "stock": 4,
            "description": "The adventure of Bilbo Baggins as he journeys to the Lonely Mountain with a group of dwarves to reclaim their treasure from the dragon Smaug.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/710+HcoP38L._AC_UF1000,1000_QL80_.jpg",
            "category": "Fantasy",
            "publication_year": 1937
        },
        {
            "name": "Pride and Prejudice",
            "author": "Jane Austen",
            "inventory": 2,
            "stock": 2,
            "description": "A romantic novel of manners that depicts the emotional development of Elizabeth Bennet.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_UF1000,1000_QL80_.jpg",
            "category": "Romance",
            "publication_year": 1813
        },
        {
            "name": "The Catcher in the Rye",
            "author": "J.D. Salinger",
            "inventory": 3,
            "stock": 3,
            "description": "The story of Holden Caulfield, a teenage boy who has been expelled from prep school and is wandering around New York City.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/91HPG31dTwL._AC_UF1000,1000_QL80_.jpg",
            "category": "Fiction",
            "publication_year": 1951
        },
        {
            "name": "Brave New World",
            "author": "Aldous Huxley",
            "inventory": 5,
            "stock": 5,
            "description": "Set in a futuristic World State, inhabited by genetically modified citizens and an intelligence-based social hierarchy.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/81zE42gT3xL._AC_UF1000,1000_QL80_.jpg",
            "category": "Science Fiction",
            "publication_year": 1932
        },
        {
            "name": "Moby-Dick",
            "author": "Herman Melville",
            "inventory": 1,
            "stock": 1,
            "description": "The voyage of the whaling ship Pequod, commanded by Captain Ahab, who seeks revenge on Moby Dick, the giant white sperm whale that bit off his leg.",
            "thumbnail_url": "https://m.media-amazon.com/images/I/41-KqB1-cAL._AC_UF1000,1000_QL80_.jpg",
            "category": "Adventure",
            "publication_year": 1851
        }
    ]
    
    # Create the books
    books_created = 0
    for book_data in books_data:
        # Check if book already exists
        existing_book = Book.objects.filter(name=book_data["name"], author=book_data["author"]).first()
        if not existing_book:
            Book.objects.create(**book_data)
            books_created += 1
            print(f"Created book: {book_data['name']}")
        else:
            print(f"Book already exists: {book_data['name']}")
    
    print(f"Created {books_created} new books. Total books: {Book.objects.count()}")
    
    # Create test book with 10 copies, all available
    Book.objects.create(
        name="Test Book",
        author="Test Author",
        inventory=10,
        stock=10,
        description="This is a test book with 10 copies, all available for borrowing.",
        category="Test",
        publication_year=2023
    )

    print("Test book created with 10 copies, all available")
    
    # Verify user accounts
    librarian = User.objects.filter(username='librarian').first()
    student = User.objects.filter(username='student').first()
    teacher = User.objects.filter(username='teacher').first()
    
    print("\nUser accounts:")
    print(f"Librarian: {'✓ Available' if librarian else '✗ Missing'}")
    print(f"Student: {'✓ Available' if student else '✗ Missing'}")
    print(f"Teacher: {'✓ Available' if teacher else '✗ Missing'}")
    
    # Check if student has profile
    if student and hasattr(student, 'student'):
        print(f"Student profile: ✓ Available (ID: {student.student.student_id})")
    elif student:
        print("Student profile: ✗ Missing")
        
    print("\nDatabase is ready for testing!")

if __name__ == '__main__':
    create_test_data() 