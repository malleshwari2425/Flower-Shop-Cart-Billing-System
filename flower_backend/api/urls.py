from django.urls import path
from .views import get_flowers

urlpatterns = [
    path('flowers/', get_flowers),
]