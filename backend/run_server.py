#!/usr/bin/env python
"""
Simple script to run the Django development server
"""
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from django.core.management import execute_from_command_line

if __name__ == '__main__':
    print("Starting Lenbrary Development Server...")
    print("Server will be available at:")
    print(" - Main site: http://localhost:8000/")
    print(" - Admin panel: http://localhost:8000/admin/")
    print(" - API: http://localhost:8000/api/")
    print(" - Authentication: http://localhost:8000/api/token/")
    print("\nPress Ctrl+C to stop the server.")
    print("\nNote: Create admin accounts using 'python manage.py createsuperuser'")
    
    try:
        execute_from_command_line(['manage.py', 'runserver', '192.168.68.111:8000'])
    except KeyboardInterrupt:
        print("\nServer stopped.") 