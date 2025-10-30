from enum import Enum

class PromotionType(str, Enum):
    PERCENTAGE = "percentage"
    FIXED = "fixed" 
    GIFT = "gift"