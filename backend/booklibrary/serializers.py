from rest_framework import serializers
from django.contrib.auth.models import User, Group
from .models import Book, Student, BookBorrowing, Message, ExamModel, EmailVerification, InvitationCode
from .utils import get_display_name
import re
import logging

# Email validation pattern for nlenau.ro domain
EMAIL_PATTERN = r'^[a-zA-Z0-9_.+-]+@nlenau\.ro$'

class InvitationCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvitationCode
        fields = ['id', 'code', 'created_by', 'created_at', 'expires_at']
        read_only_fields = ['code', 'created_by', 'created_at', 'expires_at']

class UserSerializer(serializers.ModelSerializer):
    display_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'display_name']
    
    def get_display_name(self, obj):
        return get_display_name(obj)

class BookSerializer(serializers.ModelSerializer):
    available_copies = serializers.IntegerField(read_only=True)
    pdf_file = serializers.SerializerMethodField()
    
    class Meta:
        model = Book
        fields = ['id', 'name', 'inventory', 'thumbnail_url', 'author', 'stock', 
                 'description', 'category', 'type', 'publication_year', 'book_class', 'available_copies', 'pdf_file']

    def get_pdf_file(self, obj):
        request = self.context.get('request')
        if obj.pdf_file:
            if request is not None:
                return request.build_absolute_uri(obj.pdf_file.url)
            return obj.pdf_file.url
        return None

class StudentSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    
    class Meta:
        model = Student
        fields = ['id', 'user', 'student_id', 'school_type', 'department', 'student_class', 'phone_number']

class BookBorrowingSerializer(serializers.ModelSerializer):
    book = BookSerializer(read_only=True)
    student = StudentSerializer(read_only=True)
    book_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = BookBorrowing
        fields = ['id', 'book', 'student', 'book_id', 'request_date', 'approved_date',
                 'pickup_date', 'borrow_date', 'due_date', 'return_date', 'status', 
                 'fine_amount', 'loan_duration_days', 'student_message', 'has_been_extended']
        read_only_fields = ['request_date', 'approved_date', 'pickup_date', 'fine_amount']

class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    
    class Meta:
        model = Message
        fields = ['id', 'sender', 'recipient', 'borrowing', 'content', 'timestamp', 'is_read']
        read_only_fields = ['timestamp', 'is_read']

class RegistrationSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150, required=False)  # Made optional
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    email = serializers.EmailField(required=True)
    first_name = serializers.CharField(max_length=150, required=True)
    last_name = serializers.CharField(max_length=150, required=True)
    school_type = serializers.CharField(max_length=10, required=False, allow_blank=True)
    department = serializers.CharField(max_length=100, required=False, allow_blank=True)
    student_class = serializers.CharField(max_length=10, required=False, allow_blank=True)
    phone_number = serializers.CharField(max_length=15, required=False, allow_blank=True)
    
    is_teacher = serializers.BooleanField(default=False)
    invitation_code = serializers.CharField(max_length=20, required=False, allow_blank=True)
    
    def validate_email(self, value):
        """Validate that email is from nlenau.ro domain"""
        if not re.match(EMAIL_PATTERN, value):
            raise serializers.ValidationError("Email must be from the nlenau.ro domain")
        
        # Check if email already exists
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already exists")
        
        return value
    
    def validate(self, data):
        """Validate invitation code for teachers"""
        is_teacher = data.get('is_teacher', False)
        invitation_code = data.get('invitation_code', '')
        
        if is_teacher:
            if not invitation_code:
                raise serializers.ValidationError({'invitation_code': 'Invitation code is required for teacher registration'})
            
            try:
                invitation = InvitationCode.objects.get(code=invitation_code.upper())
                if not invitation.is_valid():
                    raise serializers.ValidationError({'invitation_code': 'Invalid/Expired invitation code'})
            except InvitationCode.DoesNotExist:
                raise serializers.ValidationError({'invitation_code': 'Invalid/Expired invitation code'})
        
        return data
    
    def create(self, validated_data):
        is_teacher = validated_data.pop('is_teacher', False)
        invitation_code = validated_data.pop('invitation_code', None)
        
        # Capitalize names before creating user
        first_name = validated_data.get('first_name', '').strip()
        last_name = validated_data.get('last_name', '').strip()
        
        # Create user
        user = User.objects.create_user(
            username=validated_data.get('username') or validated_data['email'].split('@')[0],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=first_name.title(),
            last_name=last_name.title()
        )
        
        if is_teacher:
            # Add to Teachers group and make staff
            teachers_group, created = Group.objects.get_or_create(name='Teachers')
            user.groups.add(teachers_group)
            user.is_staff = True
            user.save()
            
            # Use and delete invitation code
            if invitation_code:
                invitation = InvitationCode.objects.get(code=invitation_code.upper())
                usage_info = invitation.use_code(user)
                
                # Log the invitation code usage
                logger = logging.getLogger('invitation_code_logger')
                logger.info(f"Invitation code {usage_info['code']} used by {usage_info['used_by'].email} at {usage_info['used_at']}")
        else:
            # Create student profile
            student = Student.objects.create(
                user=user,
                student_id=f"ST{user.id:06d}",
                school_type=validated_data.get('school_type'),
                department=validated_data.get('department'),
                student_class=validated_data.get('student_class'),
                phone_number=validated_data.get('phone_number')
            )
        
        return user

class ExamModelSerializer(serializers.ModelSerializer):
    def validate_pdf_file(self, value):
        """Validate that uploaded file is a PDF"""
        if value:
            # Check file extension (primary validation)
            if not value.name.lower().endswith('.pdf'):
                raise serializers.ValidationError("Only PDF files are allowed.")
            
            # Check file size (limit to 10MB)
            if value.size > 10 * 1024 * 1024:  # 10MB in bytes
                raise serializers.ValidationError("File size must be less than 10MB.")
            
            # Check MIME type if available (secondary validation)
            if hasattr(value, 'content_type') and value.content_type:
                # Be more lenient with MIME type - accept common PDF MIME types
                allowed_mime_types = [
                    'application/pdf',
                    'application/x-pdf',
                    'binary/octet-stream',  # Sometimes PDFs are sent with this type
                    'application/octet-stream',  # Another common fallback
                ]
                if value.content_type not in allowed_mime_types:
                    # Log the unexpected MIME type for debugging
                    logger = logging.getLogger(__name__)
                    logger.warning(f"Unexpected MIME type for PDF file: {value.content_type}, filename: {value.name}")
                    # Don't raise error for MIME type mismatch if extension is correct
        
        return value
    
    class Meta:
        model = ExamModel
        fields = ['id', 'name', 'type', 'category', 'pdf_file', 'created_at']

class EmailVerificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmailVerification
        fields = ['user', 'token', 'is_verified', 'created_at']
        read_only_fields = ['user', 'token', 'is_verified', 'created_at']
