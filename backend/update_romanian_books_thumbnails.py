#!/usr/bin/env python
# -*- coding: utf-8 -*-
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

def download_and_save_thumbnail(url, book_name):
    """Download thumbnail and save it locally"""
    try:
        # Create thumbnails directory if it doesn't exist
        thumbnails_dir = os.path.join(os.path.dirname(__file__), 'media', 'thumbnails')
        os.makedirs(thumbnails_dir, exist_ok=True)
        
        # Add user agent to avoid 403 errors
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(url, timeout=15, headers=headers, verify=False)
        response.raise_for_status()
        
        # Open and process the image
        img = Image.open(BytesIO(response.content))
        
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to standard thumbnail size (maintaining aspect ratio)
        img.thumbnail((300, 400), Image.Resampling.LANCZOS)
        
        # Clean filename for Windows compatibility
        clean_name = book_name.replace(' ', '_').replace('ă', 'a').replace('â', 'a').replace('î', 'i').replace('ș', 's').replace('ț', 't')
        filename = f"{uuid.uuid4().hex}_{clean_name}.jpg"
        filepath = os.path.join(thumbnails_dir, filename)
        
        # Save as JPEG with good quality
        img.save(filepath, 'JPEG', quality=85, optimize=True)
        
        return f"thumbnails/{filename}"
        
    except Exception as e:
        print(f"⚠️  Failed to download thumbnail for {book_name}: {e}")
        return None

