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
import urllib.parse

from rest_framework.decorators import api_view, parser_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model

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
        
        # Create professional HTML email (same as send_verification_email)
        html_message = f'''
        <!DOCTYPE html>
        <html lang="ro">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Verificare Email - Lenbrary</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8f9fa;">
            <div style="max-width: 600px; margin: 0 auto; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 0;">
                <!-- Header -->
                <div style="background: rgba(255,255,255,0.1); text-align: center; padding: 40px 20px;">
                    <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 700;">📚 Lenbrary</h1>
                    <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 16px;">Biblioteca Ta Digitală</p>
                </div>
                
                <!-- Content -->
                <div style="background: white; padding: 40px 30px; margin: 0;">
                    <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Bun venit în Lenbrary!</h2>
                    
                    <p style="color: #555; line-height: 1.6; margin: 0 0 20px 0; font-size: 16px;">
                        Îți mulțumim pentru înregistrare! Pentru a-ți activa contul și a accesa biblioteca noastră digitală, 
                        te rugăm să îți verifici adresa de email.
                    </p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{verify_url}" 
                           style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                                  color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; 
                                  font-weight: 600; font-size: 16px; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                            ✅ Verifică Email-ul
                        </a>
                    </div>
                    
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 25px 0;">
                        <p style="color: #666; margin: 0; font-size: 14px; line-height: 1.5;">
                            <strong>Dacă butonul nu funcționează,</strong> copiază și lipește următorul link în browser:
                        </p>
                        <p style="color: #667eea; margin: 10px 0 0 0; font-size: 14px; word-break: break-all;">
                            {verify_url}
                        </p>
                    </div>
                    
                    <div style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 30px;">
                        <p style="color: #888; font-size: 14px; margin: 0; line-height: 1.5;">
                            Acest link va expira în 6 ore din motive de securitate.<br>
                            Dacă nu te-ai înregistrat pe Lenbrary, poți ignora acest email.
                        </p>
                    </div>
                </div>
                
                <!-- Footer -->
                <div style="background: #333; color: white; text-align: center; padding: 20px;">
                    <p style="margin: 0; font-size: 14px; opacity: 0.8;">
                        © 2025 Lenbrary - Biblioteca Ta Digitală
                    </p>
                </div>
            </div>
        </body>
        </html>
        '''
        
        # Send HTML email using EmailMessage instead of send_mail
        from django.core.mail import EmailMessage
        
        email = EmailMessage(
            subject='Verifică-ți emailul - Lenbrary',
            body=html_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user.email],
        )
        email.content_subtype = "html"  # Main content is now text/html
        email.send(fail_silently=False)
        
        # Log the verification email
        email_logger = logging.getLogger('email_verification_logger')
        email_logger.info(f"To: {user.email} | Subject: Verifică-ți emailul - Lenbrary | Link: {verify_url}")
        
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
    category = request.GET.get('category', '')
    
    books = Book.objects.all()
    
    if query:
        books = books.filter(
            models.Q(name__icontains=query) | 
            models.Q(author__icontains=query)
        )
    
    if category == 'carti':
        # Show all books with type 'carte'
        books = books.filter(type='carte')
    elif category == 'manuale':
        # Show only books with type 'manual'
        books = books.filter(type='manual')
    
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
            
        # Ensure UTF-8 encoding for text fields
        data = request.data.copy()
        for field in ['name', 'author', 'category', 'description']:
            if field in data and data[field]:
                pass  # No need to re-encode; Django handles Unicode natively

        # Defensive fix: strip full URL and /media/ from media fields
        for media_field in ['pdf_file', 'thumbnail_url']:
            if media_field in data and data[media_field]:
                value = data[media_field]
                logging.warning(f"RAW {media_field}: {value}")
                value = urllib.parse.unquote(value)
                logging.warning(f"DECODED {media_field}: {value}")
                # If it's a full URL, extract only the part after /media/
                if '/media/' in value:
                    data[media_field] = value.split('/media/', 1)[-1]
                    logging.warning(f"EXTRACTED {media_field}: {data[media_field]}")
                # If it starts with http or https, try to extract the path
                elif value.startswith('http://') or value.startswith('https://'):
                    idx = value.find('/media/')
                    if idx != -1:
                        data[media_field] = value[idx + 7:]
                        logging.warning(f"EXTRACTED2 {media_field}: {data[media_field]}")

        serializer = BookSerializer(data=data)
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

    # Validate file type
    allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
    file_extension = os.path.splitext(file.name.lower())[1]
    
    if file_extension not in allowed_extensions:
        return Response({
            'error': f'Invalid file type. Allowed types: {", ".join(allowed_extensions)}'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate file size (limit to 5MB)
    if file.size > 5 * 1024 * 1024:  # 5MB in bytes
        return Response({
            'error': 'File size must be less than 5MB'
        }, status=status.HTTP_400_BAD_REQUEST)

    filename = f"{uuid.uuid4().hex}_{file.name}"
    path = os.path.join('thumbnails', filename)
    saved_path = default_storage.save(path, ContentFile(file.read()))
    url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)
    return Response({'thumbnail_url': url}, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser])
