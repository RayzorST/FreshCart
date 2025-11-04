from transformers import pipeline
from PIL import Image
import io
import logging
from typing import List, Dict

logger = logging.getLogger(__name__)

class FoodClassificationModel:
    def __init__(self):
        try:
            self.classifier = pipeline(
                "image-classification", 
                model="prithivMLmods/Food-101-93M",
                device=-1  # CPU
            )
            logger.info("✅ Food101 model loaded successfully")
        except Exception as e:
            logger.error(f"❌ Failed to load Food101: {e}")
            self.classifier = None

    def detect_dish(self, image_bytes: bytes) -> Dict:
        """Определяем блюдо и возвращаем название"""
        if self.classifier is None:
            return {
                "dish_name": "салат",
                "confidence": 0.0,
                "message": "Model not loaded"
            }
        
        try:
            image = Image.open(io.BytesIO(image_bytes))
            results = self.classifier(image)
            
            # Берем самый уверенный результат
            top_result = results[0]
            dish_name = self._clean_dish_name(top_result['label'])
            confidence = top_result['score']
            
            logger.info(f"🎯 Detected: {dish_name} (confidence: {confidence:.2f})")
            
            return {
                "dish_name": dish_name,
                "confidence": float(confidence),
                "message": f"Определено блюдо: {dish_name}"
            }
            
        except Exception as e:
            logger.error(f"❌ Dish detection error: {e}")
            return {
                "dish_name": "салат",
                "confidence": 0.0,
                "message": f"Error: {str(e)}"
            }

    def _clean_dish_name(self, label: str) -> str:
        """Очищаем название блюда"""
        # Заменяем подчеркивания на пробелы и делаем первую букву заглавной
        cleaned = label.replace('_', ' ').title()
        return cleaned

    def get_model_info(self) -> Dict:
        """Информация о модели"""
        return {
            "status": "loaded" if self.classifier else "failed",
            "model": "ethz/food101",
            "classes": 101
        }
    
    def _get_dish_mapping(self) -> dict:
        return {
            # Пицца - двухуровневая система
            "pizza": {
                "basic": ["тесто для пиццы", "томатный соус", "сыр моцарелла"],
                "additional": ["пепперони", "ветчина", "грибы", "оливки", "перец", 
                            "лук", "ананасы", "курица", "бекон", "салями"]
            },
            
            # Цезарь
            "caesar_salad": {
                "basic": ["романо", "курица", "пармезан", "сухарики"],
                "additional": ["черри", "бекон", "яйцо", "авокадо", "креветки"]
            },
            
            # Бургер
            "hamburger": {
                "basic": ["булочка для бургера", "говяжья котлета", "сыр чеддер"],
                "additional": ["салат айсберг", "помидор", "лук", "огурцы", "бекон",
                            "яйцо", "авокадо", "грибы", "соус"]
            },
            
            # Суши/роллы
            "sushi": {
                "basic": ["рис для суши", "нори", "лосось", "огурец"],
                "additional": ["тунец", "авокадо", "икра", "угорь", "сыр филадельфия",
                            "краб", "васаби", "имбирь", "соус соевый"]
            },
            
            # Паста
            "spaghetti_bolognese": {
                "basic": ["спагетти", "фарш говяжий", "томатный соус", "лук"],
                "additional": ["морковь", "сельдерей", "сыр пармезан", "базилик",
                            "чеснок", "грибы", "перец"]
            },
            
            # Торт
            "chocolate_cake": {
                "basic": ["мука", "какао", "сахар", "яйца", "разрыхлитель"],
                "additional": ["шоколад", "сливки", "ягоды", "орехи", "кокос",
                            "ваниль", "кофе"]
            },
            
            # Fallback для неизвестных блюд
            "default": {
                "basic": ["основа", "соус", "специи"],
                "additional": ["дополнительные ингредиенты"]
            }
        }
    
    def detect_dish_with_ingredients(self, image_bytes: bytes) -> Dict:
        """Определяем блюдо и подбираем ингредиенты"""
        dish_result = self.detect_dish(image_bytes)
        dish_name_key = dish_result["dish_name"].lower().replace(' ', '_')
        
        # Получаем ингредиенты для блюда
        ingredients = self._get_ingredients_for_dish(dish_name_key)
        
        # Объединяем результаты
        result = {
            **dish_result,
            "ingredients": ingredients,
            "basic_ingredients": ingredients["basic"],
            "additional_ingredients": ingredients["additional"]
        }
        
        return result

    def _get_ingredients_for_dish(self, dish_name_key: str) -> Dict:
        """Получаем ингредиенты для блюда"""
        mapping = self._get_dish_mapping()
        
        # Ищем точное совпадение
        if dish_name_key in mapping:
            return mapping[dish_name_key]
        
        # Ищем частичное совпадение
        for dish_key, ingredients in mapping.items():
            if dish_key in dish_name_key or dish_name_key in dish_key:
                return ingredients
        
        # Fallback
        return mapping["default"]