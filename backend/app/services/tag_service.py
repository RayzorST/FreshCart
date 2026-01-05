# app/services/tag_service.py
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Dict, Optional
from app.models.product import Product, ProductTag, Tag
from app.models.favorite import Favorite

class TagService:
    def __init__(self, db: Session):
        self.db = db

    def get_products_by_tag(self, tag_name: str, user_id: int, limit: int = 10) -> List[Dict]:
        """Поиск товаров по названию тега с учетом избранного"""
        try:
            tag = self.db.query(Tag).filter(
                or_(
                    Tag.name.ilike(tag_name),
                    Tag.name.ilike(f"%{tag_name}%")
                )
            ).first()
            
            if not tag:
                return []
            
            products = self.db.query(Product).join(ProductTag).filter(
                ProductTag.tag_id == tag.id,
                Product.is_active == True
            ).limit(limit).all()
            
            favorite_product_ids = {
                fav.product_id for fav in 
                self.db.query(Favorite).filter(Favorite.user_id == user_id).all()
            }
            
            return [
                {
                    'id': product.id,
                    'name': product.name,
                    'price': float(product.price),
                    'image_url': product.image_url or '',
                    'in_favorites': product.id in favorite_product_ids,
                    'stock_quantity': product.stock_quantity,
                    'description': product.description
                }
                for product in products
            ]
            
        except Exception as e:
            print(f"Error in get_products_by_tag: {e}")
            return []

    def get_products_by_multiple_tags(self, tag_names: List[str], user_id: int, limit: int = 5) -> List[Dict]:
        """Поиск товаров по нескольким тегам"""
        products_by_tag = {}
        
        for tag_name in tag_names:
            products = self.get_products_by_tag(tag_name, user_id, limit)
            if products:
                products_by_tag[tag_name] = products
        
        return products_by_tag

    def find_ingredient_alternatives(self, ingredients: List[str], user_id: int) -> Dict:
        """Поиск альтернатив для списка ингредиентов"""
        alternatives = {
            "basic_alternatives": [],
            "additional_alternatives": []
        }
        
        for ingredient in ingredients:
            products = self.get_products_by_tag(ingredient, user_id, limit=5)
            if products:
                alternatives["basic_alternatives"].append({
                    'ingredient': ingredient,
                    'products': products
                })
        
        return alternatives

    def add_tag_to_product(self, product_id: int, tag_name: str):
        """Добавление тега к продукту"""
        try:
            # Находим или создаем тег
            tag = self.db.query(Tag).filter(Tag.name.ilike(tag_name)).first()
            if not tag:
                tag = Tag(name=tag_name.lower().strip())
                self.db.add(tag)
                self.db.commit()
                self.db.refresh(tag)
            
            # Проверяем, нет ли уже такой связи
            existing_link = self.db.query(ProductTag).filter(
                ProductTag.product_id == product_id,
                ProductTag.tag_id == tag.id
            ).first()
            
            if not existing_link:
                product_tag = ProductTag(product_id=product_id, tag_id=tag.id)
                self.db.add(product_tag)
                self.db.commit()
            
            return True
            
        except Exception as e:
            self.db.rollback()
            print(f"Error adding tag: {e}")
            return False

    def search_similar_products(self, product_id: int, user_id: int, limit: int = 5) -> List[Dict]:
        """Поиск похожих продуктов по тегам"""
        try:
            # Получаем теги текущего продукта
            product_tags = self.db.query(ProductTag).filter(
                ProductTag.product_id == product_id
            ).all()
            
            if not product_tags:
                return []
            
            tag_ids = [pt.tag_id for pt in product_tags]
            
            # Ищем продукты с такими же тегами (исключая текущий)
            similar_products = self.db.query(Product).join(ProductTag).filter(
                ProductTag.tag_id.in_(tag_ids),
                Product.id != product_id,
                Product.is_active == True
            ).distinct().limit(limit).all()
            
            # Получаем избранные товары
            favorite_product_ids = {
                fav.product_id for fav in 
                self.db.query(Favorite).filter(Favorite.user_id == user_id).all()
            }
            
            return [
                {
                    'id': product.id,
                    'name': product.name,
                    'price': float(product.price),
                    'image_url': product.image_url or '',
                    'in_favorites': product.id in favorite_product_ids,
                    'common_tags': len([t for t in product.product_tags if t.tag_id in tag_ids])
                }
                for product in similar_products
            ]
            
        except Exception as e:
            print(f"Error in search_similar_products: {e}")
            return []