def upload_pdf(request):
    """Upload PDF file for books/manuals"""
    file = request.FILES.get('pdf')
    if not file:
        return Response({'error': 'No file uploaded'}, status=status.HTTP_400_BAD_REQUEST)

    # Validate file type - only PDF
    if not file.name.lower().endswith('.pdf'):
        return Response({
            'error': 'Only PDF files are allowed'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate file size (limit to 100MB for PDFs)
    if file.size > 100 * 1024 * 1024:  # 100MB in bytes
        return Response({
            'error': 'File size must be less than 100MB'
        }, status=status.HTTP_400_BAD_REQUEST)

    filename = f"{uuid.uuid4().hex}_{file.name}"
    path = os.path.join('books', filename)
    saved_path = default_storage.save(path, ContentFile(file.read()))
    url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)
    return Response({'pdf_url': url}, status=status.HTTP_201_CREATED)

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
    
    # Set estimated due date (will be updated to actual due date when picked up)
    borrowing.due_date = timezone.now() + timedelta(days=loan_duration)
    borrowing.save()
    
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
    except Student.DoesNotExist:
        # User does not have a student profile
        pass
    except Exception as e:
        logging.getLogger('user_info').exception(f"Unexpected error in user_info: {e}")
    
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
        
    # Get loan history (returned books, rejected requests, and canceled requests)
    history = BookBorrowing.objects.filter(
        status__in=['RETURNAT', 'RESPINS', 'ANULATA']
    ).extra(
        select={
            'sort_date': '''
                CASE 
                    WHEN return_date IS NOT NULL THEN return_date
                    WHEN approved_date IS NOT NULL THEN approved_date
                    ELSE request_date
                END
            '''
        }
    ).order_by('-sort_date')
    
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
    """Update book stock and inventory - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    book = get_object_or_404(Book, id=book_id)
    
    new_stock = request.data.get('stock')
    new_inventory = request.data.get('inventory')
    
    if new_stock is None and new_inventory is None:
        return Response({'error': 'Either stock or inventory is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    old_stock = book.stock
    old_inventory = book.inventory
    
    if new_stock is not None:
        try:
            new_stock = int(new_stock)
            if new_stock < 0:
                return Response({'error': 'Stock cannot be negative'}, status=status.HTTP_400_BAD_REQUEST)
            book.stock = new_stock
        except (ValueError, TypeError):
            return Response({'error': 'Invalid stock value'}, status=status.HTTP_400_BAD_REQUEST)
    
    if new_inventory is not None:
        try:
            new_inventory = int(new_inventory)
            if new_inventory < 0:
                return Response({'error': 'Inventory cannot be negative'}, status=status.HTTP_400_BAD_REQUEST)
            book.inventory = new_inventory
        except (ValueError, TypeError):
            return Response({'error': 'Invalid inventory value'}, status=status.HTTP_400_BAD_REQUEST)
    
    book.save()
    
    # Create notification for librarians
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

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_book(request, book_id):
    """Delete a book - For librarians only"""
    # Check if user is a librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    book = get_object_or_404(Book, id=book_id)
    
    # Check if the book has any active loans
    active_loans = BookBorrowing.objects.filter(
        book=book,
        status__in=['IN_ASTEPTARE', 'APROBAT', 'GATA_RIDICARE', 'IMPRUMUTAT']
    ).count()
    
    if active_loans > 0:
        return Response({
            'error': f'Cannot delete book. There are {active_loans} active loans for this book.'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Store book info for notification before deletion
    book_name = book.name
    book_author = book.author
    
    # Delete the book
    book.delete()
    
    # Create notification for librarians
    create_librarian_notification(
        notification_type='book_deleted',
        message=f"Cartea '{book_name}' de {book_author} a fost ștearsă",
        created_by=request.user
    )
    
    return Response({'success': True, 'message': 'Book deleted successfully'})

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
    
    # Check if the loan has already been extended
    if borrowing.has_been_extended:
        return Response(
            {'error': 'This loan has already been extended once and cannot be extended again'},
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
    # Mark that this loan has been extended
    borrowing.has_been_extended = True
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
    # Debug information
    print(f"Creating exam model - User: {request.user.email}")
    print(f"Request data: {request.data}")
    print(f"Request files: {request.FILES}")
    
    if 'pdf_file' in request.FILES:
        pdf_file = request.FILES['pdf_file']
        print(f"PDF file info:")
        print(f"  Name: {pdf_file.name}")
        print(f"  Size: {pdf_file.size}")
        print(f"  Content type: {getattr(pdf_file, 'content_type', 'Not set')}")
        print(f"  Content type from request: {request.FILES['pdf_file'].content_type if hasattr(request.FILES['pdf_file'], 'content_type') else 'Not available'}")
    else:
        print("No PDF file found in request.FILES")
    
    serializer = ExamModelSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    else:
        print(f"Serializer errors: {serializer.errors}")
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
    
    # Create professional HTML email
    html_message = f'''
    <!DOCTYPE html>
    <html lang="ro">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verificare Email - Lenbrary</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8f9fa;">
        <div style="max-width: 600px; margin: 0 auto; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 0;">
            <!-- Header -->
            <div style="background: rgba(255,255,255,0.1); text-align: center; padding: 40px 20px;">
                <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 700;">📚 Lenbrary</h1>
                <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 16px;">Biblioteca Ta Digitală</p>
            </div>
            
            <!-- Content -->
            <div style="background: white; padding: 40px 30px; margin: 0;">
                <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Bun venit în Lenbrary!</h2>
                
                <p style="color: #555; line-height: 1.6; margin: 0 0 20px 0; font-size: 16px;">
                    Îți mulțumim pentru înregistrare! Pentru a-ți activa contul și a accesa biblioteca noastră digitală, 
                    te rugăm să îți verifici adresa de email.
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{verify_url}" 
                       style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                              color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; 
                              font-weight: 600; font-size: 16px; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                        ✅ Verifică Email-ul
                    </a>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 25px 0;">
                    <p style="color: #666; margin: 0; font-size: 14px; line-height: 1.5;">
                        <strong>Dacă butonul nu funcționează,</strong> copiază și lipește următorul link în browser:
                    </p>
                    <p style="color: #667eea; margin: 10px 0 0 0; font-size: 14px; word-break: break-all;">
                        {verify_url}
                    </p>
                </div>
                
                <div style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 30px;">
                    <p style="color: #888; font-size: 14px; margin: 0; line-height: 1.5;">
                        Acest link va expira în 6 ore din motive de securitate.<br>
                        Dacă nu te-ai înregistrat pe Lenbrary, poți ignora acest email.
                    </p>
                </div>
            </div>
            
            <!-- Footer -->
            <div style="background: #333; color: white; text-align: center; padding: 20px;">
                <p style="margin: 0; font-size: 14px; opacity: 0.8;">
                    © 2025 Lenbrary - Biblioteca Ta Digitală
                </p>
            </div>
        </div>
    </body>
    </html>
    '''
    
    # Send HTML email
    from django.core.mail import EmailMessage
    
    email = EmailMessage(
        subject='Verifică-ți emailul - Lenbrary',
        body=html_message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[user.email],
    )
    email.content_subtype = "html"  # Main content is now text/html
    email.send(fail_silently=False)
    
    # Log the verification email
    email_logger = logging.getLogger('email_verification_logger')
    email_logger.info(f"To: {user.email} | Subject: Verifică-ți emailul - Lenbrary | Link: {verify_url}")
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
        <!DOCTYPE html>
        <html lang="ro">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Link Expirat - Lenbrary</title>
        </head>
        <body style="margin:0;padding:0;min-height:100vh;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
            <div style="background:white;padding:40px;border-radius:16px;box-shadow:0 8px 32px rgba(0,0,0,0.1);text-align:center;max-width:90vw;max-width:500px;">
                <div style="font-size:4rem;margin-bottom:20px;">⏰</div>
                <h1 style="color:#dc3545;margin:0 0 15px 0;font-size:1.8rem;">Link Expirat</h1>
                <p style="color:#666;line-height:1.6;margin:0 0 25px 0;">
                    Linkul de verificare a expirat (6 ore).<br>
                    Contul tău a fost șters automat pentru siguranță.
                </p>
                <div style="background:#f8f9fa;padding:20px;border-radius:8px;margin:20px 0;">
                    <p style="color:#666;margin:0;font-size:14px;">
                        📚 Poți să te înregistrezi din nou pentru a accesa Lenbrary
                    </p>
            </div>
        </body>
        </html>
        '''
        return HttpResponse(html, content_type='text/html')
    
    if ev.is_verified:
        html = '''
        <!DOCTYPE html>
        <html lang="ro">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Email Deja Verificat - Lenbrary</title>
        </head>
        <body style="margin:0;padding:0;min-height:100vh;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
            <div style="background:white;padding:40px;border-radius:16px;box-shadow:0 8px 32px rgba(0,0,0,0.1);text-align:center;max-width:90vw;max-width:500px;">
                <div style="font-size:4rem;margin-bottom:20px;">✅</div>
                <h1 style="color:#28a745;margin:0 0 15px 0;font-size:1.8rem;">Email Deja Verificat</h1>
                <p style="color:#666;line-height:1.6;margin:0 0 25px 0;">
                    Emailul tău a fost deja verificat anterior.<br>
                    Contul tău Lenbrary este activ și funcțional.
                </p>
                <div style="background:#e8f5e8;padding:20px;border-radius:8px;margin:20px 0;border-left:4px solid #28a745;">
                    <p style="color:#155724;margin:0;font-size:14px;">
                        📚 Poți accesa biblioteca digitală în orice moment
                    </p>
            </div>
        </body>
        </html>
        '''
        return HttpResponse(html, content_type='text/html')
    
    ev.is_verified = True
    ev.save()
    html = '''
    <!DOCTYPE html>
    <html lang="ro">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verificat - Lenbrary</title>
    </head>
    <body style="margin:0;padding:0;min-height:100vh;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
        <div style="background:white;padding:40px;border-radius:16px;box-shadow:0 8px 32px rgba(0,0,0,0.1);text-align:center;max-width:90vw;max-width:500px;">
            <div style="font-size:4rem;margin-bottom:20px;">🎉</div>
            <h1 style="color:#28a745;margin:0 0 15px 0;font-size:1.8rem;">Email Verificat cu Succes!</h1>
            <p style="color:#666;line-height:1.6;margin:0 0 25px 0;">
                Felicitări! Contul tău Lenbrary a fost activat cu succes.<br>
                Acum poți accesa toate funcționalitățile bibliotecii digitale.
            </p>
            <div style="background:#e8f5e8;padding:20px;border-radius:8px;margin:20px 0;border-left:4px solid #28a745;">
                <h3 style="color:#155724;margin:0 0 10px 0;font-size:16px;">Ce poți face acum:</h3>
                <ul style="color:#155724;margin:0;padding-left:20px;text-align:left;font-size:14px;">
                    <li>Căuta și împrumuta cărți</li>
                    <li>Accesa manuale școlare</li>
                    <li>Gestiona cererile tale</li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    '''
    return HttpResponse(html, content_type='text/html')

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_invitation_code(request):
    """Create a new invitation code for teacher registration - Admin only"""
    # Check if user is admin (superuser only)
    if not request.user.is_superuser:
        return Response({'error': 'Only administrators can create invitation codes'}, status=status.HTTP_403_FORBIDDEN)
    
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
    """List all invitation codes - Admin only"""
    # Check if user is admin (superuser only)
    if not request.user.is_superuser:
        return Response({'error': 'Only administrators can view invitation codes'}, status=status.HTTP_403_FORBIDDEN)
    
    invitations = InvitationCode.objects.all().order_by('-created_at')
    serializer = InvitationCodeSerializer(invitations, many=True)
    return Response(serializer.data)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_invitation_code(request, code_id):
    """Delete an invitation code - Admin only"""
    # Check if user is admin (superuser only)
    if not request.user.is_superuser:
        return Response({'error': 'Only administrators can delete invitation codes'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        invitation = InvitationCode.objects.get(id=code_id)
        invitation.delete()
        return Response({'success': True})
    except InvitationCode.DoesNotExist:
        return Response({'error': 'Invitation code not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cleanup_expired_invitations(request):
    """Clean up expired invitation codes - Admin only"""
    # Check if user is admin (superuser only)
    if not request.user.is_superuser:
        return Response({'error': 'Only administrators can cleanup invitation codes'}, status=status.HTTP_403_FORBIDDEN)
    
    expired_count = InvitationCode.objects.filter(expires_at__lt=timezone.now()).delete()[0]
    return Response({'deleted_count': expired_count})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_notifications_read(request):
    """Mark all notifications as read for the current user"""
    user = request.user
    is_librarian = user.groups.filter(name='Librarians').exists()
    
    if is_librarian:
        # Librarians can mark all librarian notifications as read
        Notification.objects.filter(for_librarians=True, is_read=False).update(is_read=True)
    else:
        # Regular users can only mark their own notifications as read
        Notification.objects.filter(user=user, for_librarians=False, is_read=False).update(is_read=True)
    
    return Response({'success': True})

def delete_file_from_storage(file_path):
    """Helper function to delete a file from storage"""
    if file_path:
        try:
            # Handle different types of file paths
            if isinstance(file_path, str):
                # For thumbnail URLs that might be full URLs
                if file_path.startswith('http'):
                    # Extract just the media path from URL
                    parts = file_path.split('/media/')
                    if len(parts) > 1:
                        file_path = parts[1]
                    else:
                        logging.warning(f"Could not extract media path from URL: {file_path}")
                        return False
                
                # Remove leading slash if present
                if file_path.startswith('/'):
                    file_path = file_path[1:]
                
                # Remove media/ prefix if present
                if file_path.startswith('media/'):
                    file_path = file_path[6:]
            
            # Check if file exists and delete it
            if default_storage.exists(file_path):
                default_storage.delete(file_path)
                logging.info(f"Successfully deleted file: {file_path}")
                return True
            else:
                logging.warning(f"File not found for deletion: {file_path}")
                return False
        except Exception as e:
            logging.error(f"Error deleting file {file_path}: {str(e)}")
            return False
    return False

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def update_book_details(request, book_id):
    """Update book details (for librarians)"""
    # Check if user is librarian
    if not request.user.groups.filter(name='Librarians').exists():
        return Response({'error': 'Only librarians can update books'}, status=status.HTTP_403_FORBIDDEN)
    
    book = get_object_or_404(Book, id=book_id)
    
    # Use request.data for form fields, request.FILES for files
    data = request.data.copy()
    
    # Update only the fields that are provided
    if 'name' in data:
        book.name = data['name']
    if 'author' in data:
        book.author = data['author']
    if 'category' in data:
        book.category = data['category']
    if 'type' in data:
        book.type = data['type']
    if 'description' in data:
        book.description = data['description']
    if 'publication_year' in data:
        book.publication_year = data['publication_year']
    if 'stock' in data:
        book.stock = data['stock']
    if 'inventory' in data:
        book.inventory = data['inventory']
    if 'book_class' in data:
        book.book_class = data['book_class']
    
    # Handle thumbnail_url deletion
    if 'thumbnail_url' in data and (data['thumbnail_url'] == '' or data['thumbnail_url'] == 'null'):
        # Delete the old thumbnail file from storage
        if book.thumbnail_url:
            delete_file_from_storage(book.thumbnail_url)
        book.thumbnail_url = None
    elif 'thumbnail_url' in data and data['thumbnail_url']:
        # Setting new thumbnail URL
        book.thumbnail_url = data['thumbnail_url']
    
    # Handle pdf_file upload and deletion
    if 'pdf_file' in request.FILES:
        # Delete old PDF file if it exists
        if book.pdf_file:
            delete_file_from_storage(str(book.pdf_file))
        book.pdf_file = request.FILES['pdf_file']
    elif 'pdf_file' in data and (data['pdf_file'] is None or data['pdf_file'] == '' or data['pdf_file'] == 'null'):
        # Delete the old PDF file from storage
        if book.pdf_file:
            delete_file_from_storage(str(book.pdf_file))
        book.pdf_file = None
    elif 'pdf_file' in data and data['pdf_file']:
        # Allow setting PDF path from URL/string (for already uploaded files)
        book.pdf_file = data['pdf_file']
    
    book.save()
    
    # Create notification for librarians
    create_librarian_notification(
        notification_type='book_updated',
        message=f"Cartea '{book.name}' de {book.author} a fost actualizată",
        book=book,
        created_by=request.user
    )
    
    serializer = BookSerializer(book)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([JSONParser])
def cancel_request(request, borrowing_id):
    """Allow a student to cancel their own book request (IN_ASTEPTARE or APROBAT)"""
    try:
        student = request.user.student
    except Exception:
        return Response({'error': 'User is not a student'}, status=status.HTTP_403_FORBIDDEN)

    borrowing = get_object_or_404(BookBorrowing, id=borrowing_id, student=student)

    if borrowing.status not in ['IN_ASTEPTARE', 'APROBAT']:
        return Response({'error': f'Cannot cancel request with status: {borrowing.status}'}, status=status.HTTP_400_BAD_REQUEST)

    # Optional message
    message = request.data.get('message', '').strip()
    if message:
        librarian = User.objects.filter(groups__name='Librarians').first()
        if librarian:
            Message.objects.create(
                sender=request.user,
                recipient=librarian,
                borrowing=borrowing,
                content=f'Mesaj la anulare: {message}'
            )

    borrowing.status = 'ANULATA'
    borrowing.save()

    # Notificare pentru student
    create_user_notification(
        user=request.user,
        notification_type='request_cancelled',
        message=f'Cererea ta pentru "{borrowing.book.name}" a fost anulată.',
        book=borrowing.book,
        borrowing=borrowing
    )

    serializer = BookBorrowingSerializer(borrowing)
    return Response({'success': True, 'borrowing': serializer.data})
