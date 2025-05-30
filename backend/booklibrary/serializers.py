from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Book, Student, BookBorrowing, Message
import re

# Email validation pattern for nlenau.ro domain
EMAIL_PATTERN = r'^[a-zA-Z0-9_.+-]+@nlenau\.ro$'
TEACHER_CODE = "Teacher101"

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

class BookSerializer(serializers.ModelSerializer):
    available_copies = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Book
        fields = ['id', 'name', 'inventory', 'thumbnail_url', 'author', 'stock', 
                 'description', 'category', 'publication_year', 'available_copies']

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
                 'fine_amount', 'loan_duration_days', 'student_message']
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
    teacher_code = serializers.CharField(max_length=50, required=False, allow_blank=True)
    
    def validate_email(self, value):
        """Validate that email is from nlenau.ro domain"""
        if not re.match(EMAIL_PATTERN, value):
            raise serializers.ValidationError("Email must be from the nlenau.ro domain")
        
        # Check if email already exists
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already exists")
        
        return value
    
    def validate(self, data):
        """Validate data and generate username if not provided"""
        # Generate username from email if not provided
        if 'username' not in data or not data['username']:
            # Extract username from email (part before @)
            email = data['email']
            username_part = email.split('@')[0]
            
            # Check if this username already exists
            if User.objects.filter(username=username_part).exists():
                # Add a timestamp suffix to make it unique
                import time
                username = f"{username_part}_{int(time.time())}"
            else:
                username = username_part
                
            data['username'] = username
        
        # Validate teacher code and student data based on school type
        is_teacher = data.get('is_teacher', False)
        
        if is_teacher:
            teacher_code = data.get('teacher_code')
            if not teacher_code or teacher_code != TEACHER_CODE:
                raise serializers.ValidationError({'teacher_code': 'Invalid teacher code'})
        else:
            # For students, validate school_type, department, and student_class
            if data.get('school_type') == 'Liceu' and not data.get('department'):
                raise serializers.ValidationError({'department': 'Department is required for high school students'})
            
            if data.get('school_type') == 'Liceu' and not data.get('student_class'):
                raise serializers.ValidationError({'student_class': 'Class is required for high school students'})
        
        return data
    
    def validate_username(self, value):
        """Validate that username is unique"""
        if value and User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Username already exists")
        return value
    
    def validate_school_type(self, value):
        """Validate that school_type is one of the allowed values"""
        if value and value not in ["Generala", "Liceu"]:
            raise serializers.ValidationError("School type must be either Generala or Liceu")
    
    def validate_department(self, value):
        """Validate that department is one of the allowed values"""
        if value and value not in ["N", "SW", "STS", "MI", "FILO"]:
            raise serializers.ValidationError("Department must be one of: N, SW, STS, MI, FILO")
        return value
    
    def validate_student_class(self, value):
        """Validate that student_class is one of the allowed values"""
        if value and value not in ["IX", "X", "XI", "XII"]:
            raise serializers.ValidationError("Student class must be one of: IX, X, XI, XII")
        return value
    
    def create(self, validated_data):
        """Create user and student/teacher profile"""
        # Remove fields not needed for User model
        is_teacher = validated_data.pop('is_teacher', False)
        teacher_code = validated_data.pop('teacher_code', None)
        school_type = validated_data.pop('school_type', None)
        department = validated_data.pop('department', None)
        student_class = validated_data.pop('student_class', None)
        phone_number = validated_data.pop('phone_number', '')
        
        # Create user
        user = User.objects.create_user(**validated_data)
        
        if not is_teacher:
            # Create student profile
            student_id = f"ST{100000 + user.id}"
            Student.objects.create(
                user=user,
                student_id=student_id,
                school_type=school_type,
                department=department,
                student_class=student_class,
                phone_number=phone_number
            )
        else:
            # If teacher, add to teacher group and make staff
            from django.contrib.auth.models import Group
            teacher_group, _ = Group.objects.get_or_create(name='Teachers')
            user.groups.add(teacher_group)
            user.is_staff = True
            user.save()
        
        return user