def update_romanian_books_with_thumbnails():
    """Update Romanian books with proper thumbnails and diacritics"""
    
    print("🔧 Updating Romanian books with thumbnails and diacritics...")
    
    # Romanian books with their thumbnail URLs
    books_data = [
        {
            'name': 'Mara',
            'author': 'Ioan Slavici',
            'category': 'Literatură Română',
            'description': 'Un roman despre dragoste, sacrificiu și drama unei femei în societatea rurală din Transilvania. Mara este simbolul femeii puternice care luptă pentru familia sa.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030042.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/editura-litera-international-mara-4006.jpg',
                'https://nemira.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/m/a/mara_original.jpg.webp'
            ]
        },
        {
            'name': 'Amintiri din Copilărie',
            'author': 'Ion Creangă',
            'category': 'Literatură Română',
            'description': 'Amintirile lui Ion Creangă despre copilăria sa în satul Humulești. O capodoperă a literaturii române care evocă cu umor și nostalgie lumea satului moldovenesc.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030041.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/amintiri-din-copilarie-5411.jpg',
                'https://humanitas.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/4/1/41fwqklb-ml._sx195_.jpg.webp'
            ]
        },
        {
            'name': 'Ion',
            'author': 'Liviu Rebreanu',
            'category': 'Literatură Română',
            'description': 'Primul mare roman al literaturii române moderne. Povestea lui Ion, un țăran care se căsătorește din interes pentru pământ, dar care este consumat de pasiunea pentru Ana.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030043.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/ion-4078.jpg',
                'https://humanitas.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/i/o/ion_rebreanu.jpg.webp'
            ]
        },
        {
            'name': 'Moara cu Noroc',
            'author': 'Ioan Slavici',
            'category': 'Literatură Română',
            'description': 'O nuvelă despre corupția și decăderea morală. Ghiță și Ana transformă o moară în cârciumă, dar norocul devine nenorocire prin lăcomie și mită.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030044.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/moara-cu-noroc-4006.jpg'
            ]
        },
        {
            'name': 'Baltagul',
            'author': 'Mihail Sadoveanu',
            'category': 'Literatură Română',
            'description': 'Povestea Vitei Lipan, o femeie care își caută soțul dispărut în munți. Un simbol al dărniciei și puterii feminine în literatura română.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030045.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/baltagul-4006.jpg',
                'https://humanitas.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/b/a/baltagul.jpg.webp'
            ]
        },
        {
            'name': 'Enigma Otiliei',
            'author': 'George Călinescu',
            'category': 'Literatură Română',
            'description': 'Un roman despre burghezia bucureșteană din prima jumătate a secolului XX. Felix Sima se îndrăgostește de enigmatica Otilia Mărculescu.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030046.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/enigma-otiliei-4006.jpg'
            ]
        },
        {
            'name': 'Pădurea Spânzuraților',
            'author': 'Liviu Rebreanu',
            'category': 'Literatură Română',
            'description': 'Un roman despre Primul Război Mondial, văzut prin ochii lui Apostol Bologa, un ofițer austro-ungar de origine română aflat în conflict interior.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030047.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/padurea-spanzuratilor-4006.jpg'
            ]
        },
        {
            'name': 'Moromeții',
            'author': 'Marin Preda',
            'category': 'Literatură Română',
            'description': 'Un roman epic despre familia Moromete din Siliștea Gumești. O pictură a satului românesc în perioada interbelică și în primii ani ai comunismului.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030048.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/morometii-4006.jpg',
                'https://humanitas.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/m/o/morometii.jpg.webp'
            ]
        },
        {
            'name': 'Luceafărul',
            'author': 'Mihai Eminescu',
            'category': 'Poezie Română',
            'description': 'Poemul cel mai cunoscut al lui Eminescu. Povestea dragostei imposibile dintre Luceafărul și Cătălina, o alegorie despre condiția artistului.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030049.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/luceafarul-4006.jpg',
                'https://humanitas.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/l/u/luceafarul.jpg.webp'
            ]
        },
        {
            'name': 'Harap-Alb',
            'author': 'Ion Creangă',
            'category': 'Basme Românești',
            'description': 'Cel mai cunoscut basm al lui Ion Creangă. Povestea unui prinț care trece prin multiple încercări pentru a-și dovedi valoarea.',
            'thumbnail_urls': [
                'https://www.libris.ro/covers/500/1030050.jpg',
                'https://carturesti.ro/files/carte_img/xxlrg/harap-alb-4006.jpg',
                'https://humanitas.ro/media/amasty/webp/catalog/product/cache/4c67e0d8e0c5b7fd0c99b6c7e7f5ee31/h/a/harap_alb.jpg.webp'
            ]
        }
    ]
    
    updated_count = 0
    
    for book_data in books_data:
        print(f"\n📚 Processing: {book_data['name']} by {book_data['author']}")
        
        # Find the book in database
        book = Book.objects.filter(
            name=book_data['name'],
            author=book_data['author']
        ).first()
        
        if not book:
            print(f"⚠️  Book not found: {book_data['name']}")
            continue
        
        # Try to download thumbnail from available URLs
        thumbnail_path = None
        for url in book_data['thumbnail_urls']:
            print(f"  🔗 Trying URL: {url}")
            thumbnail_path = download_and_save_thumbnail(url, book_data['name'])
            if thumbnail_path:
                print(f"  ✅ Successfully downloaded thumbnail")
                break
            else:
                print(f"  ❌ Failed to download from this URL")
        
        # Update book data
        try:
            book.category = book_data['category']
            book.description = book_data['description']
            
            if thumbnail_path:
                book.thumbnail_url = thumbnail_path
                print(f"  ✅ Updated thumbnail")
            
            book.save()
            print(f"✅ Updated: {book.name} by {book.author}")
            updated_count += 1
            
        except Exception as e:
            print(f"❌ Error updating {book_data['name']}: {e}")
    
    print(f"\n🎉 Successfully updated {updated_count} books!")
    
    # Verification
    print("\n📋 Verification - Updated Romanian books:")
    romanian_books = Book.objects.filter(
        category__in=['Literatură Română', 'Poezie Română', 'Basme Românești']
    )
    
    for book in romanian_books:
        thumbnail_status = "✅ Has thumbnail" if book.thumbnail_url else "❌ No thumbnail"
        print(f"  • {book.name} - {book.category} - {thumbnail_status}")
    
    return updated_count

if __name__ == '__main__':
    try:
        print("🔧 Installing required packages...")
        os.system("pip install Pillow requests")
        
        print("\n📚 Starting Romanian books update...")
        updated = update_romanian_books_with_thumbnails()
        print(f"\n✅ Process completed! Updated {updated} books.")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
