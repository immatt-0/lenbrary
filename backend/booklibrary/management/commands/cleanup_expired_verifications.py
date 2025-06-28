from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from booklibrary.models import EmailVerification
from django.utils import timezone
from datetime import timedelta


class Command(BaseCommand):
    help = 'Clean up expired email verifications and delete unverified accounts'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        # Find expired verifications (older than 6 hours)
        expiration_time = timezone.now() - timedelta(hours=6)
        expired_verifications = EmailVerification.objects.filter(
            created_at__lt=expiration_time,
            is_verified=False
        )
        
        if not expired_verifications.exists():
            self.stdout.write(
                self.style.SUCCESS('No expired verifications found.')
            )
            return
        
        self.stdout.write(
            f'Found {expired_verifications.count()} expired verifications:'
        )
        
        deleted_count = 0
        for verification in expired_verifications:
            user = verification.user
            self.stdout.write(
                f'  - {user.email} (created: {verification.created_at})'
            )
            
            if not dry_run:
                try:
                    # Delete the user (this will cascade delete the verification)
                    user.delete()
                    deleted_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(f'    ✓ Deleted user: {user.email}')
                    )
                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'    ✗ Error deleting {user.email}: {e}')
                    )
            else:
                self.stdout.write(
                    self.style.WARNING(f'    [DRY RUN] Would delete: {user.email}')
                )
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f'\n[DRY RUN] Would delete {expired_verifications.count()} users'
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f'\nSuccessfully deleted {deleted_count} expired unverified accounts.'
                )
            ) 