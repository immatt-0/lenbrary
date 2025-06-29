from django.core.management.base import BaseCommand
from booklibrary.models import Book

class Command(BaseCommand):
    help = 'Fixes pdf_file and thumbnail_url paths for books'

    def handle(self, *args, **options):
        for book in Book.objects.all():
            changed = False
            # Fix PDF (FileField)
            if book.pdf_file and ('http:' in book.pdf_file.name or 'https:' in book.pdf_file.name or '\\' in book.pdf_file.name):
                # Extrage doar partea după /media/ sau books/
                if '/media/' in book.pdf_file.name:
                    book.pdf_file.name = book.pdf_file.name.split('/media/')[-1]
                    changed = True
                elif 'books/' in book.pdf_file.name:
                    idx = book.pdf_file.name.find('books/')
                    book.pdf_file.name = book.pdf_file.name[idx:]
                    changed = True
            # Fix thumbnail_url (CharField)
            if book.thumbnail_url and ('http:' in book.thumbnail_url or 'https:' in book.thumbnail_url or '\\' in book.thumbnail_url):
                if '/media/' in book.thumbnail_url:
                    book.thumbnail_url = book.thumbnail_url.split('/media/')[-1]
                    changed = True
                elif 'books/' in book.thumbnail_url:
                    idx = book.thumbnail_url.find('books/')
                    book.thumbnail_url = book.thumbnail_url[idx:]
                    changed = True
            if changed:
                book.save()
                print(f'Fixed book: {book.name}')
        print('Done fixing book paths.')