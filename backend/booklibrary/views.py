import os
import uuid
import re
from datetime import timedelta
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.contrib.auth.models import User, Group
from django.db import models
from django.core.mail import send_mail
from django.urls import reverse
from django.http import HttpResponse
import logging

from rest_framework.decorators import api_view, parser_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate

from .models import Book, Student, BookBorrowing, Message, Notification, ExamModel, EmailVerification, InvitationCode
from .serializers import (
    BookSerializer, StudentSerializer, BookBorrowingSerializer,
    RegistrationSerializer, UserSerializer, ExamModelSerializer, EmailVerificationSerializer, InvitationCodeSerializer
)
from .utils import get_display_name

# Email validation pattern for @nlenau.ro domain
EMAIL_PATTERN = r'^[a-zA-Z0-9_.+-]+@nlenau\.ro$'

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """Register a new user with validation for student/teacher"""
    serializer = RegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        
        # Automatically create EmailVerification and send email
        if hasattr(user, 'email_verification'):
            ev = user.email_verification
        else:
            ev = EmailVerification.objects.create(user=user)
        
        domain = request.get_host()
        verify_path = reverse('verify_email')
        verify_url = f"http://{domain}{verify_path}?token={ev.token}"
        send_mail(
            'Verify your email',
            f'Click the link to verify your email: {verify_url}',
            'noreply@lenbrary.com',
            [user.email],
            fail_silently=False,
        )
        # Log the verification email
        email_logger = logging.getLogger('email_verification_logger')
        email_logger.info(f"To: {user.email} | Subject: Verify your email | Link: {verify_url}")
        
        # Generate response based on whether user is teacher or student
        is_teacher = request.data.get('is_teacher', False)
        
        # Include student class in response if provided for students
        student_info = {}
        if not is_teacher and hasattr(user, 'student'):
            student = user.student
            student_info = {
                'student_id': student.student_id,
                'department': student.department,
                'student_class': student.student_class
            }
        
        return Response(
            {
                'success': True,
                'message': f"{'Teacher' if is_teacher else 'Student'} registered successfully",
                'user': UserSerializer(user).data,
                **student_info
            },
            status=status.HTTP_201_CREATED
        )
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def books(request):
    """Get all books or search books"""
    query = request.GET.get('search', '')
    if query:
        books = Book.objects.filter(name__icontains=query) | Book.objects.filter(author__icontains=query)
    else:
        books = Book.objects.all()
    serializer = BookSerializer(books, many=True)
    return Response(serializer.data)

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def book(request):
    if request.method == 'GET':
        book_id = request.GET.get('id')
        if not book_id:
            return Response({'error': 'Missing ?id='}, status=status.HTTP_400_BAD_REQUEST)
        book = get_object_or_404(Book, id=book_id)
        serializer = BookSerializer(book)
        return Response(serializer.data)

    elif request.method == 'POST':
        # Check if user is librarian
        if not request.user.groups.filter(name='Librarians').exists():
            return Response({'error': 'Only librarians can add books'}, status=status.HTTP_403_FORBIDDEN)
            
        serializer = BookSerializer(data=request.data)
        if serializer.is_valid():
            new_book = serializer.save()
            
            # Create notification for librarians
            create_librarian_notification(
                notification_type='book_added',
                message=f"Cartea '{new_book.name}' de {new_book.author} a fost adăugată",
                book=new_book,
                created_by=request.user
            )
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser])
def upload_thumbnail(request):
    file = request.FILES.get('thumbnail')
    if not file:
        return Response({'error': 'No file uploaded'}, status=status.HTTP_400_BAD_REQUEST)

    filename = f"{uuid.uuid4().hex}_{file.name}"
    path = os.path.join('thumbnails', filename)
    saved_path = default_storage.save(path, ContentFile(file.read()))
    url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)
    return Response({'thumbnail_url': url}, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([JSONParser])
def request_book(request):
    """Request to borrow a book"""
    book_id = request.data.get('book_id')
    loan_duration = request.data.get('loan_duration_days', 14)  # Default to 14 days if not provided
    
    if not book_id:
        return Response({'error': 'book_id is required'}, status=status.HTTP_400_BAD_REQUEST)

    book = get_object_or_404(Book, id=book_id)

    # Check if user is a student
    is_student = hasattr(request.user, 'student')
    is_teacher = request.user.groups.filter(name='Teachers').exists()
    
    if not (is_student or is_teacher):
        return Response({'error': 'Doar studenții și profesorii pot solicita cărți'}, status=status.HTTP_403_FORBIDDEN)
    
    # For teachers, we'll create a temporary student object just for the borrowing
    if is_teacher and not is_student:
        # Check if this teacher already has a student record
        student, created = Student.objects.get_or_create(
            user=request.user,
            defaults={
                'student_id': f"T{request.user.id}",  # Teacher ID format
                'school_type': None,
                'department': None,
                'student_class': None
            }
        )
    else:
        student = request.user.student
    
    # Check if user already has a pending or active request for this book
    existing_request = BookBorrowing.objects.filter(
        student=student,
        book=book,
        status__in=['IN_ASTEPTARE', 'APROBAT', 'GATA_RIDICARE', 'IMPRUMUTAT']
    ).first()
    
    if existing_request:
        return Response(
            {'error': f'Aveți deja o cerere activă pentru această carte (Status: {existing_request.status})'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if book.available_copies <= 0:
        return Response({'error': 'Nu există exemplare disponibile'}, status=status.HTTP_400_BAD_REQUEST)

    borrowing = BookBorrowing.objects.create(
        book=book,
        student=student,
        status='IN_ASTEPTARE',
        loan_duration_days=loan_duration
    )
    
    # Create notification for librarians
    create_librarian_notification(
        notification_type='book_requested',
        message=f"{request.user.get_full_name() or request.user.username} a solicitat '{book.name}'",
        book=book,
        borrowing=borrowing,
        created_by=request.user
    )
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data, status=status.HTTP_201_CREATED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_books(request):
    """Get current user's borrowed books"""
    is_student = hasattr(request.user, 'student')
    is_teacher = request.user.groups.filter(name='Teachers').exists()
    
    if not (is_student or is_teacher):
        return Response({'error': 'Only students and teachers can view their books'}, status=status.HTTP_403_FORBIDDEN)
    
    if is_teacher and not is_student:
        # Get the teacher's student record if it exists
        try:
            student = Student.objects.get(user=request.user)
        except Student.DoesNotExist:
            # No borrowings yet
            return Response([])
    else:
        student = request.user.student

    borrowings = BookBorrowing.objects.filter(
        student=student
    ).order_by('-request_date')
    
    serializer = BookBorrowingSerializer(borrowings, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([JSONParser])
def return_book(request, borrowing_id):
    """Return a borrowed book"""
    try:
        student = request.user.student
    except Student.DoesNotExist:
        return Response({'error': 'User is not a student'}, status=status.HTTP_403_FORBIDDEN)

    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id, student=student)
    
    if borrowing.status != 'IMPRUMUTAT':
        return Response(
            {'error': f'Cannot return book with status: {borrowing.status}'},
            status=status.HTTP_400_BAD_REQUEST
        )

    borrowing.return_date = timezone.now()
    borrowing.status = 'RETURNAT'
    borrowing.fine_amount = borrowing.calculate_fine()
    borrowing.save()

    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_info(request):
    """Get current user information including role"""
    user = request.user
    
    # Check if user is in librarian group
    is_librarian = user.groups.filter(name='Librarians').exists()
    
    data = {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'name': get_display_name(user),
        'is_librarian': is_librarian,
    }
    
    # Add student info if user is a student
    try:
        if hasattr(user, 'student'):
            student = user.student
            data.update({
                'student_id': student.student_id,
                'department': student.department,
                'student_class': student.student_class,
                'school_type': student.school_type,
            })
    except:
        pass
        
    return Response(data)

# Librarian views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_requests(request):
    """Get all pending book requests - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    # Get all pending requests
    pending = BookBorrowing.objects.filter(status='IN_ASTEPTARE').order_by('-request_date')
    serializer = BookBorrowingSerializer(pending, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def active_loans(request):
    """Get all active book loans - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    # Get all active loans (borrowed books)
    active = BookBorrowing.objects.filter(status='IMPRUMUTAT').order_by('-borrow_date')
    serializer = BookBorrowingSerializer(active, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def loan_history(request):
    """Get history of completed loans - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    # Get loan history (returned books and rejected requests)
    history = BookBorrowing.objects.filter(
        status__in=['RETURNAT', 'RESPINS']
    ).order_by('-return_date', '-approved_date')
    
    serializer = BookBorrowingSerializer(history, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def approve_request(request, borrowing_id):
    """Approve a book request - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    if borrowing.status != 'IN_ASTEPTARE':
        return Response({'error': f'Cannot approve request with status: {borrowing.status}'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    
    # Update book stock
    book = borrowing.book
    if book.stock <= 0:
        return Response({'error': 'No copies available'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Book is now reserved but not yet picked up
    # We'll deduct from stock when user picks up the book
    
    # Update borrowing record
    now = timezone.now()
    borrowing.status = 'APROBAT'
    borrowing.approved_date = now
    borrowing.save()
    
    # Add librarian message if provided
    librarian_message = request.data.get('librarian_message')
    if librarian_message:
        Message.objects.create(
            sender=request.user,
            recipient=borrowing.student.user,
            borrowing=borrowing,
            content=librarian_message
        )
    
    # Create notification for the student/teacher
    create_user_notification(
        user=borrowing.student.user,
        notification_type='request_approved',
        message=f"Cererea ta pentru '{book.name}' a fost aprobată",
        book=book,
        borrowing=borrowing
    )
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reject_request(request, borrowing_id):
    """Reject a book request - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    if borrowing.status != 'IN_ASTEPTARE':
        return Response({'error': f'Cannot reject request with status: {borrowing.status}'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    
    # Update borrowing record
    borrowing.status = 'RESPINS'
    borrowing.approved_date = timezone.now()
    borrowing.save()
    
    # Add librarian message if provided
    librarian_message = request.data.get('librarian_message')
    if librarian_message:
        Message.objects.create(
            sender=request.user,
            recipient=borrowing.student.user,
            borrowing=borrowing,
            content=librarian_message
        )
    
    # Create notification for the student/teacher
    create_user_notification(
        user=borrowing.student.user,
        notification_type='request_rejected',
        message=f"Cererea ta pentru '{borrowing.book.name}' a fost respinsă",
        book=borrowing.book,
        borrowing=borrowing
    )
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([AllowAny])
@parser_classes([JSONParser])
def email_token_obtain(request):
    """Custom token authentication using email or username (part before @nlenau.ro)"""
    email_or_username = request.data.get('email')
    password = request.data.get('password')
    
    if not email_or_username or not password:
        return Response(
            {'detail': 'Email/username și parola sunt obligatorii.'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Determine if input is email or username
    is_email = '@' in email_or_username
    
    # If username is provided (without domain), convert to email format
    if not is_email:
        email = f"{email_or_username}@nlenau.ro"
    else:
        email = email_or_username
    
    # Try to find user by email first (case-insensitive)
    try:
        user = User.objects.get(email__iexact=email)
    except User.DoesNotExist:
        # If not found by email but email was provided, try to extract username from email
        if is_email and email.lower().endswith('@nlenau.ro'):
            # Extract username part (everything before @)
            username_part = email.split('@')[0]
            
            # Try to find user with that exact username (case-insensitive)
            try:
                user = User.objects.get(username__iexact=username_part)
            except User.DoesNotExist:
                # Try to find by original input as username (case-insensitive)
                try:
                    user = User.objects.get(username__iexact=email_or_username)
                except User.DoesNotExist:
                    return Response(
                        {'detail': 'Nu a fost găsit niciun cont activ cu datele furnizate.'},
                        status=status.HTTP_401_UNAUTHORIZED
                    )
        else:
            # Try direct username lookup (case-insensitive)
            try:
                user = User.objects.get(username__iexact=email_or_username)
            except User.DoesNotExist:
                return Response(
                    {'detail': 'Nu a fost găsit niciun cont activ cu datele furnizate.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
    
    # Authenticate with username and password
    user_auth = authenticate(username=user.username, password=password)
    
    if user_auth is None:
        # If the user exists but the password is wrong, show specific message
        if user is not None:
            return Response(
                {'detail': 'Parola este incorecta'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        else:
            return Response(
                {'detail': 'Nu a fost găsit niciun cont activ cu datele furnizate.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
    user = user_auth

    # Check if email is verified
    try:
        ev = user.email_verification
        if not ev.is_verified:
            # Check if the verification has expired
            if ev.is_expired():
                # Delete the expired unverified account
                user.delete()
                return Response(
                    {'detail': 'Linkul de verificare a expirat (6 ore). Contul a fost șters automat. Poți să te înregistrezi din nou.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            return Response(
                {'detail': 'Contul nu a fost verificat. Vă rugăm să verificați e-mailul pentru a activa contul.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
    except EmailVerification.DoesNotExist:
        return Response(
            {'detail': 'Contul nu a fost verificat. Vă rugăm să verificați e-mailul pentru a activa contul.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Create tokens
    refresh = RefreshToken.for_user(user)
    
    return Response({
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_pickup(request, borrowing_id):
    """Mark book as picked up - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    if borrowing.status != 'APROBAT' and borrowing.status != 'GATA_RIDICARE':
        return Response({'error': f'Cannot mark pickup for request with status: {borrowing.status}'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    
    # Update book stock
    book = borrowing.book
    if book.stock <= 0:
        return Response({'error': 'No copies available'}, status=status.HTTP_400_BAD_REQUEST)
    
    book.stock -= 1
    book.save()
    
    # Update borrowing record
    now = timezone.now()
    borrowing.status = 'IMPRUMUTAT'
    borrowing.pickup_date = now
    borrowing.borrow_date = now
    borrowing.due_date = now + timedelta(days=borrowing.loan_duration_days)
    borrowing.save()
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def librarian_return_book(request, borrowing_id):
    """Return a book - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    if borrowing.status != 'IMPRUMUTAT' and borrowing.status != 'INTARZIAT':
        return Response({'error': f'Cannot return book with status: {borrowing.status}'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    
    # Update book stock
    book = borrowing.book
    book.stock += 1
    book.save()
    
    # Update borrowing record
    borrowing.return_date = timezone.now()
    borrowing.status = 'RETURNAT'
    borrowing.fine_amount = borrowing.calculate_fine()
    borrowing.save()
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_book_stock(request, book_id):
    """Update book inventory and stock - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    book = get_object_or_404(Book, id=book_id)
    
    # Get the new stock value
    new_stock = request.data.get('stock')
    new_inventory = request.data.get('inventory')
    
    old_stock = book.stock
    old_inventory = book.inventory
    
    if new_stock is not None:
        try:
            new_stock = int(new_stock)
            if new_stock < 0:
                return Response({'error': 'Stock cannot be negative'}, status=status.HTTP_400_BAD_REQUEST)
            book.stock = new_stock
        except ValueError:
            return Response({'error': 'Stock must be a number'}, status=status.HTTP_400_BAD_REQUEST)
    
    if new_inventory is not None:
        try:
            new_inventory = int(new_inventory)
            if new_inventory < 0:
                return Response({'error': 'Inventory cannot be negative'}, status=status.HTTP_400_BAD_REQUEST)
            book.inventory = new_inventory
        except ValueError:
            return Response({'error': 'Inventory must be a number'}, status=status.HTTP_400_BAD_REQUEST)
    
    book.save()
    
    # Create notification if stock or inventory changed
    if old_stock != book.stock or old_inventory != book.inventory:
        changes = []
        if old_stock != book.stock:
            changes.append(f"stoc: {old_stock} → {book.stock}")
        if old_inventory != book.inventory:
            changes.append(f"inventar: {old_inventory} → {book.inventory}")
            
        create_librarian_notification(
            notification_type='stock_updated',
            message=f"Cartea '{book.name}' a fost actualizată ({', '.join(changes)})",
            book=book,
            created_by=request.user
        )
    
    serializer = BookSerializer(book)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def all_book_requests(request):
    """Get all book requests regardless of status - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    # Get all requests
    all_requests = BookBorrowing.objects.all().order_by('-request_date')
    serializer = BookBorrowingSerializer(all_requests, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([JSONParser])
def request_loan_extension(request, borrowing_id):
    """Request extension for a borrowed book"""
    is_student = hasattr(request.user, 'student')
    is_teacher = request.user.groups.filter(name='Teachers').exists()
    
    if not (is_student or is_teacher):
        return Response({'error': 'Only students and teachers can request loan extensions'}, status=status.HTTP_403_FORBIDDEN)
    
    if is_teacher and not is_student:
        # Get the teacher's student record if it exists
        try:
            student = Student.objects.get(user=request.user)
        except Student.DoesNotExist:
            return Response({'error': 'No borrowing record found'}, status=status.HTTP_404_NOT_FOUND)
    else:
        student = request.user.student

    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id, student=student)
    
    if borrowing.status != 'IMPRUMUTAT':
        return Response(
            {'error': f'Cannot request extension for book with status: {borrowing.status}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get the requested new duration
    requested_days = request.data.get('requested_days')
    message = request.data.get('message', '')
    
    if not requested_days:
        return Response({'error': 'requested_days is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Update borrowing with student message
    borrowing.student_message = f"Cerere extindere: {requested_days} zile. Mesaj: {message}"
    borrowing.save()
    
    # Create a message for the librarians
    librarians = User.objects.filter(groups__name='Librarians')
    for librarian in librarians:
        Message.objects.create(
            sender=request.user,
            recipient=librarian,
            borrowing=borrowing,
            content=f"Cerere extindere împrumut: {requested_days} zile. Mesaj: {message}"
        )
    
    # Create notification for librarians
    create_librarian_notification(
        notification_type='extension_requested',
        message=f"{get_display_name(request.user)} a solicitat extinderea împrumutului pentru '{borrowing.book.name}' cu {requested_days} zile",
        book=borrowing.book,
        borrowing=borrowing,
        created_by=request.user
    )
    
    return Response({'success': True, 'message': 'Extension request sent successfully'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([JSONParser])
def send_message(request):
    """Send a message to another user"""
    recipient_id = request.data.get('recipient_id')
    borrowing_id = request.data.get('borrowing_id')
    content = request.data.get('content')
    
    if not recipient_id or not content:
        return Response({'error': 'recipient_id and content are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    recipient = get_object_or_404(User, id=recipient_id)
    
    borrowing = None
    if borrowing_id:
        borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    message = Message.objects.create(
        sender=request.user,
        recipient=recipient,
        borrowing=borrowing,
        content=content
    )
    
    return Response({
        'id': message.id,
        'sent': message.timestamp.isoformat(),
        'content': message.content
    }, status=status.HTTP_201_CREATED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_messages(request):
    """Get all messages for the current user, grouped by conversation"""
    user = request.user
    conversation_id = request.query_params.get('conversation_id')
    
    if conversation_id:
        # Get messages for a specific conversation
        messages = Message.objects.filter(
            models.Q(sender=user) | models.Q(recipient=user),
            conversation_id=conversation_id
        ).order_by('timestamp')
    else:
        # Get all conversations for the user
        # First get all unique conversation IDs
        conversations = Message.objects.filter(
            models.Q(sender=user) | models.Q(recipient=user)
        ).values('conversation_id').distinct()
        
        # For each conversation, get the latest message
        conversations_data = []
        for conv in conversations:
            conv_id = conv['conversation_id']
            latest_message = Message.objects.filter(
                models.Q(sender=user) | models.Q(recipient=user),
                conversation_id=conv_id
            ).order_by('-timestamp').first()
            
            if latest_message:
                other_user = latest_message.sender if latest_message.recipient == user else latest_message.recipient
                conversations_data.append({
                    'conversation_id': conv_id,
                    'other_user': {
                        'id': other_user.id,
                        'username': other_user.username,
                        'name': get_display_name(other_user),
                    },
                    'last_message': {
                        'id': latest_message.id,
                        'content': latest_message.content,
                        'timestamp': latest_message.timestamp.isoformat(),
                        'is_read': latest_message.is_read,
                        'is_sent_by_me': latest_message.sender == user,
                    },
                    'unread_count': Message.objects.filter(
                        models.Q(recipient=user, is_read=False),
                        conversation_id=conv_id
                    ).count(),
                })
        
        return Response(conversations_data)
    
    # For a specific conversation, return all messages
    data = []
    for msg in messages:
        data.append({
            'id': msg.id,
            'sender': {
                'id': msg.sender.id,
                'username': msg.sender.username,
                'name': get_display_name(msg.sender),
            },
            'content': msg.content,
            'timestamp': msg.timestamp.isoformat(),
            'is_read': msg.is_read,
            'is_sent_by_me': msg.sender == user,
        })
    
    return Response(data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_message_read(request, message_id):
    """Mark a message as read"""
    message = get_object_or_404(Message, id=message_id, recipient=request.user)
    message.is_read = True
    message.save()
    
    return Response({'success': True})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_all_users(request):
    """Get all users for messaging purposes - librarians can see all users, regular users can only see librarians"""
    current_user = request.user
    is_librarian = current_user.groups.filter(name='Librarians').exists()
    
    if is_librarian:
        # Librarians can see all users
        users = User.objects.exclude(id=current_user.id)
    else:
        # Regular users can only see librarians
        users = User.objects.filter(groups__name='Librarians')
    
    # Basic serialization with email username extraction
    data = []
    for user in users:
        # Extract username from email for display
        display_name = user.username
        if '@' in user.email:
            display_name = user.email.split('@')[0]
            
        data.append({
            'id': user.id,
            'username': user.username,
            'display_name': display_name,
            'full_name': get_display_name(user),
            'is_librarian': user.groups.filter(name='Librarians').exists(),
        })
    
    return Response(data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_notifications(request):
    """Get notifications for the current user"""
    user = request.user
    is_librarian = user.groups.filter(name='Librarians').exists()
    
    if is_librarian:
        # Librarians see notifications meant for librarians
        notifications = Notification.objects.filter(for_librarians=True)
    else:
        # Regular users see their own notifications
        notifications = Notification.objects.filter(user=user, for_librarians=False)
    
    # Limit to latest 50 notifications
    notifications = notifications.order_by('-timestamp')[:50]
    
    # Basic serialization
    data = []
    for notification in notifications:
        notification_data = {
            'id': notification.id,
            'type': notification.notification_type,
            'message': notification.message,
            'timestamp': notification.timestamp.isoformat(),
            'is_read': notification.is_read,
        }
        
        # Add book info if available
        if notification.book:
            notification_data['book'] = {
                'id': notification.book.id,
                'name': notification.book.name,
            }
            
        # Add borrowing info if available
        if notification.borrowing:
            notification_data['borrowing'] = {
                'id': notification.borrowing.id,
            }
            
        # Add creator info if available (for librarian notifications)
        if notification.created_by:
            notification_data['created_by'] = {
                'id': notification.created_by.id,
                'name': get_display_name(notification.created_by),
            }
            
        data.append(notification_data)
    
    return Response(data)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    """Mark a notification as read"""
    user = request.user
    is_librarian = user.groups.filter(name='Librarians').exists()
    
    if is_librarian:
        # Librarians can mark librarian notifications as read
        notification = get_object_or_404(Notification, id=notification_id, for_librarians=True)
    else:
        # Regular users can only mark their own notifications as read
        notification = get_object_or_404(Notification, id=notification_id, user=user, for_librarians=False)
    
    notification.is_read = True
    notification.save()
    
    return Response({'success': True})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def approve_extension(request, borrowing_id):
    """Approve a loan extension request - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    if borrowing.status != 'IMPRUMUTAT':
        return Response({'error': f'Cannot approve extension for book with status: {borrowing.status}'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    
    if not borrowing.student_message:
        return Response({'error': 'No extension request found'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Get the requested extension days from the request data
    requested_days = request.data.get('requested_days')
    if not requested_days:
        return Response({'error': 'requested_days is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Calculate new due date
    if borrowing.due_date:
        # Extend from current due date
        borrowing.due_date = borrowing.due_date + timezone.timedelta(days=int(requested_days))
    else:
        # Fallback: extend from current date if due date is missing
        borrowing.due_date = timezone.now() + timezone.timedelta(days=int(requested_days))
    
    # Store the original message for notification
    original_message = borrowing.student_message
    
    # Clear the student message since the request is handled
    borrowing.student_message = ''
    borrowing.save()
    
    # Add librarian message if provided
    librarian_message = request.data.get('librarian_message')
    if librarian_message:
        Message.objects.create(
            sender=request.user,
            recipient=borrowing.student.user,
            borrowing=borrowing,
            content=librarian_message
        )
    
    # Create notification for the student/teacher
    create_user_notification(
        user=borrowing.student.user,
        notification_type='extension_approved',
        message=f"Cererea ta de prelungire pentru '{borrowing.book.name}' a fost aprobată",
        book=borrowing.book,
        borrowing=borrowing
    )
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def decline_extension(request, borrowing_id):
    """Decline a loan extension request - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id)
    
    if borrowing.status != 'IMPRUMUTAT':
        return Response({'error': f'Cannot decline extension for book with status: {borrowing.status}'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    
    if not borrowing.student_message:
        return Response({'error': 'No extension request found'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Store the original message for notification
    original_message = borrowing.student_message
    
    # Clear the student message since the request is handled
    borrowing.student_message = ''
    borrowing.save()
    
    # Add librarian message if provided
    librarian_message = request.data.get('librarian_message')
    if librarian_message:
        Message.objects.create(
            sender=request.user,
            recipient=borrowing.student.user,
            borrowing=borrowing,
            content=librarian_message
        )
    
    # Create notification for the student/teacher
    create_user_notification(
        user=borrowing.student.user,
        notification_type='extension_declined',
        message=f"Cererea ta de prelungire pentru '{borrowing.book.name}' a fost respinsă",
        book=borrowing.book,
        borrowing=borrowing
    )
    
    serializer = BookBorrowingSerializer(borrowing)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_users(request):
    """Search users - for librarians only"""
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    query = request.query_params.get('q', '').strip()
    if not query:
        return Response([])
    
    # Search in username, email, first_name, and last_name
    users = User.objects.filter(
        models.Q(username__icontains=query) |
        models.Q(email__icontains=query) |
        models.Q(first_name__icontains=query) |
        models.Q(last_name__icontains=query)
    ).exclude(id=request.user.id)
    
    data = []
    for user in users:
        data.append({
            'id': user.id,
            'username': user.username,
            'display_name': get_display_name(user),
            'email': user.email,
            'is_librarian': user.groups.filter(name='Librarians').exists(),
        })
    
    return Response(data)

# Add notification helpers
def create_librarian_notification(notification_type, message, book=None, borrowing=None, created_by=None):
    """Create notification for librarians"""
    Notification.objects.create(
        notification_type=notification_type,
        message=message,
        book=book,
        borrowing=borrowing,
        created_by=created_by,
        for_librarians=True
    )

def create_user_notification(user, notification_type, message, book=None, borrowing=None):
    """Create notification for a specific user"""
    Notification.objects.create(
        user=user,
        notification_type=notification_type,
        message=message,
        book=book,
        borrowing=borrowing,
        for_librarians=False
    )

@api_view(['GET'])
@permission_classes([AllowAny])
def list_exam_models(request):
    """List all exam models"""
    exam_models = ExamModel.objects.all().order_by('-created_at')
    serializer = ExamModelSerializer(exam_models, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def create_exam_model(request):
    """Create a new exam model (admin only)"""
    serializer = ExamModelSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_exam_model(request, pk):
    """Delete an exam model (admin only)"""
    try:
        exam_model = ExamModel.objects.get(pk=pk)
    except ExamModel.DoesNotExist:
        return Response({'error': 'Exam model not found'}, status=status.HTTP_404_NOT_FOUND)
    exam_model.delete()
    return Response({'success': True})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_verification_email(request):
    user = request.user
    if hasattr(user, 'email_verification'):
        ev = user.email_verification
        if ev.is_verified:
            return Response({'detail': 'Email already verified.'}, status=status.HTTP_400_BAD_REQUEST)
        ev.generate_token()
    else:
        ev = EmailVerification.objects.create(user=user)
        ev.generate_token()
    # Build verification link
    domain = request.get_host()
    verify_path = reverse('verify_email')
    verify_url = f"http://{domain}{verify_path}?token={ev.token}"
    # Send email
    send_mail(
        'Verify your email',
        f'Click the link to verify your email: {verify_url}',
        'noreply@lenbrary.com',
        [user.email],
        fail_silently=False,
    )
    # Log the verification email
    email_logger = logging.getLogger('email_verification_logger')
    email_logger.info(f"To: {user.email} | Subject: Verify your email | Link: {verify_url}")
    return Response({'detail': 'Verification email sent.'})

@api_view(['GET'])
@permission_classes([AllowAny])
def verify_email(request):
    token = request.GET.get('token')
    if not token:
        return HttpResponse('Token is required.', status=400, content_type='text/plain')
    try:
        ev = EmailVerification.objects.get(token=token)
    except EmailVerification.DoesNotExist:
        return HttpResponse('Invalid token.', status=400, content_type='text/plain')
    
    # Check if token has expired
    if ev.is_expired():
        html = '''
        <html><head><meta charset="UTF-8"><title>Token Expired</title></head>
        <body style="margin:0;padding:0;min-height:100vh;background:linear-gradient(135deg,#ffffff 0%,#e3f0ff 100%);display:flex;align-items:center;justify-content:center;">
        <div style="background:#ffe6e6;color:#dc3545;padding:32px 40px;border-radius:16px;box-shadow:0 2px 16px #0001;font-size:1.3rem;font-family:sans-serif;max-width:90vw;text-align:center;">
        Linkul de verificare a expirat (6 ore).<br>Contul tău a fost șters automat.<br>Poți să te înregistrezi din nou.
        </div></body></html>
        '''
        return HttpResponse(html, content_type='text/html')
    
    if ev.is_verified:
        html = '''
        <html><head><meta charset="UTF-8"><title>Email Already Verified</title></head>
        <body style="margin:0;padding:0;min-height:100vh;background:linear-gradient(135deg,#ffffff 0%,#e3f0ff 100%);display:flex;align-items:center;justify-content:center;">
        <div style="background:#e6ffe6;color:#218838;padding:32px 40px;border-radius:16px;box-shadow:0 2px 16px #0001;font-size:1.3rem;font-family:sans-serif;max-width:90vw;text-align:center;">
        Emailul a fost deja verificat.<br>Poți închide această pagină.
        </div></body></html>
        '''
        return HttpResponse(html, content_type='text/html')
    ev.is_verified = True
    ev.save()
    html = '''
    <html><head><meta charset="UTF-8"><title>Email Verified</title></head>
    <body style="margin:0;padding:0;min-height:100vh;background:linear-gradient(135deg,#ffffff 0%,#e3f0ff 100%);display:flex;align-items:center;justify-content:center;">
    <div style="background:#e6ffe6;color:#218838;padding:32px 40px;border-radius:16px;box-shadow:0 2px 16px #0001;font-size:1.3rem;font-family:sans-serif;max-width:90vw;text-align:center;">
    Emailul a fost verificat cu succes!<br>Poți închide această pagină.
    </div></body></html>
    '''
    return HttpResponse(html, content_type='text/html')

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_invitation_code(request):
    """Create a new invitation code for teacher registration - Admin/Librarian only"""
    # Check if user is admin or librarian
    if not (request.user.is_superuser or request.user.groups.filter(name='Librarians').exists()):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    # Create invitation code with 6-hour expiration
    invitation = InvitationCode.objects.create(
        created_by=request.user,
        expires_at=timezone.now() + timedelta(hours=6)
    )
    invitation.generate_code()
    
    serializer = InvitationCodeSerializer(invitation)
    return Response(serializer.data, status=status.HTTP_201_CREATED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_invitation_codes(request):
    """List all invitation codes - Admin/Librarian only"""
    # Check if user is admin or librarian
    if not (request.user.is_superuser or request.user.groups.filter(name='Librarians').exists()):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    invitations = InvitationCode.objects.all().order_by('-created_at')
    serializer = InvitationCodeSerializer(invitations, many=True)
    return Response(serializer.data)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_invitation_code(request, code_id):
    """Delete an invitation code - Admin/Librarian only"""
    # Check if user is admin or librarian
    if not (request.user.is_superuser or request.user.groups.filter(name='Librarians').exists()):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        invitation = InvitationCode.objects.get(id=code_id)
        invitation.delete()
        return Response({'success': True})
    except InvitationCode.DoesNotExist:
        return Response({'error': 'Invitation code not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cleanup_expired_invitations(request):
    """Clean up expired invitation codes - Admin/Librarian only"""
    # Check if user is admin or librarian
    if not (request.user.is_superuser or request.user.groups.filter(name='Librarians').exists()):
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    expired_count = InvitationCode.objects.filter(expires_at__lt=timezone.now()).delete()[0]
    return Response({'deleted_count': expired_count})
