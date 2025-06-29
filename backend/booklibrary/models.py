from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.utils.crypto import get_random_string
from datetime import timedelta
from .utils import get_display_name

class Book(models.Model):
    TYPE_CHOICES = [
        ('carte', 'Carte'),
        ('manual', 'Manual'),
    ]
    
    # Class choices for manuals (gimnaziu and liceu)
    CLASS_CHOICES = [
        # Gimnaziu classes
        ('V', 'V'),
        ('VI', 'VI'),
        ('VII', 'VII'),
        ('VIII', 'VIII'),
        # Liceu classes
        ('IX', 'IX'),
        ('X', 'X'),
        ('XI', 'XI'),
        ('XII', 'XII'),
    ]
    
    name = models.CharField(max_length=255)
    inventory = models.IntegerField()
    thumbnail_url = models.CharField(max_length=500, blank=True, null=True)
    author = models.CharField(max_length=255)
    stock = models.IntegerField()
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=100, blank=True, null=True)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='carte')
    publication_year = models.IntegerField(blank=True, null=True)
    book_class = models.CharField(max_length=10, choices=CLASS_CHOICES, blank=True, null=True, verbose_name='Clasă')
    pdf_file = models.FileField(upload_to='books/', blank=True, null=True)  # PDF file for manuals

    def __str__(self):
        return self.name

    @property
    def available_copies(self):
        # Available copies is the difference between inventory and stock
        # Inventory = total copies in library
        # Stock = copies currently available for borrowing
        return self.stock

class Student(models.Model):
    SECTION_CHOICES = [
        ('N', 'N'),
        ('SW', 'SW'),
        ('STS', 'STS'),
        ('MI', 'MI'),
        ('FILO', 'FILO'),
    ]
    
    SCHOOL_TYPE_CHOICES = [
        ('Generala', 'Generala'),
        ('Liceu', 'Liceu'),
    ]
    
    CLASS_CHOICES = [
        # Generala classes
        ('V-A', 'V-A'), ('V-B', 'V-B'), ('V-C', 'V-C'), ('V-D', 'V-D'), ('V-E', 'V-E'), ('V-F', 'V-F'),
        ('VI-A', 'VI-A'), ('VI-B', 'VI-B'), ('VI-C', 'VI-C'), ('VI-D', 'VI-D'), ('VI-E', 'VI-E'), ('VI-F', 'VI-F'),
        ('VII-A', 'VII-A'), ('VII-B', 'VII-B'), ('VII-C', 'VII-C'), ('VII-D', 'VII-D'), ('VII-E', 'VII-E'), ('VII-F', 'VII-F'),
        ('VIII-A', 'VIII-A'), ('VIII-B', 'VIII-B'), ('VIII-C', 'VIII-C'), ('VIII-D', 'VIII-D'), ('VIII-E', 'VIII-E'), ('VIII-F', 'VIII-F'),
        # Liceu classes
        ('IX', 'IX'), ('X', 'X'), ('XI', 'XI'), ('XII', 'XII'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    student_id = models.CharField(max_length=50, unique=True)
    school_type = models.CharField(max_length=10, choices=SCHOOL_TYPE_CHOICES, null=True, blank=True)
    department = models.CharField(max_length=100, choices=SECTION_CHOICES, null=True, blank=True)
    student_class = models.CharField(max_length=10, choices=CLASS_CHOICES, null=True, blank=True)
    phone_number = models.CharField(max_length=15, blank=True, null=True)

    def __str__(self):
        return f"{get_display_name(self.user)} ({self.student_id})"

class BookBorrowing(models.Model):
    STATUS_CHOICES = [
        ('IN_ASTEPTARE', 'În așteptare'),
        ('APROBAT', 'Aprobat'),
        ('GATA_RIDICARE', 'Gata de ridicare'),
        ('IMPRUMUTAT', 'Împrumutat'),
        ('RETURNAT', 'Returnat'),
        ('INTARZIAT', 'Întârziat'),
        ('RESPINS', 'Respins'),
        ('ANULATA', 'Anulată'),  # New status for cancelled by user
    ]
    
    # Map old status values to new ones for backwards compatibility
    STATUS_MAP = {
        'PENDING': 'IN_ASTEPTARE',
        'APPROVED': 'APROBAT',
        'READY_FOR_PICKUP': 'GATA_RIDICARE',
        'BORROWED': 'IMPRUMUTAT',
        'RETURNED': 'RETURNAT',
        'OVERDUE': 'INTARZIAT',
        'REJECTED': 'RESPINS',
    }
    
    LOAN_DURATION_CHOICES = [
        (7, '1 Săptămână'),
        (14, '2 Săptămâni'),
        (30, '1 Lună'),
        (60, '2 Luni'),
    ]

    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    request_date = models.DateTimeField(auto_now_add=True)
    approved_date = models.DateTimeField(null=True, blank=True)
    pickup_date = models.DateTimeField(null=True, blank=True)  # Date when the book was picked up
    borrow_date = models.DateTimeField(null=True, blank=True)
    due_date = models.DateTimeField(null=True, blank=True)
    return_date = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='IN_ASTEPTARE')
    fine_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    loan_duration_days = models.IntegerField(choices=LOAN_DURATION_CHOICES, default=14)  # Default 2 weeks
    student_message = models.TextField(blank=True, null=True)  # Message from student about extension request or other
    has_been_extended = models.BooleanField(default=False)  # Track if this loan has been extended before

    def __str__(self):
        return f"{self.student} - {self.book} ({self.status})"

    def calculate_fine(self):
        if self.due_date and not self.return_date and timezone.now() > self.due_date:
            days_overdue = (timezone.now() - self.due_date).days
            return max(0, days_overdue * 1.00)  # $1 per day
        return 0.00

class Message(models.Model):
    sender = models.ForeignKey(User, related_name='sent_messages', on_delete=models.CASCADE)
    recipient = models.ForeignKey(User, related_name='received_messages', on_delete=models.CASCADE)
    borrowing = models.ForeignKey(BookBorrowing, null=True, blank=True, on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    conversation_id = models.CharField(max_length=100, null=True, blank=True)  # To group messages in conversations

    class Meta:
        ordering = ['timestamp']  # Changed to ascending order for chat-like display

    def __str__(self):
        return f"From {self.sender.username} to {self.recipient.username} at {self.timestamp}"

    def save(self, *args, **kwargs):
        if not self.conversation_id:
            # Generate conversation_id based on sender and recipient IDs
            # Sort IDs to ensure same conversation_id regardless of who sends first
            user_ids = sorted([self.sender.id, self.recipient.id])
            self.conversation_id = f"conv_{user_ids[0]}_{user_ids[1]}"
        super().save(*args, **kwargs)

class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('book_added', 'Carte adăugată'),
        ('stock_updated', 'Stoc actualizat'),
        ('book_deleted', 'Carte ștearsă'),
        ('book_requested', 'Carte solicitată'),
        ('request_approved', 'Cerere aprobată'),
        ('request_rejected', 'Cerere respinsă'),
        ('book_returned', 'Carte returnată'),
        ('extension_requested', 'Extindere solicitată'),
    ]
    
    # For librarians, user is null (system notification for all librarians)
    # For students, the specific student
    user = models.ForeignKey(User, null=True, blank=True, on_delete=models.CASCADE, 
                            related_name='notifications')
    book = models.ForeignKey(Book, null=True, blank=True, on_delete=models.SET_NULL,
                           related_name='notifications')
    borrowing = models.ForeignKey(BookBorrowing, null=True, blank=True, on_delete=models.CASCADE,
                                related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    
    # For librarians only: who triggered this notification
    created_by = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL,
                                 related_name='created_notifications')
    
    # If True, shown to librarians, if False shown to students/teachers
    for_librarians = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        target = self.user.username if self.user else "Librarians"
        return f"{self.notification_type} for {target} at {self.timestamp}"

class ExamModel(models.Model):
    EXAM_TYPE_CHOICES = [
        ('EN', 'Evaluare Națională'),
        ('BAC', 'Bacalaureat'),
    ]
    CATEGORY_CHOICES = [
        ('Matematica', 'Matematică'),
        ('Romana', 'Română'),
    ]
    name = models.CharField(max_length=255)
    type = models.CharField(max_length=3, choices=EXAM_TYPE_CHOICES)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    pdf_file = models.FileField(upload_to='exam_models/')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.get_type_display()}) - {self.get_category_display()}"

