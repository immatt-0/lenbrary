import os
import subprocess
import sys

def run_server():
    """
    Runs the Django development server with proper settings.
    """
    print("=" * 50)
    print(" LENBRARY BACKEND SERVER")
    print("=" * 50)
    print("\nAvailable credentials for testing:")
    print(" - Librarian: librarian@nlenau.ro / Librarian123")
    print(" - Teacher:   teacher@nlenau.ro / teacher123")
    print(" - Student:   student@nlenau.ro / student123")
    print("\nAPI Endpoints:")
    print(" - Authentication: http://localhost:8000/api/token/")
    print(" - Book Library:   http://localhost:8000/book-library/*")
    print(" - Admin Panel:    http://localhost:8000/admin/")
    print("\nPress Ctrl+C to stop the server")
    print("=" * 50)
    
    # Run Django's manage.py
    try:
        subprocess.call([sys.executable, "manage.py", "runserver", "0.0.0.0:8000"])
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == "__main__":
    # Check if we're in the right directory
    if not os.path.exists("manage.py"):
        print("ERROR: This script must be run from the backend directory!")
        print(f"Current directory: {os.getcwd()}")
        sys.exit(1)
        
    run_server() 