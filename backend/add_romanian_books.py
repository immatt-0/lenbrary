#!/usr/bin/env python
import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from booklibrary.models import Book

def add_romanian_books():
    """Add popular Romanian classic books to the database"""
    
    books = [
        {
            'name': 'Mara',
            'author': 'Ioan Slavici',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Un roman despre dragoste, sacrificiu și drama unei femei în societatea rurală din Transilvania. Mara este simbolul femeii puternice care luptă pentru familia sa.',
            'publication_year': 1906,
            'stock': 5,
            'inventory': 5,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51wQJ9Z6KBL._SX323_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Amintiri din Copilărie',
            'author': 'Ion Creangă',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Amintirile lui Ion Creangă despre copilăria sa în satul Humulești. O capodoperă a literaturii române care evocă cu umor și nostalgie lumea satului moldovenesc.',
            'publication_year': 1881,
            'stock': 4,
            'inventory': 4,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/41xK0Z9rKfL._SX333_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Ion',
            'author': 'Liviu Rebreanu',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Primul mare roman al literaturii române moderne. Povestea lui Ion, un țăran care se căsătorește din interes pentru pământ, dar care este consumat de pasiunea pentru Ana.',
            'publication_year': 1920,
            'stock': 3,
            'inventory': 3,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51tYKZ2QPBL._SX348_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Moara cu Noroc',
            'author': 'Ioan Slavici',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'O nuvelă despre corupția și decăderea morală. Ghiță și Ana transformă o moară în cîrciumă, dar norocul devine nenorocire prin lăcomie și mita.',
            'publication_year': 1881,
            'stock': 4,
            'inventory': 4,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51xZ8Q9rKBL._SX331_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Baltagul',
            'author': 'Mihail Sadoveanu',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Povestea Vitei Lipan, o femeie care își caută soțul dispărut în munți. Un simbol al dărniciei și puterii feminine în literatura română.',
            'publication_year': 1930,
            'stock': 3,
            'inventory': 3,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51GKZ2Q9rKBL._SX348_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Enigma Otiliei',
            'author': 'George Călinescu',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Un roman despre burghezia bucureșteană din prima jumătate a secolului XX. Felix Sima se îndrăgostește de enigmatica Otilia Mărculescu.',
            'publication_year': 1938,
            'stock': 2,
            'inventory': 2,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/41KZ9Q2QPBL._SX348_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Pădurea Spânzuraților',
            'author': 'Liviu Rebreanu',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Un roman despre Primul Război Mondial, văzut prin ochii lui Apostol Bologa, un ofițer austro-ungar de origine română aflat în conflict interior.',
            'publication_year': 1922,
            'stock': 3,
            'inventory': 3,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51HKZ3Q9rKBL._SX348_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Moromeții',
            'author': 'Marin Preda',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'Un roman epic despre familia Moromete din Siliștea Gumești. O pictură a satului românesc în perioada interbelică și în primii ani ai comunismului.',
            'publication_year': 1955,
            'stock': 4,
            'inventory': 4,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51PKZ4Q9rKBL._SX348_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Luceafărul',
            'author': 'Mihai Eminescu',
            'category': 'Poezie Română',
            'type': 'carte',
            'description': 'Poemul cel mai cunoscut al lui Eminescu. Povestea dragostei imposibile dintre Luceafărul și Cătălina, o alegorie despre condiția artistului.',
            'publication_year': 1883,
            'stock': 5,
            'inventory': 5,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/41QKZ5Q9rKBL._SX348_BO1,204,203,200_.jpg'
        },
        {
            'name': 'Harap-Alb',
            'author': 'Ion Creangă',
            'category': 'Basme Românești',
            'type': 'carte',
            'description': 'Cel mai cunoscut basm al lui Ion Creangă. Povestea unui prinț care trece prin multiple încercări pentru a-și dovedi valoarea.',
            'publication_year': 1877,
            'stock': 6,
            'inventory': 6,
            'thumbnail_url': 'https://images-na.ssl-images-amazon.com/images/I/51RKZ6Q9rKBL._SX348_BO1,204,203,200_.jpg'
        }
    ]
    
    created_books = []
    
    for book_data in books:
        # Check if book already exists
        existing_book = Book.objects.filter(
            name=book_data['name'], 
            author=book_data['author']
        ).first()
        
        if existing_book:
            print(f"Book '{book_data['name']}' by {book_data['author']} already exists. Skipping...")
            continue
        
        # Create new book
        book = Book.objects.create(**book_data)
        created_books.append(book)
        print(f"✅ Added: '{book.name}' by {book.author}")
    
    print(f"\n🎉 Successfully added {len(created_books)} Romanian books to the library!")
    return created_books

if __name__ == '__main__':
    try:
        books = add_romanian_books()
        print("\n📚 Books added:")
        for book in books:
            print(f"  • {book.name} - {book.author}")
    except Exception as e:
        print(f"❌ Error adding books: {e}")
