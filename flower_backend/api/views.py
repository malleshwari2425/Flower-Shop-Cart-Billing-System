from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Flower
from .serializers import FlowerSerializer

@api_view(['GET'])
def get_flowers(request):
    flowers = Flower.objects.all()
    serializer = FlowerSerializer(flowers, many=True)
    return Response(serializer.data)