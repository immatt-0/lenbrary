from django.core.management.base import BaseCommand
from booklibrary.models import InvitationCode
from django.utils import timezone


class Command(BaseCommand):
    help = 'Clean up expired invitation codes'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        # Find expired invitation codes
        expired_invitations = InvitationCode.objects.filter(expires_at__lt=timezone.now())
        
        if not expired_invitations.exists():
            self.stdout.write(
                self.style.SUCCESS('No expired invitation codes found.')
            )
            return
        
        self.stdout.write(
            f'Found {expired_invitations.count()} expired invitation codes:'
        )
        
        deleted_count = 0
        for invitation in expired_invitations:
            self.stdout.write(
                f'  - {invitation.code} (created: {invitation.created_at}, expires: {invitation.expires_at})'
            )
            
            if not dry_run:
                try:
                    invitation.delete()
                    deleted_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(f'    ✓ Deleted invitation code: {invitation.code}')
                    )
                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'    ✗ Error deleting {invitation.code}: {e}')
                    )
            else:
                self.stdout.write(
                    self.style.WARNING(f'    [DRY RUN] Would delete: {invitation.code}')
                )
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f'\n[DRY RUN] Would delete {expired_invitations.count()} invitation codes'
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f'\nSuccessfully deleted {deleted_count} expired invitation codes.'
                )
            ) 