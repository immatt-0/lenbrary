from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from booklibrary.models import InvitationCode
from django.utils import timezone
from datetime import timedelta


class Command(BaseCommand):
    help = 'Create an invitation code for teacher registration'

    def add_arguments(self, parser):
        parser.add_argument(
            '--admin-username',
            type=str,
            help='Username of the admin creating the code (optional)',
        )

    def handle(self, *args, **options):
        """Create an invitation code for teacher registration."""
        self.stdout.write("=" * 60)
        self.stdout.write("LENBRARY - CREATE INVITATION CODE")
        self.stdout.write("=" * 60)
        self.stdout.write("")
        
        # Check if there's a superuser
        admin_username = options.get('admin_username')
        if admin_username:
            try:
                admin_user = User.objects.get(username=admin_username, is_superuser=True)
            except User.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'❌ ERROR: User "{admin_username}" is not a superuser or does not exist.')
                )
                return
        else:
            admin_user = User.objects.filter(is_superuser=True).first()
            if not admin_user:
                self.stdout.write(
                    self.style.ERROR('❌ ERROR: No superuser found. Please create an admin account first.')
                )
                self.stdout.write('   Run: python manage.py createsuperuser')
                return
        
        try:
            # Create invitation code
            invitation = InvitationCode.objects.create(
                created_by=admin_user,
                expires_at=timezone.now() + timedelta(hours=6)
            )
            invitation.generate_code()
            
            self.stdout.write(self.style.SUCCESS('✅ SUCCESS: Invitation code created!'))
            self.stdout.write("")
            self.stdout.write("📋 CODE DETAILS:")
            self.stdout.write(f"   Code: {invitation.code}")
            self.stdout.write(f"   Created by: {admin_user.username}")
            self.stdout.write(f"   Created at: {invitation.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
            self.stdout.write(f"   Expires at: {invitation.expires_at.strftime('%Y-%m-%d %H:%M:%S')}")
            self.stdout.write("   Status: 🟢 ACTIVE")
            self.stdout.write("")
            self.stdout.write("📝 USAGE:")
            self.stdout.write("   Give this code to a teacher who wants to register.")
            self.stdout.write("   They must use it within 6 hours.")
            self.stdout.write("   The code can only be used once.")
            self.stdout.write("")
            self.stdout.write("⚠️  IMPORTANT:")
            self.stdout.write("   - Keep this code secure")
            self.stdout.write("   - Don't share it publicly")
            self.stdout.write("   - It will expire in 6 hours")
            self.stdout.write("   - It can only be used once")
            self.stdout.write("")
            self.stdout.write("=" * 60)
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ ERROR: Failed to create invitation code')
            )
            self.stdout.write(f'   Error: {str(e)}')
            return 