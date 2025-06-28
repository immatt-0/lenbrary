#!/usr/bin/env python
"""
Script to clean up expired email verifications and delete unverified accounts.
This script can be run as a scheduled task (cron job) to automatically clean up expired accounts.

Usage:
    python cleanup_expired_accounts.py

For testing (dry run):
    python cleanup_expired_accounts.py --dry-run
"""

import os
import sys
import django
from datetime import timedelta

# Add the backend directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from django.contrib.auth.models import User
from booklibrary.models import EmailVerification
from django.utils import timezone


def cleanup_expired_verifications(dry_run=False):
    """Clean up expired email verifications and delete unverified accounts"""
    
    # Find expired verifications (older than 6 hours)
    expiration_time = timezone.now() - timedelta(hours=6)
    expired_verifications = EmailVerification.objects.filter(
        created_at__lt=expiration_time,
        is_verified=False
    )
    
    if not expired_verifications.exists():
        print('No expired verifications found.')
        return
    
    print(f'Found {expired_verifications.count()} expired verifications:')
    
    deleted_count = 0
    for verification in expired_verifications:
        user = verification.user
        print(f'  - {user.email} (created: {verification.created_at})')
        
        if not dry_run:
            try:
                # Delete the user (this will cascade delete the verification)
                user.delete()
                deleted_count += 1
                print(f'    ✓ Deleted user: {user.email}')
            except Exception as e:
                print(f'    ✗ Error deleting {user.email}: {e}')
        else:
            print(f'    [DRY RUN] Would delete: {user.email}')
    
    if dry_run:
        print(f'\n[DRY RUN] Would delete {expired_verifications.count()} users')
    else:
        print(f'\nSuccessfully deleted {deleted_count} expired unverified accounts.')


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    cleanup_expired_verifications(dry_run) 