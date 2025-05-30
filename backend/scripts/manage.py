"""
Unified management script for Lenbrary backend operations.
"""
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime

from .utils import (
    setup_django,
    get_base_dir,
    confirm_action,
    backup_file
)

def list_users_and_groups():
    """List all users and their groups."""
    setup_django()
    from django.contrib.auth.models import User, Group
    
    print("\n👥 Users and Groups Report 👥\n")
    
    # Get all users
    users = User.objects.all().order_by('username')
    if not users:
        print("No users found in the database.")
        return
    
    # Get all groups
    groups = Group.objects.all().order_by('name')
    
    # Print users
    print("Users:")
    print("-" * 50)
    for user in users:
        user_groups = [g.name for g in user.groups.all()]
        status = []
        if user.is_superuser:
            status.append("Superuser")
        if user.is_staff:
            status.append("Staff")
        if not user.is_active:
            status.append("Inactive")
        
        print(f"Username: {user.username}")
        print(f"Full Name: {user.get_full_name() or 'N/A'}")
        print(f"Email: {user.email}")
        print(f"Groups: {', '.join(user_groups) or 'None'}")
        print(f"Status: {', '.join(status) or 'Normal'}")
        print(f"Last Login: {user.last_login or 'Never'}")
        print("-" * 50)
    
    # Print groups
    print("\nGroups:")
    print("-" * 50)
    for group in groups:
        members = User.objects.filter(groups=group).count()
        print(f"Group: {group.name}")
        print(f"Members: {members}")
        print("-" * 50)

def delete_user(username=None):
    """Delete a specific user or list users for deletion."""
    setup_django()
    from django.contrib.auth.models import User
    
    print("\n🗑️  User Deletion Tool 🗑️\n")
    
    if username:
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            print(f"❌ User '{username}' not found.")
            return
    else:
        # List all users for selection
        users = User.objects.all().order_by('username')
        if not users:
            print("No users found in the database.")
            return
        
        print("Available users:")
        for i, user in enumerate(users, 1):
            print(f"{i}. {user.username} ({user.get_full_name() or 'No name'})")
        
        try:
            choice = int(input("\nEnter the number of the user to delete (0 to cancel): "))
            if choice == 0:
                print("Operation cancelled.")
                return
            if 1 <= choice <= len(users):
                user = users[choice - 1]
            else:
                print("Invalid selection.")
                return
        except ValueError:
            print("Invalid input. Please enter a number.")
            return
    
    if not confirm_action(f"Are you sure you want to delete user '{user.username}'?", "DELETE"):
        print("Operation cancelled.")
        return
    
    try:
        username = user.username
        user.delete()
        print(f"\n✅ User '{username}' deleted successfully!")
    except Exception as e:
        print(f"\n❌ Error deleting user: {str(e)}")

def cleanup_users():
    """Clean up inactive or problematic users."""
    setup_django()
    from django.contrib.auth.models import User
    from django.utils import timezone
    
    print("\n🧹 User Cleanup Tool 🧹\n")
    
    # Find users who haven't logged in for 30 days
    thirty_days_ago = timezone.now() - timezone.timedelta(days=30)
    inactive_users = User.objects.filter(
        last_login__lt=thirty_days_ago,
        is_superuser=False
    ).exclude(groups__name='Librarians')
    
    if not inactive_users:
        print("No inactive users found.")
        return
    
    print(f"Found {inactive_users.count()} inactive users:")
    for user in inactive_users:
        print(f"- {user.username} (Last login: {user.last_login or 'Never'})")
    
    if not confirm_action("Delete these inactive users?", "CLEANUP"):
        print("Operation cancelled.")
        return
    
    deleted_count = 0
    for user in inactive_users:
        try:
            username = user.username
            user.delete()
            deleted_count += 1
            print(f"Deleted user: {username}")
        except Exception as e:
            print(f"Error deleting {user.username}: {str(e)}")
    
    print(f"\n✅ Cleanup complete. Deleted {deleted_count} users.")

def setup_essential_groups():
    """Create essential user groups."""
    from .utils import create_or_get_group
    
    print("\nSetting up essential groups...")
    try:
        for group_name in ['Librarians', 'Teachers']:
            create_or_get_group(group_name)
        print("\nEssential groups created:")
        print("- Librarians")
        print("- Teachers")
    except Exception as e:
        print(f"\n❌ Error creating groups: {str(e)}")

def recreate_database():
    """Recreate the database from scratch."""
    print("\n🗄️  Database Recreation Tool 🗄️\n")
    
    if not confirm_action("This will delete the database and recreate it from scratch. ALL DATA WILL BE PERMANENTLY LOST.", "RECREATE"):
        print("Operation cancelled.")
        return
    
    db_path = get_base_dir() / "db.sqlite3"
    
    if db_path.exists():
        print(f"\nFound database at: {db_path}")
        try:
            backup_path = backup_file(db_path)
            print(f"Created backup at: {backup_path}")
            db_path.unlink()
        except Exception as e:
            print(f"Error backing up/removing database: {str(e)}")
            return
    else:
        print("No existing database found. Will create new one.")
    
    print("\nRunning migrations...")
    try:
        subprocess.run([sys.executable, "manage.py", "migrate"], check=True)
        print("\n✅ Database recreated successfully!")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error during migrations: {str(e)}")
        return
    
    setup_django()
    setup_essential_groups()

