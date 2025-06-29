#!/usr/bin/env python
import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from booklibrary.models import Book

def test_category_filtering():
    print("Testing category filtering logic...")
    
    # Create test books with different categories
    test_books = [
        {'name': 'Test Book 1', 'author': 'Author 1', 'inventory': 5, 'stock': 3, 'category': 'carti'},
        {'name': 'Test Book 2', 'author': 'Author 2', 'inventory': 3, 'stock': 2, 'category': 'manuale'},
        {'name': 'Test Book 3', 'author': 'Author 3', 'inventory': 4, 'stock': 1, 'category': 'fiction'},
        {'name': 'Test Book 4', 'author': 'Author 4', 'inventory': 2, 'stock': 1, 'category': None},
        {'name': 'Test Book 5', 'author': 'Author 5', 'inventory': 6, 'stock': 4, 'category': ''},
    ]
    
    # Create the books
    for book_data in test_books:
        Book.objects.get_or_create(
            name=book_data['name'],
            defaults=book_data
        )
    
    print("\nAll books:")
    for book in Book.objects.all():
        print(f"- {book.name}: category='{book.category}'")
    
    print("\nBooks for 'carti' category (should exclude 'manuale'):")
    carti_books = Book.objects.exclude(category='manuale')
    for book in carti_books:
        print(f"- {book.name}: category='{book.category}'")
    
    print("\nBooks for 'manuale' category:")
    manuale_books = Book.objects.filter(category='manuale')
    for book in manuale_books:
        print(f"- {book.name}: category='{book.category}'")
    
    print(f"\nSummary:")
    print(f"- Total books: {Book.objects.count()}")
    print(f"- Books in 'carti': {carti_books.count()}")
    print(f"- Books in 'manuale': {manuale_books.count()}")

if __name__ == '__main__':
    test_category_filtering() 