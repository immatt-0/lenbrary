from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from booklibrary.utils import capitalize_name

class Command(BaseCommand):
    help = 'Capitalize all user first names and last names'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be changed without making changes',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        if dry_run:
            self.stdout.write(self.style.WARNING('DRY RUN MODE - No changes will be made'))
        
        users = User.objects.all()
        updated_count = 0
        
        for user in users:
            original_first_name = user.first_name
            original_last_name = user.last_name
            
            new_first_name = capitalize_name(user.first_name) if user.first_name else ''
            new_last_name = capitalize_name(user.last_name) if user.last_name else ''
            
            if (original_first_name != new_first_name or 
                original_last_name != new_last_name):
                
                self.stdout.write(
                    f"User: {user.username} ({user.email})"
                )
                if original_first_name != new_first_name:
                    self.stdout.write(
                        f"  First name: '{original_first_name}' -> '{new_first_name}'"
                    )
                if original_last_name != new_last_name:
                    self.stdout.write(
                        f"  Last name: '{original_last_name}' -> '{new_last_name}'"
                    )
                
                if not dry_run:
                    user.first_name = new_first_name
                    user.last_name = new_last_name
                    user.save()
                    self.stdout.write(
                        self.style.SUCCESS(f"  ✓ Updated user {user.username}")
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f"  Would update user {user.username}")
                    )
                
                updated_count += 1
        
        if dry_run:
            self.stdout.write(
                self.style.SUCCESS(f'\nDRY RUN: Would update {updated_count} users')
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(f'\nSuccessfully updated {updated_count} users')
            ) 