from django.db import models

class Book(models.Model):
    name = models.CharField(max_length=255)
    inventory = models.IntegerField()
    thumbnail_url = models.CharField(max_length=500, blank=True, null=True)  # ✅ allow null/empty
    author = models.CharField(max_length=255)
    stock = models.IntegerField()

    def __str__(self):
        return self.name
