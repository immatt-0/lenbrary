from django.urls import path
from . import views

urlpatterns = [
    path('book', views.book, name='book'),
    path('thumbnails', views.upload_thumbnail, name='upload_thumbnail'),
]