class InvitationCode(models.Model):
    code = models.CharField(max_length=20, unique=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_invitations')
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    def is_expired(self):
        """Check if the invitation code has expired"""
        return timezone.now() > self.expires_at
    
    def is_valid(self):
        """Check if the invitation code is valid (not expired)"""
        return not self.is_expired()
    
    def use_code(self, user):
        """Use the code and then delete it"""
        if not self.is_valid():
            raise ValueError("Code is not valid (expired)")
        
        # Store the user who used it before deletion (for logging purposes)
        used_by_user = user
        
        # Delete the invitation code
        self.delete()
        
        # Return information about the used code (for logging)
        return {
            'code': self.code,
            'used_by': used_by_user,
            'used_at': timezone.now()
        }
    
    def generate_code(self):
        """Generate a unique invitation code"""
        from django.utils.crypto import get_random_string
        while True:
            code = get_random_string(8).upper()  # 8 character uppercase code
            if not InvitationCode.objects.filter(code=code).exists():
                self.code = code
                self.save()
                break
    
    def __str__(self):
        status = "Expired" if self.is_expired() else "Valid"
        return f"{self.code} - {status} (created by {self.created_by.username})"

class EmailVerification(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='email_verification')
    token = models.CharField(max_length=64, unique=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        if not self.token:
            self.generate_token()
        super().save(*args, **kwargs)
    
    def generate_token(self):
        """Generate a unique token, ensuring no duplicates"""
        while True:
            token = get_random_string(48)
            if not EmailVerification.objects.filter(token=token).exists():
                self.token = token
                break

    def is_expired(self):
        """Check if the verification token has expired (6 hours)"""
        expiration_time = self.created_at + timedelta(hours=6)
        return timezone.now() > expiration_time

    def __str__(self):
        return f"{self.user.email} - {'Verified' if self.is_verified else 'Unverified'}"
