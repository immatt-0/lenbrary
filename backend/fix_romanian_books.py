#!/usr/bin/env python
import os
import sys
import django
import requests
from PIL import Image
from io import BytesIO
import uuid

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from booklibrary.models import Book
from django.core.files.base import ContentFile

def download_and_save_cover(url, book_name):
    """Download cover image and save it locally"""
    try:
        # Create thumbnails directory if it doesn't exist
        thumbnails_dir = os.path.join(os.path.dirname(__file__), 'media', 'thumbnails')
        os.makedirs(thumbnails_dir, exist_ok=True)
        
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        # Open and process the image
        img = Image.open(BytesIO(response.content))
        
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to standard thumbnail size
        img.thumbnail((300, 400), Image.Resampling.LANCZOS)
        
        # Save the image
        filename = f"{uuid.uuid4().hex}_{book_name.replace(' ', '_')}.jpg"
        filepath = os.path.join(thumbnails_dir, filename)
        img.save(filepath, 'JPEG', quality=85)
        
        return f"thumbnails/{filename}"
    except Exception as e:
        print(f"⚠️  Failed to download cover for {book_name}: {e}")
        return None

def fix_romanian_books():
    """Fix Romanian books with proper covers and diacritics"""
    
    # First, let's delete the existing Romanian books to start fresh
    Book.objects.filter(category__in=['Literatura Română', 'Poezie Română', 'Basme Românești']).delete()
    print("🗑️  Deleted existing Romanian books")
    
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030042_mara-ioan-slavici.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030041_amintiri-din-copilarie-ion-creanga.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030043_ion-liviu-rebreanu.jpg'
        },
        {
            'name': 'Moara cu Noroc',
            'author': 'Ioan Slavici',
            'category': 'Literatura Română',
            'type': 'carte',
            'description': 'O nuvelă despre corupția și decăderea morală. Ghiță și Ana transformă o moară în cârciumă, dar norocul devine nenorocire prin lăcomie și mită.',
            'publication_year': 1881,
            'stock': 4,
            'inventory': 4,
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030044_moara-cu-noroc-ioan-slavici.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030045_baltagul-mihail-sadoveanu.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030046_enigma-otiliei-george-calinescu.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030047_padurea-spanzuratilor-liviu-rebreanu.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030048_morometii-marin-preda.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030049_luceafarul-mihai-eminescu.jpg'
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
            'cover_url': 'https://cdn.libris.ro/userpics/1031/1030050_harap-alb-ion-creanga.jpg'
        }
    ]
    
    created_books = []
    
    for book_data in books:
        print(f"📚 Processing: {book_data['name']} by {book_data['author']}")
        
        # Download and save cover image
        cover_url = book_data.pop('cover_url')
        thumbnail_path = download_and_save_cover(cover_url, book_data['name'])
        
        if thumbnail_path:
            book_data['thumbnail_url'] = thumbnail_path
            print(f"✅ Cover downloaded and saved")
        else:
            print(f"⚠️  Using default cover")
        
        # Create new book
        book = Book.objects.create(**book_data)
        created_books.append(book)
        print(f"✅ Added: '{book.name}' by {book.author}\n")
    
    print(f"🎉 Successfully added {len(created_books)} Romanian books with proper covers!")
    return created_books

if __name__ == '__main__':
    try:
        print("🔧 Installing required packages...")
        os.system("pip install Pillow requests")
        
        print("\n📚 Starting Romanian books setup...")
        books = fix_romanian_books()
        
        print("\n📖 Books added:")
        for book in books:
            print(f"  • {book.name} - {book.author}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
