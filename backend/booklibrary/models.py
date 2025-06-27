from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.utils.crypto import get_random_string

class Book(models.Model):
    name = models.CharField(max_length=255)
    inventory = models.IntegerField()
    thumbnail_url = models.CharField(max_length=500, blank=True, null=True)
    author = models.CharField(max_length=255)
    stock = models.IntegerField()
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=100, blank=True, null=True)
    publication_year = models.IntegerField(blank=True, null=True)

    def __str__(self):
        return self.name

    @property
    def available_copies(self):
        # Available copies is simply the current stock
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
        return f"{self.user.get_full_name()} ({self.student_id})"

class BookBorrowing(models.Model):
    STATUS_CHOICES = [
        ('IN_ASTEPTARE', 'În așteptare'),
        ('APROBAT', 'Aprobat'),
        ('GATA_RIDICARE', 'Gata de ridicare'),
        ('IMPRUMUTAT', 'Împrumutat'),
        ('RETURNAT', 'Returnat'),
        ('INTARZIAT', 'Întârziat'),
        ('RESPINS', 'Respins'),
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

class EmailVerification(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='email_verification')
    token = models.CharField(max_length=64, unique=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def generate_token(self):
        self.token = get_random_string(48)
        self.save()

    def __str__(self):
        return f"{self.user.email} - {'Verified' if self.is_verified else 'Unverified'}"
