"""
Nutrition service for mapping foods to nutrition data
"""
from typing import List, Dict, Optional
from app.models.food_item import FoodItem
from app.models.nutrient import Nutrient


class NutritionService:
    """Service for nutrition data mapping and calculations"""
    
    # Basic nutrition database (simplified - in production, use USDA/Open Food Facts API)
    NUTRITION_DB = {
        "apple": {
            "calories": 52, "protein": 0.3, "carbs": 14, "fiber": 2.4,
            "fat": 0.2, "vitamin_c": 4.6, "unit": "per_100g"
        },
        "banana": {
            "calories": 89, "protein": 1.1, "carbs": 23, "fiber": 2.6,
            "fat": 0.3, "potassium": 358, "unit": "per_100g"
        },
        "chicken breast": {
            "calories": 165, "protein": 31, "carbs": 0, "fiber": 0,
            "fat": 3.6, "unit": "per_100g"
        },
        "chicken": {
            "calories": 165, "protein": 31, "carbs": 0, "fiber": 0,
            "fat": 3.6, "unit": "per_100g"
        },
        "rice": {
            "calories": 130, "protein": 2.7, "carbs": 28, "fiber": 0.4,
            "fat": 0.3, "unit": "per_100g"
        },
        "egg": {
            "calories": 155, "protein": 13, "carbs": 1.1, "fiber": 0,
            "fat": 11, "unit": "per_100g"
        },
        "bread": {
            "calories": 265, "protein": 9, "carbs": 49, "fiber": 2.7,
            "fat": 3.2, "unit": "per_100g"
        },
        "milk": {
            "calories": 42, "protein": 3.4, "carbs": 5, "fiber": 0,
            "fat": 1, "unit": "per_100g"
        },
        "salad": {
            "calories": 20, "protein": 1.5, "carbs": 3.5, "fiber": 2,
            "fat": 0.2, "vitamin_c": 15, "unit": "per_100g"
        },
        "fish": {
            "calories": 136, "protein": 20, "carbs": 0, "fiber": 0,
            "fat": 5.9, "unit": "per_100g"
        },
        "beef": {
            "calories": 250, "protein": 26, "carbs": 0, "fiber": 0,
            "fat": 15, "iron": 2.6, "unit": "per_100g"
        },
        "pasta": {
            "calories": 131, "protein": 5, "carbs": 25, "fiber": 1.8,
            "fat": 1.1, "unit": "per_100g"
        },
    }
    
    # Default nutrition for unknown foods (average meal estimate)
    DEFAULT_NUTRITION = {
        "calories": 150, "protein": 8, "carbs": 20, "fiber": 2,
        "fat": 5, "unit": "per_100g"
    }
    
    def normalize_food_name(self, food_name: str) -> str:
        """Normalize food name for database lookup"""
        return food_name.lower().strip()
    
    def get_nutrition_data(self, food_name: str, quantity: float = 100, unit: str = "g") -> Dict[str, float]:
        """
        Get nutrition data for a food item.
        Returns nutrients per specified quantity.
        """
        normalized_name = self.normalize_food_name(food_name)
        
        # Look up in database
        base_nutrition = self.NUTRITION_DB.get(normalized_name)
        if not base_nutrition:
            # Try partial match
            for key, value in self.NUTRITION_DB.items():
                if key in normalized_name or normalized_name in key:
                    base_nutrition = value
                    break
        
        if not base_nutrition:
            # Use default estimated nutrition for unknown foods
            base_nutrition = self.DEFAULT_NUTRITION
        
        # Calculate nutrients based on quantity
        multiplier = quantity / 100.0  # Assuming base is per 100g
        
        nutrition = {}
        for nutrient, value in base_nutrition.items():
            if nutrient != "unit" and isinstance(value, (int, float)):
                nutrition[nutrient] = value * multiplier
        
        return nutrition
    
    # Map nutrient names to standard units
    nutrient_units = {
        "calories": "kcal",
        "protein": "g",
        "carbs": "g",
        "fiber": "g",
        "fat": "g",
        "vitamin_c": "mg",
        "potassium": "mg",
        "sodium": "mg",
        "calcium": "mg",
        "iron": "mg",
    }
    
    def create_nutrient_objects(
        self,
        food_item: FoodItem,
        nutrition_data: Dict[str, float]
    ) -> List[Nutrient]:
        """Create Nutrient objects from nutrition data"""
        nutrients = []
        
        for nutrient_name, value in nutrition_data.items():
            unit = self.nutrient_units.get(nutrient_name, "g")
            nutrient = Nutrient(
                food_item_id=food_item.id,
                name=nutrient_name,
                value=value,
                unit=unit,
                per_100g=value / (food_item.quantity / 100.0) if food_item.quantity else value
            )
            nutrients.append(nutrient)
        
        return nutrients


# Global nutrition service instance
nutrition_service = NutritionService()

