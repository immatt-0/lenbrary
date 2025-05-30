"""
Common utility functions for management scripts.
"""
import os
import django
from pathlib import Path

def setup_django():
    """Set up Django environment for scripts."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
    django.setup()

def get_base_dir():
    """Get the base directory of the project."""
    return Path(__file__).resolve().parent.parent

def create_or_get_group(group_name):
    """Create or get a user group."""
    from django.contrib.auth.models import Group
    group, _ = Group.objects.get_or_create(name=group_name)
    return group

def confirm_action(message, confirmation_word="YES"):
    """Get user confirmation for a potentially dangerous action."""
    print(f"\n⚠️  {message}")
    confirm = input(f"Type '{confirmation_word}' to confirm: ")
    return confirm == confirmation_word

def backup_file(file_path):
    """Create a timestamped backup of a file."""
    import shutil
    import time
    
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_{timestamp}"
    shutil.copy2(file_path, backup_path)
    return backup_path 