from django.db import models

class Flower(models.Model):
    name = models.CharField(max_length=100)
    price = models.FloatField()
    image = models.URLField()

    def __str__(self):
        return self.name