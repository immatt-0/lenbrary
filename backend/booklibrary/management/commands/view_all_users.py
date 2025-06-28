from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from booklibrary.models import Student, EmailVerification
from datetime import datetime


class Command(BaseCommand):
    help = 'Display all users (verified and unverified) with their details and option to delete expired unverified users'

    def add_arguments(self, parser):
        parser.add_argument(
            '--delete-expired',
            action='store_true',
            help='Automatically delete expired unverified users without prompting',
        )

    def handle(self, *args, **options):
        """Display all users (verified and unverified) with their details."""
        self.stdout.write("=" * 80)
        self.stdout.write("ALL USERS (VERIFIED AND UNVERIFIED)")
        self.stdout.write("=" * 80)
        
        # Get all users
        users = User.objects.all().order_by('date_joined')
        
        if not users.exists():
            self.stdout.write("No users found in the system.")
            return
        
        verified_count = 0
        unverified_count = 0
        expired_unverified_users = []
        
        for user in users:
            self.stdout.write(f"\nUser ID: {user.id}")
            self.stdout.write(f"Username: {user.username}")
            self.stdout.write(f"Email: {user.email}")
            self.stdout.write(f"First Name: {user.first_name}")
            self.stdout.write(f"Last Name: {user.last_name}")
            self.stdout.write(f"Date Joined: {user.date_joined.strftime('%Y-%m-%d %H:%M:%S')}")
            self.stdout.write(f"Is Active: {user.is_active}")
            self.stdout.write(f"Is Staff: {user.is_staff}")
            self.stdout.write(f"Is Superuser: {user.is_superuser}")
            
            # Check if user is verified
            try:
                email_verification = EmailVerification.objects.get(user=user)
                if email_verification.is_verified:
                    self.stdout.write("Status: ✅ VERIFIED")
                    verified_count += 1
                else:
                    self.stdout.write("Status: ❌ UNVERIFIED")
                    self.stdout.write(f"Verification Token: {email_verification.token}")
                    self.stdout.write(f"Verification Created: {email_verification.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
                    self.stdout.write(f"Verification Expires: {email_verification.expires_at.strftime('%Y-%m-%d %H:%M:%S')}")
                    
                    # Check if expired (past 6 hours)
                    now = datetime.now()
                    if email_verification.expires_at < now:
                        self.stdout.write("⚠️  EXPIRED (Past 6 hours)")
                        expired_unverified_users.append((user, email_verification))
                    else:
                        self.stdout.write("⏰ NOT EXPIRED YET")
                    
                    unverified_count += 1
            except EmailVerification.DoesNotExist:
                self.stdout.write("Status: ❌ NO VERIFICATION RECORD")
                unverified_count += 1
            
            # Check if user is a student
            try:
                student = Student.objects.get(user=user)
                self.stdout.write(f"Student Department: {student.department}")
                self.stdout.write(f"Student Class: {student.student_class}")
                self.stdout.write(f"School Type: {student.school_type}")
            except Student.DoesNotExist:
                self.stdout.write("Student Profile: No student profile")
            
            self.stdout.write("-" * 80)
        
        self.stdout.write(f"\nSUMMARY:")
        self.stdout.write(f"Total Users: {users.count()}")
        self.stdout.write(f"Verified Users: {verified_count}")
        self.stdout.write(f"Unverified Users: {unverified_count}")
        self.stdout.write(f"Expired Unverified Users: {len(expired_unverified_users)}")
        self.stdout.write("=" * 80)
        
        # Handle expired unverified users
        if expired_unverified_users:
            self.stdout.write(f"\n⚠️  FOUND {len(expired_unverified_users)} EXPIRED UNVERIFIED USERS:")
            for i, (user, verification) in enumerate(expired_unverified_users, 1):
                self.stdout.write(f"{i}. {user.username} ({user.email}) - Expired: {verification.expires_at.strftime('%Y-%m-%d %H:%M:%S')}")
            
            if options['delete_expired']:
                self.delete_expired_users(expired_unverified_users)
            else:
                while True:
                    choice = input(f"\nDo you want to delete these {len(expired_unverified_users)} expired unverified users? (y/n): ").lower().strip()
                    if choice in ['y', 'yes']:
                        self.delete_expired_users(expired_unverified_users)
                        break
                    elif choice in ['n', 'no']:
                        self.stdout.write("No users were deleted.")
                        break
                    else:
                        self.stdout.write("Please enter 'y' or 'n'.")

    def delete_expired_users(self, expired_users):
        """Delete expired unverified users."""
        self.stdout.write(f"\n🗑️  DELETING {len(expired_users)} EXPIRED UNVERIFIED USERS...")
        
        deleted_count = 0
        for user, verification in expired_users:
            try:
                username = user.username
                email = user.email
                user.delete()  # This will also delete the EmailVerification due to CASCADE
                self.stdout.write(f"✅ Deleted: {username} ({email})")
                deleted_count += 1
            except Exception as e:
                self.stdout.write(f"❌ Failed to delete {user.username}: {str(e)}")
        
        self.stdout.write(f"\nSUMMARY: Successfully deleted {deleted_count} out of {len(expired_users)} expired unverified users.") 