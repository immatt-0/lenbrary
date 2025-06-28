#!/usr/bin/env python
"""
Test script to verify the invitation code system functionality.
This script tests creating, using, and expiring invitation codes.
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

from django.contrib.auth.models import User, Group
from booklibrary.models import InvitationCode
from django.utils import timezone


def create_test_admin():
    """Create a test admin user"""
    test_email = 'admin@nlenau.ro'
    
    # Delete if exists
    try:
        user = User.objects.get(email=test_email)
        user.delete()
        print(f"Deleted existing test admin: {test_email}")
    except User.DoesNotExist:
        pass
    
    # Create new test admin
    user = User.objects.create_user(
        username='test_admin',
        email=test_email,
        password='adminpass123',
        first_name='Test',
        last_name='Admin',
        is_superuser=True,
        is_staff=True
    )
    
    print(f"Created test admin: {test_email}")
    return user


def create_test_invitation_code(admin_user):
    """Create a test invitation code"""
    invitation = InvitationCode.objects.create(
        created_by=admin_user,
        expires_at=timezone.now() + timedelta(hours=6)
    )
    invitation.generate_code()
    
    print(f"Created invitation code: {invitation.code}")
    print(f"  Expires at: {invitation.expires_at}")
    print(f"  Is valid: {invitation.is_valid()}")
    
    return invitation


def test_invitation_code_functionality():
    """Test the invitation code functionality"""
    
    print("=== Testing Invitation Code System ===\n")
    
    # Create test admin
    admin_user = create_test_admin()
    
    # Test 1: Create invitation code
    print("\n=== Test 1: Creating Invitation Code ===")
    invitation = create_test_invitation_code(admin_user)
    
    # Test 2: Check validity
    print("\n=== Test 2: Checking Validity ===")
    print(f"Code: {invitation.code}")
    print(f"Is valid: {invitation.is_valid()}")
    print(f"Is expired: {invitation.is_expired()}")
    print(f"Is used: {invitation.is_used}")
    
    # Test 3: Use the code
    print("\n=== Test 3: Using Invitation Code ===")
    test_teacher_email = 'teacher@nlenau.ro'
    
    # Create a test teacher user
    try:
        teacher_user = User.objects.get(email=test_teacher_email)
        teacher_user.delete()
        print(f"Deleted existing test teacher: {test_teacher_email}")
    except User.DoesNotExist:
        pass
    
    teacher_user = User.objects.create_user(
        username='test_teacher',
        email=test_teacher_email,
        password='teacherpass123',
        first_name='Test',
        last_name='Teacher'
    )
    
    # Use the invitation code
    invitation.use_code(teacher_user)
    print(f"Used invitation code {invitation.code} for teacher: {test_teacher_email}")
    
    # Test 4: Check code after use
    print("\n=== Test 4: Checking Code After Use ===")
    print(f"Code: {invitation.code}")
    print(f"Is valid: {invitation.is_valid()}")
    print(f"Is used: {invitation.is_used}")
    print(f"Used by: {invitation.used_by.email if invitation.used_by else 'None'}")
    print(f"Used at: {invitation.used_at}")
    
    # Test 5: Try to use the same code again (should fail)
    print("\n=== Test 5: Trying to Use Same Code Again ===")
    try:
        invitation.use_code(teacher_user)
        print("❌ ERROR: Should not be able to use the same code twice!")
    except ValueError as e:
        print(f"✅ SUCCESS: Correctly prevented reuse: {e}")
    
    # Test 6: Create expired invitation code
    print("\n=== Test 6: Creating Expired Invitation Code ===")
    expired_invitation = InvitationCode.objects.create(
        created_by=admin_user,
        expires_at=timezone.now() - timedelta(hours=1)  # Expired 1 hour ago
    )
    expired_invitation.generate_code()
    print(f"Created expired invitation code: {expired_invitation.code}")
    print(f"  Expires at: {expired_invitation.expires_at}")
    print(f"  Is valid: {expired_invitation.is_valid()}")
    print(f"  Is expired: {expired_invitation.is_expired()}")
    
    # Test 7: Try to use expired code (should fail)
    print("\n=== Test 7: Trying to Use Expired Code ===")
    try:
        expired_invitation.use_code(teacher_user)
        print("❌ ERROR: Should not be able to use expired code!")
    except ValueError as e:
        print(f"✅ SUCCESS: Correctly prevented use of expired code: {e}")
    
    # Test 8: Test cleanup command
    print("\n=== Test 8: Testing Cleanup Command ===")
    from booklibrary.management.commands.cleanup_expired_invitations import Command as CleanupCommand
    cleanup_cmd = CleanupCommand()
    cleanup_cmd.handle(dry_run=True)
    
    print("\n=== Test completed successfully ===")
    
    # Clean up test data
    print("\n=== Cleaning up test data ===")
    try:
        admin_user.delete()
        teacher_user.delete()
        print("✅ Test data cleaned up")
    except Exception as e:
        print(f"⚠️  Warning: Could not clean up all test data: {e}")


if __name__ == '__main__':
    test_invitation_code_functionality() 