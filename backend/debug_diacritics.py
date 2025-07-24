#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys
import django
import json

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from booklibrary.models import Book
from booklibrary.serializers import BookSerializer

def debug_diacritics():
    """Debug diacritics issue in detail"""
    
    print("🔍 Debugging diacritics issue...")
    
    # Get a Romanian book
    book = Book.objects.filter(name='Mara').first()
    
    if book:
        print(f"\n📚 Testing book: {book.name}")
        print(f"Raw category from DB: {repr(book.category)}")
        print(f"Raw description from DB: {repr(book.description[:100])}")
        
        # Test serialization
        serializer = BookSerializer(book)
        serialized_data = serializer.data
        
        print(f"\n📡 Serialized data:")
        print(f"Category: {repr(serialized_data['category'])}")
        print(f"Description: {repr(serialized_data['description'][:100])}")
        
        # Test JSON encoding
        json_data = json.dumps(serialized_data, ensure_ascii=False)
        print(f"\n📄 JSON output (ensure_ascii=False):")
        print(f"Category in JSON: {serialized_data['category']}")
        print(f"Description sample: {serialized_data['description'][:100]}")
        
        # Check if diacritics are actually there
        test_chars = ['ă', 'â', 'î', 'ș', 'ț']
        for char in test_chars:
            if char in book.category or char in book.description:
                print(f"✅ Found diacritic '{char}' in database")
            else:
                print(f"❌ Missing diacritic '{char}' in database")
    
    # Check all Romanian books
    print(f"\n📋 All Romanian books in database:")
    romanian_books = Book.objects.filter(
        category__icontains='român'
    ).values('name', 'category', 'description')
    
    for book in romanian_books:
        print(f"  • {book['name']} - {book['category']}")
        if 'ă' in book['category'] or 'ș' in book['category'] or 'ț' in book['category']:
            print("    ✅ Category has diacritics")
        else:
            print("    ❌ Category missing diacritics")

if __name__ == '__main__':
    debug_diacritics()
