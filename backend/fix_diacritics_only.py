#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lenbrary_api.settings')
django.setup()

from booklibrary.models import Book

def fix_diacritics_only():
    """Fix only the diacritics in existing Romanian books"""
    
    print("🔧 Fixing diacritics in existing Romanian books...")
    
    # Define the correct mappings
    diacritics_fixes = [
        {
            'old_category': 'Literatura Română',
            'new_category': 'Literatură Română',
            'books': [
                {
                    'name': 'Mara',
                    'author': 'Ioan Slavici',
                    'description': 'Un roman despre dragoste, sacrificiu și drama unei femei în societatea rurală din Transilvania. Mara este simbolul femeii puternice care luptă pentru familia sa.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/9786065880177-2007198-240.jpg'
                },
                {
                    'name': 'Amintiri din Copilărie',
                    'author': 'Ion Creangă',
                    'description': 'Amintirile lui Ion Creangă despre copilăria sa în satul Humulești. O capodoperă a literaturii române care evocă cu umor și nostalgie lumea satului moldovenesc.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/77387815-0.jpeg'
                },
                {
                    'name': 'Ion',
                    'author': 'Liviu Rebreanu',
                    'description': 'Primul mare roman al literaturii române moderne. Povestea lui Ion, un țăran care se căsătorește din interes pentru pământ, dar care este consumat de pasiunea pentru Ana.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/367868268-0.jpeg'
                },
                {
                    'name': 'Moara cu Noroc',
                    'author': 'Ioan Slavici',
                    'description': 'O nuvelă despre corupția și decăderea morală. Ghiță și Ana transformă o moară în cârciumă, dar norocul devine nenorocire prin lăcomie și mită.',
                    'thumbnail_url': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRKNVuDEqgKcq_axG1Ev8yiM3p8a8D1WBlfLA&s'
                },
                {
                    'name': 'Baltagul',
                    'author': 'Mihail Sadoveanu',
                    'description': 'Povestea Vitei Lipan, o femeie care își caută soțul dispărut în munți. Un simbol al dărniciei și puterii feminine în literatura română.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/227230-2627244-240.jpeg'
                },
                {
                    'name': 'Enigma Otiliei',
                    'author': 'George Călinescu',
                    'description': 'Un roman despre burghezia bucureșteană din prima jumătate a secolului XX. Felix Sima se îndrăgostește de enigmatica Otilia Mărculescu.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/1661595-1.jpeg'
                },
                {
                    'name': 'Pădurea Spânzuraților',
                    'author': 'Liviu Rebreanu',
                    'description': 'Un roman despre Primul Război Mondial, văzut prin ochii lui Apostol Bologa, un ofițer austro-ungar de origine română aflat în conflict interior.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/61315-0.jpeg'
                },
                {
                    'name': 'Moromeții',
                    'author': 'Marin Preda',
                    'description': 'Un roman epic despre familia Moromete din Siliștea Gumești. O pictură a satului românesc în perioada interbelică și în primii ani ai comunismului.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/5948486009238-1739843-240.jpg'
                }
            ]
        },
        {
            'old_category': 'Poezie Română',
            'new_category': 'Poezie Română',
            'books': [
                {
                    'name': 'Luceafărul',
                    'author': 'Mihai Eminescu',
                    'description': 'Poemul cel mai cunoscut al lui Eminescu. Povestea dragostei imposibile dintre Luceafărul și Cătălina, o alegorie despre condiția artistului.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/9789738852730-2305892-240.jpg'
                }
            ]
        },
        {
            'old_category': 'Basme Românești',
            'new_category': 'Basme Românești',
            'books': [
                {
                    'name': 'Harap-Alb',
                    'author': 'Ion Creangă',
                    'description': 'Cel mai cunoscut basm al lui Ion Creangă. Povestea unui prinț care trece prin multiple încercări pentru a-și dovedi valoarea.',
                    'thumbnail_url': 'https://cdn.dc5.ro/img-prod/225385-2617217.jpeg'
                }
            ]
        }
    ]
    
    updated_count = 0
    
    for category_data in diacritics_fixes:
        print(f"\n📂 Processing category: {category_data['new_category']}")
        
        for book_info in category_data['books']:
            try:
                # Find the book by name and author
                book = Book.objects.filter(
                    name=book_info['name'],
                    author=book_info['author']
                ).first()
                
                if book:
                    # Update category and description with proper diacritics
                    book.category = category_data['new_category']
                    book.description = book_info['description']
                    
                    # Update thumbnail if provided
                    if 'thumbnail_url' in book_info and book_info['thumbnail_url'] != 'ADD_YOUR_THUMBNAIL_URL_HERE':
                        book.thumbnail_url = book_info['thumbnail_url']
                        print(f"  📸 Updated thumbnail for {book.name}")
                    
                    book.save()
                    
                    print(f"✅ Updated: {book.name} by {book.author}")
                    updated_count += 1
                else:
                    print(f"⚠️  Book not found: {book_info['name']} by {book_info['author']}")
                    
            except Exception as e:
                print(f"❌ Error updating {book_info['name']}: {e}")
    
    print(f"\n🎉 Successfully updated {updated_count} books with proper diacritics!")
    
    # Verify the changes
    print("\n📋 Verification - Current Romanian books:")
    romanian_books = Book.objects.filter(
        category__in=['Literatură Română', 'Poezie Română', 'Basme Românești']
    )
    
    for book in romanian_books:
        print(f"  • {book.name} - {book.category}")
        if book.description and len(book.description) > 50:
            print(f"    Description: {book.description[:50]}...")
    
    return updated_count

if __name__ == '__main__':
    try:
        updated = fix_diacritics_only()
        print(f"\n✅ Process completed! Updated {updated} books.")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
