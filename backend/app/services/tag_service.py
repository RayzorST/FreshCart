# app/services/tag_service.py
from sqlalchemy.orm import Session
from typing import List, Dict
from app.models.product import Product, ProductTag
from app.models.favorite import Favorite

class TagService:
    def __init__(self, db: Session):
        self.db = db

    def get_products_by_tag(self, tag: str, user_id: int, only_favorites: bool = False) -> List[Dict]:
        """Поиск товаров по тегу с учетом избранного"""
        query = self.db.query(Product).join(ProductTag).filter(ProductTag.tag == tag)
        
        if only_favorites:
            query = query.join(Favorite).filter(
                Favorite.user_id == user_id,
                Favorite.product_id == Product.id
            )
        
        products = query.all()
        
        favorite_product_ids = [fav.product_id for fav in 
                               self.db.query(Favorite).filter(Favorite.user_id == user_id).all()]
        
        return [
            {
                'id': product.id,
                'name': product.name,
                'price': product.price,
                'image_url': product.image_url,
                'in_favorites': product.id in favorite_product_ids
            }
            for product in products
        ]

    def find_ingredient_alternatives(self, clarifai_ingredients: List[str], user_id: int) -> List[Dict]:
        alternatives = []
        
        for ingredient in clarifai_ingredients:
            favorite_products = self.get_products_by_tag(ingredient, user_id, only_favorites=True)
            other_products = self.get_products_by_tag(ingredient, user_id, only_favorites=False)
            
            other_products = [p for p in other_products if p['id'] not in [fp['id'] for fp in favorite_products]]
            
            if favorite_products or other_products:
                alternatives.append({
                    'ingredient': ingredient,
                    'products': favorite_products + other_products
                })
        
        return alternatives

    def add_tag_to_product(self, product_id: int, tag: str):
        product_tag = ProductTag(product_id=product_id, tag=tag.lower().strip())
        self.db.add(product_tag)
        self.db.commit()
        return product_tag