import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from django.contrib.auth.models import User, Group
from booklibrary.models import Student

def check_profiles():
    # Check if the student user has a student profile
    try:
        student_user = User.objects.get(username='student')
        has_profile = hasattr(student_user, 'student')
        print(f"Student user exists, has student profile: {has_profile}")
        
        if has_profile:
            student = student_user.student
            print(f"Current student profile:")
            print(f"Student ID: {student.student_id}")
            print(f"School type: {student.school_type}")
            print(f"Department: {student.department}")
            print(f"Class: {student.student_class}")
            
            # Update student profile to 10th grade N class
            print("\nUpdating student profile to 10th grade N class...")
            student.school_type = 'Liceu'
            student.department = 'N'
            student.student_class = 'X'
            student.save()
            
            print("\nUpdated student profile:")
            print(f"Student ID: {student.student_id}")
            print(f"School type: {student.school_type}")
            print(f"Department: {student.department}")
            print(f"Class: {student.student_class}")
        else:
            print("Creating student profile...")
            Student.objects.create(
                user=student_user,
                student_id='ST100001',
                school_type='Liceu',
                department='N',
                student_class='X'
            )
            print("Student profile created successfully with:")
            print("School type: Liceu")
            print("Department: N")
            print("Class: X")
    except User.DoesNotExist:
        print("Student user doesn't exist!")
    
    # Check if teacher is in the Teachers group
    try:
        teacher_user = User.objects.get(username='teacher')
        teacher_group, created = Group.objects.get_or_create(name='Teachers')
        is_in_group = teacher_user.groups.filter(name='Teachers').exists()
        print(f"\nTeacher user exists, in Teachers group: {is_in_group}")
        
        if not is_in_group:
            print("Adding teacher to Teachers group...")
            teacher_user.groups.add(teacher_group)
            teacher_user.is_staff = True
            teacher_user.save()
            print("Teacher added to Teachers group.")
    except User.DoesNotExist:
        print("Teacher user doesn't exist!")
    
    # Check if librarian is in the Librarians group
    try:
        librarian_user = User.objects.get(username='librarian')
        librarian_group, created = Group.objects.get_or_create(name='Librarians')
        is_in_group = librarian_user.groups.filter(name='Librarians').exists()
        print(f"\nLibrarian user exists, in Librarians group: {is_in_group}")
        
        if not is_in_group:
            print("Adding librarian to Librarians group...")
            librarian_user.groups.add(librarian_group)
            librarian_user.is_staff = True
            librarian_user.save()
            print("Librarian added to Librarians group.")
    except User.DoesNotExist:
        print("Librarian user doesn't exist!")

if __name__ == '__main__':
    check_profiles() 