def create_librarian():
    """Create a librarian account."""
    print("\n📚 Create Librarian Account 📚\n")
    setup_django()
    
    from django.contrib.auth.models import User
    from .utils import create_or_get_group
    
    defaults = {
        'username': 'librarian',
        'password': 'Library123',
        'email': 'librarian@nlenau.ro',
        'first_name': 'Library',
        'last_name': 'Admin'
    }
    
    use_defaults = input("Use default values? [Y/n]: ").lower() != 'n'
    
    if use_defaults:
        values = defaults
    else:
        values = {
            key: input(f"{key.replace('_', ' ').title()} [{defaults[key]}]: ") or defaults[key]
            for key in defaults
        }
    
    if User.objects.filter(username=values['username']).exists():
        if not confirm_action(f"User '{values['username']}' exists. Replace?", "y"):
            print("Operation cancelled.")
            return
        User.objects.filter(username=values['username']).delete()
        print(f"Deleted existing user: {values['username']}")
    
    try:
        librarian = User.objects.create_user(
            username=values['username'],
            email=values['email'],
            password=values['password'],
            first_name=values['first_name'],
            last_name=values['last_name']
        )
        
        librarians_group = create_or_get_group('Librarians')
        librarian.groups.add(librarians_group)
        librarian.is_staff = True
        librarian.save()
        
        print("\n✅ Librarian account created successfully!")
        for key, value in values.items():
            if key != 'password':
                print(f"{key.replace('_', ' ').title()}: {value}")
        print(f"Password: {values['password']}")
    except Exception as e:
        print(f"\n❌ Error creating librarian: {str(e)}")

def update_student(username=None):
    """Update or create a student profile."""
    setup_django()
    from django.contrib.auth.models import User
    from booklibrary.models import Student
    
    print("\n👨‍🎓 Student Profile Management 👨‍🎓\n")
    
    if username:
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            print(f"❌ User '{username}' not found.")
            return
    else:
        # List all users for selection
        users = User.objects.all().order_by('username')
        if not users:
            print("No users found in the database.")
            return
        
        print("Available users:")
        for i, user in enumerate(users, 1):
            print(f"{i}. {user.username} ({user.get_full_name() or 'No name'})")
        
        try:
            choice = int(input("\nEnter the number of the user to update (0 to cancel): "))
            if choice == 0:
                print("Operation cancelled.")
                return
            if 1 <= choice <= len(users):
                user = users[choice - 1]
            else:
                print("Invalid selection.")
                return
        except ValueError:
            print("Invalid input. Please enter a number.")
            return
    
    # Get or create student profile
    student, created = Student.objects.get_or_create(user=user)
    
    if created:
        print(f"\nCreating new student profile for {user.username}")
    else:
        print(f"\nCurrent student profile for {user.username}:")
        print(f"Student ID: {student.student_id}")
        print(f"School type: {student.school_type}")
        print(f"Department: {student.department}")
        print(f"Class: {student.student_class}")
    
    # Get new values
    print("\nEnter new values (press Enter to keep current values):")
    student.student_id = input(f"Student ID [{student.student_id or 'ST100001'}]: ") or (student.student_id or 'ST100001')
    student.school_type = input(f"School type [{student.school_type or 'Liceu'}]: ") or (student.school_type or 'Liceu')
    student.department = input(f"Department [{student.department or 'MI'}]: ") or (student.department or 'MI')
    student.student_class = input(f"Class [{student.student_class or 'X'}]: ") or (student.student_class or 'X')
    
    try:
        student.save()
        print("\n✅ Student profile updated successfully!")
        print(f"Student ID: {student.student_id}")
        print(f"School type: {student.school_type}")
        print(f"Department: {student.department}")
        print(f"Class: {student.student_class}")
    except Exception as e:
        print(f"\n❌ Error updating student profile: {str(e)}")

def main():
    """Main entry point for the management script."""
    if len(sys.argv) < 2:
        print("Usage: python -m scripts.manage <command> [args]")
        print("\nAvailable commands:")
        print("  recreate-db           - Recreate the database from scratch")
        print("  create-librarian      - Create a new librarian account")
        print("  list-users           - List all users and their groups")
        print("  delete-user [name]   - Delete a specific user (or list users to choose from)")
        print("  cleanup-users        - Clean up inactive users")
        print("  update-student [name] - Update or create a student profile")
        return
    
    command = sys.argv[1]
    args = sys.argv[2:] if len(sys.argv) > 2 else []
    
    if command == "recreate-db":
        recreate_database()
    elif command == "create-librarian":
        create_librarian()
    elif command == "list-users":
        list_users_and_groups()
    elif command == "delete-user":
        delete_user(args[0] if args else None)
    elif command == "cleanup-users":
        cleanup_users()
    elif command == "update-student":
        update_student(args[0] if args else None)
    else:
        print(f"Unknown command: {command}")

if __name__ == "__main__":
    main() 