# app/services/promotion_service.py
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from datetime import datetime
import json
from app.models.promotions import Promotion, PromotionType
from app.models.product import Product

class PromotionService:
    def __init__(self, db: Session):
        self.db = db

    def calculate_cart_discounts(self, cart_items: List[Dict], user_id: int) -> Dict[str, Any]:
        """
        Рассчитывает скидки для корзины
        """
        # Получаем активные акции
        active_promotions = self.get_active_promotions()
        
        # Загружаем информацию о товарах
        product_ids = [item['product_id'] for item in cart_items]
        products = self.get_products_by_ids(product_ids)
        
        # Инициализируем результат
        result = {
            'items': [],
            'total_amount': 0,
            'discount_amount': 0,
            'final_amount': 0,
            'applied_promotions': []
        }
        
        # Рассчитываем исходную сумму
        for item in cart_items:
            product = products.get(item['product_id'])
            if product:
                item_total = product.price * item['quantity']
                result['total_amount'] += item_total
        
        # Применяем акции
        cart_with_discounts = self.apply_promotions(cart_items, products, active_promotions)
        
        # Формируем итоговый результат
        result['items'] = cart_with_discounts['items']
        result['discount_amount'] = cart_with_discounts['total_discount']
        result['final_amount'] = result['total_amount'] - result['discount_amount']
        result['applied_promotions'] = cart_with_discounts['applied_promotions']
        
        return result

    def get_active_promotions(self) -> List[Promotion]:
        """Получить активные акции"""
        now = datetime.now()
        return self.db.query(Promotion).filter(
            Promotion.is_active == True,
            Promotion.start_date <= now,
            Promotion.end_date >= now
        ).order_by(Promotion.priority.desc()).all()

    def get_products_by_ids(self, product_ids: List[int]) -> Dict[int, Product]:
        """Получить товары по ID"""
        products = self.db.query(Product).filter(Product.id.in_(product_ids)).all()
        return {product.id: product for product in products}

    def apply_promotions(self, cart_items: List[Dict], products: Dict[int, Product], 
                        promotions: List[Promotion]) -> Dict[str, Any]:
        """
        Применяет акции к товарам в корзине
        """
        items_with_discounts = []
        applied_promotions = []
        total_discount = 0
        
        # Копируем товары для применения скидок
        for item in cart_items:
            product = products.get(item['product_id'])
            if not product:
                continue
                
            item_data = {
                'product_id': item['product_id'],
                'quantity': item['quantity'],
                'price': product.price,
                'discount_price': product.price,  # начальная цена без скидки
                'applied_promotions': [],
                'category_id': product.category_id
            }
            items_with_discounts.append(item_data)
        
        # Применяем акции по приоритету
        for promotion in promotions:
            promotion_applied = self.apply_single_promotion(
                items_with_discounts, promotion, products
            )
            
            if promotion_applied:
                applied_promotions.append({
                    'promotion_id': promotion.id,
                    'name': promotion.name,
                    'description': promotion.description
                })
        
        # Пересчитываем общую скидку
        for item in items_with_discounts:
            item_discount = (item['price'] - item['discount_price']) * item['quantity']
            total_discount += item_discount
        
        return {
            'items': items_with_discounts,
            'total_discount': total_discount,
            'applied_promotions': applied_promotions
        }

    def apply_single_promotion(self, items: List[Dict], promotion: Promotion, 
                            products: Dict[int, Product]) -> bool:
        """
        Применяет одну акцию к товарам
        """
        print(f"=== APPLYING PROMOTION: {promotion.name} ===")
        print(f"Type: {promotion.promotion_type}, Value: {promotion.value}")
        
        # Проверяем минимальную сумму заказа
        cart_total = sum(item['price'] * item['quantity'] for item in items)
        print(f"Cart total: {cart_total}, Min order: {promotion.min_order_amount}")
        
        if cart_total < promotion.min_order_amount / 100:
            print(f"❌ Cart total {cart_total} < min order {promotion.min_order_amount}")
            return False
        
        # Фильтруем товары, подходящие под акцию
        applicable_items = self.get_applicable_items(items, promotion, products)
        print(f"Applicable items: {len(applicable_items)}")
        
        if not applicable_items:
            print("❌ No applicable items")
            return False
        
        # Применяем акцию в зависимости от типа
        result = False
        if promotion.promotion_type == PromotionType.PERCENTAGE:
            result = self.apply_percentage_discount(applicable_items, promotion)
        elif promotion.promotion_type == PromotionType.FIXED:
            result = self.apply_fixed_discount(applicable_items, promotion)
        elif promotion.promotion_type == PromotionType.GIFT:
            result = self.apply_gift_promotion(applicable_items, promotion, products)
        
        print(f"✅ Promotion applied: {result}")
        return result

    def get_applicable_items(self, items: List[Dict], promotion: Promotion, 
                            products: Dict[int, Product]) -> List[Dict]:
        """
        Получает товары, подходящие под акцию
        """
        applicable_items = []
        
        print(f"Checking promotion categories: {[pc.category_id for pc in promotion.categories]}")
        print(f"Checking promotion products: {[pp.product_id for pp in promotion.products]}")
        
        # Проверяем товары по категориям
        if promotion.categories:
            promotion_category_ids = [pc.category_id for pc in promotion.categories]
            print(f"Promotion category IDs: {promotion_category_ids}")
            
            for item in items:
                product = products.get(item['product_id'])
                if product:
                    print(f"Product {product.id}: category {product.category_id}, in promotion categories: {product.category_id in promotion_category_ids}")
                    print(f"Product {product.id} : {promotion.gift_product_id} | {product.id == promotion.gift_product_id}")
                    if product.category_id in promotion_category_ids:
                        applicable_items.append(item)
        
        # Проверяем конкретные товары
        elif promotion.products:
            promotion_product_ids = [pp.product_id for pp in promotion.products]
            print(f"Promotion product IDs: {promotion_product_ids}")
            
            for item in items:
                print(f"Product {item['product_id']} in promotion products: {item['product_id'] in promotion_product_ids or item['product_id'] == promotion.gift_product_id}")
                if item['product_id'] in promotion_product_ids or item['product_id'] == promotion.gift_product_id:
                    applicable_items.append(item)
        
        # Если нет ограничений - все товары подходят
        else:
            applicable_items = items.copy()
            print("No category/product restrictions - all items applicable")
        
        # Фильтруем по минимальному количеству
        filtered_items = []
        for item in applicable_items:
            if item['quantity'] >= promotion.min_quantity or item['product_id'] == promotion.gift_product_id:
                filtered_items.append(item)
            else:
                print(f"Item {item['product_id']} quantity {item['quantity']} < min {promotion.min_quantity}")
        
        print(f"After quantity filter: {len(filtered_items)} items")
        return filtered_items

    def apply_percentage_discount(self, items: List[Dict], promotion: Promotion) -> bool:
        """Применяет процентную скидку"""
        if not promotion.value:
            return False
            
        discount_multiplier = (100 - promotion.value) / 100
        
        for item in items:
            new_price = item['price'] * discount_multiplier
            # Применяем скидку только если она лучше текущей
            if new_price < item['discount_price']:
                item['discount_price'] = new_price
                item['applied_promotions'].append({
                    'promotion_id': promotion.id,
                    'name': promotion.name,
                    'type': 'percentage',
                    'value': promotion.value
                })
        
        return True

    def apply_fixed_discount(self, items: List[Dict], promotion: Promotion) -> bool:
        """Применяет фиксированную скидку"""
        if not promotion.value:
            return False
            
        for item in items:
            new_price = max(0, item['price'] - promotion.value)
            # Применяем скидку только если она лучше текущей
            if new_price < item['discount_price']:
                item['discount_price'] = new_price
                item['applied_promotions'].append({
                    'promotion_id': promotion.id,
                    'name': promotion.name,
                    'type': 'fixed',
                    'value': promotion.value
                })
        
        return True

    def apply_gift_promotion(self, items: List[Dict], promotion: Promotion, 
                            products: Dict[int, Product]) -> bool:
        """Применяет акцию 'подарок'"""
        if not promotion.gift_product_id:
            return False
        print(f"products {products}")
        print(f"promotion gift {promotion.gift_product_id}")
        gift_product = products.get(promotion.gift_product_id)
        if not gift_product:
            return False
        
        for item in items:
            print(item)
            if item['quantity'] >= promotion.min_quantity:
                # Добавляем информацию о подарке
                item['applied_promotions'].append({
                    'promotion_id': promotion.id,
                    'name': promotion.name,
                    'type': 'gift',
                    'gift_product_id': promotion.gift_product_id,
                    'gift_product_name': gift_product.name
                })

            if item['product_id'] == promotion.gift_product_id:
                item['discount_price'] = 0
                item['applied_promotions'].append({
                    'promotion_id': promotion.id,
                    'name': promotion.name,
                    'type': 'gift',
                    'gift_product_id': promotion.gift_product_id,
                    'gift_product_name': gift_product.name
                })
        return True