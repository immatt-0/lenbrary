#!/usr/bin/env python
import os
import sys
import django
import requests
from PIL import Image
from io import BytesIO
import uuid
import urllib3

# Disable SSL warnings for development
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from booklibrary.models import Book
from django.core.files.base import ContentFile

def download_and_save_cover(url, book_name, attempt_count=0):
    """Download cover image and save it locally"""
    try:
        # Create thumbnails directory if it doesn't exist
        thumbnails_dir = os.path.join(os.path.dirname(__file__), 'media', 'thumbnails')
        os.makedirs(thumbnails_dir, exist_ok=True)
        
        # Use different sources based on attempt
        if attempt_count == 0:
            # Try with SSL verification disabled
            response = requests.get(url, timeout=15, verify=False)
        else:
            # Try alternative URLs
            return None
            
        response.raise_for_status()
        
        # Open and process the image
        img = Image.open(BytesIO(response.content))
        
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to standard thumbnail size
        img.thumbnail((300, 400), Image.Resampling.LANCZOS)
        
        # Save the image
        filename = f"{uuid.uuid4().hex}_{book_name.replace(' ', '_').replace('ă', 'a').replace('â', 'a').replace('î', 'i').replace('ș', 's').replace('ț', 't')}.jpg"
        filepath = os.path.join(thumbnails_dir, filename)
        img.save(filepath, 'JPEG', quality=85)
        
        return f"thumbnails/{filename}"
    except Exception as e:
        print(f"⚠️  Failed to download cover for {book_name}: {e}")
        if attempt_count < 1:
            return download_and_save_cover(url, book_name, attempt_count + 1)
        return None

def create_default_cover(book_name, author):
    """Create a simple default cover with text"""
    try:
        from PIL import Image, ImageDraw, ImageFont
        
        # Create thumbnails directory if it doesn't exist
        thumbnails_dir = os.path.join(os.path.dirname(__file__), 'media', 'thumbnails')
        os.makedirs(thumbnails_dir, exist_ok=True)
        
        # Create a simple colored background
        img = Image.new('RGB', (300, 400), color=(52, 73, 94))  # Dark blue-gray
        draw = ImageDraw.Draw(img)
        
        # Try to use a system font
        try:
            font_title = ImageFont.truetype("arial.ttf", 24)
            font_author = ImageFont.truetype("arial.ttf", 18)
        except:
            font_title = ImageFont.load_default()
            font_author = ImageFont.load_default()
        
        # Add title and author text
        title_lines = []
        words = book_name.split(' ')
        current_line = ""
        for word in words:
            if len(current_line + word) < 20:
                current_line += word + " "
            else:
                title_lines.append(current_line.strip())
                current_line = word + " "
        if current_line:
            title_lines.append(current_line.strip())
        
        # Draw title
        y_offset = 150
        for line in title_lines:
            bbox = draw.textbbox((0, 0), line, font=font_title)
            text_width = bbox[2] - bbox[0]
            x = (300 - text_width) // 2
            draw.text((x, y_offset), line, fill=(255, 255, 255), font=font_title)
            y_offset += 30
        
        # Draw author
        bbox = draw.textbbox((0, 0), author, font=font_author)
        text_width = bbox[2] - bbox[0]
        x = (300 - text_width) // 2
        draw.text((x, y_offset + 20), author, fill=(189, 195, 199), font=font_author)
        
        # Save the image
        filename = f"default_{uuid.uuid4().hex}_{book_name.replace(' ', '_').replace('ă', 'a').replace('â', 'a').replace('î', 'i').replace('ș', 's').replace('ț', 't')}.jpg"
        filepath = os.path.join(thumbnails_dir, filename)
        img.save(filepath, 'JPEG', quality=85)
        
        return f"thumbnails/{filename}"
    except Exception as e:
        print(f"⚠️  Failed to create default cover: {e}")
        return None

def fix_romanian_books_final():
    """Fix Romanian books with better covers and perfect diacritics"""
    
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
            'cover_urls': [
                'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Mara_-_Ioan_Slavici.jpg/256px-Mara_-_Ioan_Slavici.jpg',
                'https://www.historia.ro/sites/default/files/styles/historia_articol_imagine_principala/public/2019-04/mara_slavici.jpg'
            ]
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
            'cover_urls': [
                'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Amintiri_din_copilarie.jpg/256px-Amintiri_din_copilarie.jpg'
            ]
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
            'cover_urls': [
                'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Ion_-_Liviu_Rebreanu.jpg/256px-Ion_-_Liviu_Rebreanu.jpg'
            ]
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
            'cover_urls': []
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
            'cover_urls': []
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
            'cover_urls': []
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
            'cover_urls': []
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
            'cover_urls': []
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
            'cover_urls': [
                'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Luceafarul_-_Mihai_Eminescu.jpg/256px-Luceafarul_-_Mihai_Eminescu.jpg'
            ]
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
            'cover_urls': []
        }
    ]
    
    created_books = []
    
    for book_data in books:
        print(f"📚 Processing: {book_data['name']} by {book_data['author']}")
        
        # Try to download cover images
        cover_urls = book_data.pop('cover_urls', [])
        thumbnail_path = None
        
        for url in cover_urls:
            thumbnail_path = download_and_save_cover(url, book_data['name'])
            if thumbnail_path:
                print(f"✅ Cover downloaded from: {url}")
                break
        
        # If no cover downloaded, create a default one
        if not thumbnail_path:
            thumbnail_path = create_default_cover(book_data['name'], book_data['author'])
            if thumbnail_path:
                print(f"✅ Created default cover")
        
        if thumbnail_path:
            book_data['thumbnail_url'] = thumbnail_path
        
        # Create new book
        book = Book.objects.create(**book_data)
        created_books.append(book)
        print(f"✅ Added: '{book.name}' by {book.author}\n")
    
    print(f"🎉 Successfully added {len(created_books)} Romanian books!")
    return created_books

if __name__ == '__main__':
    try:
        print("🔧 Installing required packages...")
        os.system("pip install Pillow requests")
        
        print("\n📚 Starting Romanian books final setup...")
        books = fix_romanian_books_final()
        
        print("\n📖 Books added with proper diacritics:")
        for book in books:
            print(f"  • {book.name} - {book.author}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
