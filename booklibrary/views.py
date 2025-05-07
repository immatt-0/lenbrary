import os
import uuid
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile

from rest_framework.decorators import api_view, renderer_classes, parser_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.renderers import JSONRenderer

from .models import Book
from .serializers import BookSerializer


@api_view(['POST'])
@parser_classes([MultiPartParser])
@renderer_classes([JSONRenderer])
def upload_thumbnail(request):
    file = request.FILES.get('thumbnail')
    if not file:
        return Response({'error': 'No file uploaded'}, status=status.HTTP_400_BAD_REQUEST)

    # Generate unique filename
    filename = f"{uuid.uuid4().hex}_{file.name}"
    path = os.path.join('thumbnails', filename)

    # Save file to /media/thumbnails/
    saved_path = default_storage.save(path, ContentFile(file.read()))
    url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)

    return Response({'thumbnail_url': url}, status=status.HTTP_201_CREATED)


@api_view(['GET', 'POST'])
@parser_classes([MultiPartParser, FormParser])
@renderer_classes([JSONRenderer])
def book(request):
    if request.method == 'GET':
        book_id = request.GET.get('id')
        if not book_id:
            return Response({'error': 'Missing ?id='}, status=status.HTTP_400_BAD_REQUEST)
        try:
            book = Book.objects.get(id=book_id)
        except Book.DoesNotExist:
            return Response({'error': 'Book not found'}, status=status.HTTP_404_NOT_FOUND)

        serializer = BookSerializer(book)
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = BookSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
