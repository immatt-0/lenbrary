import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from django.contrib.auth.models import User, Group, Permission
from django.contrib.contenttypes.models import ContentType
from django.contrib.admin.models import LogEntry
from django.db import connection
import sqlite3

def find_user_relations():
    user_ids = [2, 3]  # test and Sergiu users
    
    # Check for admin log entries
    log_entries = LogEntry.objects.filter(user_id__in=user_ids)
    print(f"Admin Log Entries: {log_entries.count()}")
    for entry in log_entries:
        print(f"  Log entry ID: {entry.id} for user_id: {entry.user_id}")
    
    # Check user permissions
    for user_id in user_ids:
        try:
            user = User.objects.get(id=user_id)
            print(f"\nUser permissions for {user.username}:")
            user_perms = user.user_permissions.all()
            print(f"  Direct permissions: {user_perms.count()}")
            for perm in user_perms:
                print(f"  - {perm.codename}")
            
            # Check group memberships
            groups = user.groups.all()
            print(f"  Groups: {groups.count()}")
            for group in groups:
                print(f"  - {group.name}")
        except User.DoesNotExist:
            print(f"User with ID {user_id} not found")
    
    # List all database tables
    print("\nChecking all database tables for references to user IDs 2 and 3...")
    
    # Get database path
    db_path = os.path.join(os.getcwd(), 'db.sqlite3')
    print(f"Database path: {db_path}")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    
    for table in tables:
        table_name = table[0]
        print(f"\nChecking table: {table_name}")
        
        # Get column names
        cursor.execute(f"PRAGMA table_info({table_name})")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        # Look for user_id or anything with _user_id
        user_id_columns = [col for col in column_names if col == 'user_id' or col.endswith('_user_id')]
        if user_id_columns:
            print(f"  Found potential user ID columns: {user_id_columns}")
            
            for col in user_id_columns:
                try:
                    # Check for references to our target users
                    cursor.execute(f"SELECT * FROM {table_name} WHERE {col} IN (2, 3)")
                    rows = cursor.fetchall()
                    
                    if rows:
                        print(f"  ⚠️ Found {len(rows)} rows in {table_name} with {col} referencing users 2 or 3")
                        
                        # Show columns
                        print(f"  Columns: {column_names}")
                        
                        # Show data
                        for row in rows:
                            print(f"    Row: {row}")
                except Exception as e:
                    print(f"  Error querying {table_name}.{col}: {str(e)}")
    
    # Check specifically for auth_user_groups
    cursor.execute("SELECT * FROM auth_user_groups WHERE user_id IN (2, 3)")
    rows = cursor.fetchall()
    if rows:
        print("\nUser-Group relationships:")
        for row in rows:
            print(f"  User ID: {row[1]}, Group ID: {row[2]}")
    
    # Check for user permissions
    cursor.execute("SELECT * FROM auth_user_user_permissions WHERE user_id IN (2, 3)")
    rows = cursor.fetchall()
    if rows:
        print("\nUser-Permission relationships:")
        for row in rows:
            print(f"  User ID: {row[1]}, Permission ID: {row[2]}")
    
    conn.close()

if __name__ == "__main__":
    find_user_relations() 