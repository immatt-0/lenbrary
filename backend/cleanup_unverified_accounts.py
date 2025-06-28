#!/usr/bin/env python
"""
Script to delete all unverified user accounts and their associated data.
This will remove users who haven't verified their email addresses.
"""

import os
import sys
import django
from datetime import timedelta

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from django.contrib.auth.models import User
from django.utils import timezone
from booklibrary.models import EmailVerification, Student, BookBorrowing, Message, Notification

def cleanup_unverified_accounts():
    """Delete all unverified user accounts and their associated data"""
    
    print("Starting cleanup of unverified accounts...")
    
    # Get all unverified users
    unverified_users = User.objects.filter(
        email_verification__is_verified=False
    ).distinct()
    
    print(f"Found {unverified_users.count()} unverified users")
    
    if unverified_users.count() == 0:
        print("No unverified accounts found.")
        return
    
    # Show details of users to be deleted
    print("\nUsers to be deleted:")
    for user in unverified_users:
        print(f"  - {user.username} ({user.email}) - Created: {user.date_joined}")
    
    # Confirm deletion
    response = input(f"\nAre you sure you want to delete {unverified_users.count()} unverified accounts? (yes/no): ")
    if response.lower() != 'yes':
        print("Operation cancelled.")
        return
    
    deleted_count = 0
    
    for user in unverified_users:
        try:
            print(f"Deleting user: {user.username} ({user.email})")
            
            # Delete associated data first
            # Delete messages
            Message.objects.filter(sender=user).delete()
            Message.objects.filter(recipient=user).delete()
            
            # Delete notifications
            Notification.objects.filter(user=user).delete()
            Notification.objects.filter(created_by=user).delete()
            
            # Delete borrowings (this will cascade to related records)
            if hasattr(user, 'student'):
                BookBorrowing.objects.filter(student=user.student).delete()
                user.student.delete()
            
            # Delete email verification
            if hasattr(user, 'email_verification'):
                user.email_verification.delete()
            
            # Delete invitation codes created by this user
            from booklibrary.models import InvitationCode
            InvitationCode.objects.filter(created_by=user).delete()
            
            # Finally delete the user
            user.delete()
            deleted_count += 1
            print(f"  ✓ Successfully deleted {user.username}")
            
        except Exception as e:
            print(f"  ✗ Error deleting {user.username}: {e}")
    
    print(f"\nCleanup completed! Deleted {deleted_count} unverified accounts.")
    
    # Show remaining users
    remaining_users = User.objects.all()
    print(f"\nRemaining users: {remaining_users.count()}")
    for user in remaining_users:
        verification_status = "Verified" if hasattr(user, 'email_verification') and user.email_verification.is_verified else "Unverified"
        print(f"  - {user.username} ({user.email}) - {verification_status}")

def cleanup_expired_unverified_accounts():
    """Delete only expired unverified accounts (older than 6 hours)"""
    
    print("Starting cleanup of expired unverified accounts...")
    
    # Calculate expiration time (6 hours ago)
    expiration_time = timezone.now() - timedelta(hours=6)
    
    # Get expired unverified users
    expired_users = User.objects.filter(
        email_verification__is_verified=False,
        email_verification__created_at__lt=expiration_time
    ).distinct()
    
    print(f"Found {expired_users.count()} expired unverified users")
    
    if expired_users.count() == 0:
        print("No expired unverified accounts found.")
        return
    
    # Show details of users to be deleted
    print("\nExpired users to be deleted:")
    for user in expired_users:
        print(f"  - {user.username} ({user.email}) - Created: {user.email_verification.created_at}")
    
    # Confirm deletion
    response = input(f"\nAre you sure you want to delete {expired_users.count()} expired unverified accounts? (yes/no): ")
    if response.lower() != 'yes':
        print("Operation cancelled.")
        return
    
    deleted_count = 0
    
    for user in expired_users:
        try:
            print(f"Deleting expired user: {user.username} ({user.email})")
            
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
            
            from booklibrary.models import InvitationCode
            InvitationCode.objects.filter(created_by=user).delete()
            
            user.delete()
            deleted_count += 1
            print(f"  ✓ Successfully deleted {user.username}")
            
        except Exception as e:
            print(f"  ✗ Error deleting {user.username}: {e}")
    
    print(f"\nCleanup completed! Deleted {deleted_count} expired unverified accounts.")

if __name__ == "__main__":
    print("Unverified Account Cleanup Script")
    print("=" * 40)
    print("1. Delete ALL unverified accounts")
    print("2. Delete only EXPIRED unverified accounts (older than 6 hours)")
    print("3. Show statistics only")
    
    choice = input("\nChoose an option (1/2/3): ").strip()
    
    if choice == "1":
        cleanup_unverified_accounts()
    elif choice == "2":
        cleanup_expired_unverified_accounts()
    elif choice == "3":
        # Show statistics
        total_users = User.objects.count()
        verified_users = User.objects.filter(email_verification__is_verified=True).count()
        unverified_users = User.objects.filter(email_verification__is_verified=False).count()
        expired_users = User.objects.filter(
            email_verification__is_verified=False,
            email_verification__created_at__lt=timezone.now() - timedelta(hours=6)
        ).count()
        
        print(f"\nAccount Statistics:")
        print(f"Total users: {total_users}")
        print(f"Verified users: {verified_users}")
        print(f"Unverified users: {unverified_users}")
        print(f"Expired unverified users: {expired_users}")
    else:
        print("Invalid choice. Exiting.") 