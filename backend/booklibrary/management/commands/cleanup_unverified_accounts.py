from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from booklibrary.models import EmailVerification, Student, BookBorrowing, Message, Notification, InvitationCode


class Command(BaseCommand):
    help = 'Delete unverified user accounts and their associated data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--expired-only',
            action='store_true',
            help='Delete only expired unverified accounts (older than 6 hours)',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Skip confirmation prompt',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        expired_only = options['expired_only']
        force = options['force']
        dry_run = options['dry_run']

        if expired_only:
            self.stdout.write("Looking for expired unverified accounts...")
            expiration_time = timezone.now() - timedelta(hours=6)
            users_to_delete = User.objects.filter(
                email_verification__is_verified=False,
                email_verification__created_at__lt=expiration_time
            ).distinct()
        else:
            self.stdout.write("Looking for all unverified accounts...")
            users_to_delete = User.objects.filter(
                email_verification__is_verified=False
            ).distinct()

        count = users_to_delete.count()
        
        if count == 0:
            self.stdout.write(
                self.style.SUCCESS('No unverified accounts found.')
            )
            return

        # Show statistics
        total_users = User.objects.count()
        verified_users = User.objects.filter(email_verification__is_verified=True).count()
        unverified_users = User.objects.filter(email_verification__is_verified=False).count()
        
        self.stdout.write(f"\nAccount Statistics:")
        self.stdout.write(f"Total users: {total_users}")
        self.stdout.write(f"Verified users: {verified_users}")
        self.stdout.write(f"Unverified users: {unverified_users}")
        self.stdout.write(f"Accounts to delete: {count}")

        # Show users to be deleted
        self.stdout.write(f"\nUsers to be deleted:")
        for user in users_to_delete:
            status = f"Expired ({user.email_verification.created_at})" if expired_only else "Unverified"
            self.stdout.write(f"  - {user.username} ({user.email}) - {status}")

        if dry_run:
            self.stdout.write(
                self.style.WARNING(f'\nDRY RUN: Would delete {count} accounts')
            )
            return

        # Confirm deletion
        if not force:
            confirm = input(f"\nAre you sure you want to delete {count} accounts? (yes/no): ")
            if confirm.lower() != 'yes':
                self.stdout.write('Operation cancelled.')
                return

        deleted_count = 0
        errors = []

        for user in users_to_delete:
            try:
                self.stdout.write(f"Deleting user: {user.username} ({user.email})")
                
                # Delete associated data first
                Message.objects.filter(sender=user).delete()
                Message.objects.filter(recipient=user).delete()
                Notification.objects.filter(user=user).delete()
                Notification.objects.filter(created_by=user).delete()
                
                if hasattr(user, 'student'):
                    BookBorrowing.objects.filter(student=user.student).delete()
                    user.student.delete()
                
                if hasattr(user, 'email_verification'):
                    user.email_verification.delete()
                
                InvitationCode.objects.filter(created_by=user).delete()
                
                user.delete()
                deleted_count += 1
                self.stdout.write(f"  ✓ Successfully deleted {user.username}")
                
            except Exception as e:
                error_msg = f"Error deleting {user.username}: {e}"
                errors.append(error_msg)
                self.stdout.write(f"  ✗ {error_msg}")

        # Summary
        self.stdout.write(f"\nCleanup completed!")
        self.stdout.write(f"Successfully deleted: {deleted_count} accounts")
        
        if errors:
            self.stdout.write(f"Errors: {len(errors)}")
            for error in errors:
                self.stdout.write(f"  - {error}")

        # Show remaining users
        remaining_users = User.objects.all()
        self.stdout.write(f"\nRemaining users: {remaining_users.count()}")
        for user in remaining_users:
            verification_status = "Verified" if hasattr(user, 'email_verification') and user.email_verification.is_verified else "Unverified"
            self.stdout.write(f"  - {user.username} ({user.email}) - {verification_status}") 