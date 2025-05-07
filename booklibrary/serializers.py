from rest_framework import serializers
from .models import Book

class BookSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)  # ✅ make it writable (but optional)

    class Meta:
        model = Book
        fields = ['id', 'name', 'inventory', 'thumbnail_url', 'author', 'stock']
