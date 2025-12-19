"""
Nutrition service for mapping foods to nutrition data using USDA FoodData Central API
"""
import asyncio
from typing import List, Dict, Optional
import httpx
from app.models.food_item import FoodItem
from app.models.nutrient import Nutrient
from app.core.config import settings


class NutritionService:
    """Service for nutrition data mapping and calculations using USDA FoodData Central API"""
    
    # API endpoint
    USDA_API_BASE = "https://api.nal.usda.gov/fdc/v1"
    
    # Default nutrition for unknown foods (average meal estimate)
    DEFAULT_NUTRITION = {
        "calories": 150, "protein": 8, "carbs": 20, "fiber": 2,
        "fat": 5, "unit": "per_100g"
    }
    
    def __init__(self):
        """Initialize the nutrition service"""
        self._http_client: Optional[httpx.AsyncClient] = None
        self.usda_api_key = settings.USDA_API_KEY
    
    @property
    def http_client(self) -> httpx.AsyncClient:
        """Get or create HTTP client (lazy initialization)"""
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(timeout=10.0)
        return self._http_client
    
    def normalize_food_name(self, food_name: str) -> str:
        """Normalize food name for database lookup"""
        return food_name.lower().strip()
    
    async def get_nutrition_from_usda(self, food_name: str) -> Optional[Dict[str, float]]:
        """
        Get nutrition data from USDA FoodData Central API using food name.
        Returns nutrition data per 100g or None if not found.
        Requires API key (get one free at https://fdc.nal.usda.gov/api-guide.html)
        """
        if not self.usda_api_key:
            # USDA API requires an API key
            return None
        
        try:
            # Search for food
            search_url = f"{self.USDA_API_BASE}/foods/search"
            params = {
                "query": food_name,
                "api_key": self.usda_api_key,
                "pageSize": 1,
                "sortBy": "dataType.keyword"  # Prefer Foundation foods
            }
            
            response = await self.http_client.get(search_url, params=params)
            response.raise_for_status()
            search_data = response.json()
            
            foods = search_data.get("foods", [])
            if not foods:
                return None
            
            # Get the first result
            food = foods[0]
            fdc_id = food.get("fdcId")
            if not fdc_id:
                return None
            
            # Get detailed nutrition data
            detail_url = f"{self.USDA_API_BASE}/food/{fdc_id}"
            detail_params = {"api_key": self.usda_api_key}
            
            detail_response = await self.http_client.get(detail_url, params=detail_params)
            detail_response.raise_for_status()
            food_data = detail_response.json()
            
            # Extract nutrients (USDA provides nutrients in various units)
            nutrition = {}
            food_nutrients = food_data.get("foodNutrients", [])
            
            # Map USDA nutrient IDs to our nutrient names (common nutrients)
            nutrient_map = {
                1008: "calories",  # Energy (kcal)
                1003: "protein",   # Protein
                1005: "carbs",     # Carbohydrate, by difference
                1079: "fiber",     # Fiber, total dietary
                1004: "fat",       # Total lipid (fat)
                1253: "sodium",    # Sodium, Na (mg)
                1162: "vitamin_c", # Vitamin C, total ascorbic acid (mg)
                1087: "calcium",   # Calcium, Ca (mg)
                1089: "iron",      # Iron, Fe (mg)
                1092: "potassium", # Potassium, K (mg)
            }
            
            for fn in food_nutrients:
                nutrient_id = fn.get("nutrient", {}).get("id")
                nutrient_name = nutrient_map.get(nutrient_id)
                if nutrient_name:
                    amount = fn.get("amount")
                    if amount is not None:
                        nutrition[nutrient_name] = float(amount)
            
            # If we have calories but it's 0, try energy in kJ
            if "calories" not in nutrition or nutrition["calories"] == 0:
                for fn in food_nutrients:
                    nutrient_id = fn.get("nutrient", {}).get("id")
                    if nutrient_id == 1062:  # Energy (kJ)
                        amount = fn.get("amount")
                        if amount is not None:
                            nutrition["calories"] = float(amount) / 4.184  # Convert kJ to kcal
                            break
            
            nutrition["unit"] = "per_100g"
            return nutrition if nutrition else None
            
        except Exception as e:
            # Log error but don't raise - fall back to defaults
            print(f"Error fetching from USDA API: {e}")
            return None
    
    async def get_nutrition_data_async(
        self, 
        food_name: str, 
        quantity: float = 100, 
        unit: str = "g",
        barcode: Optional[str] = None
    ) -> Dict[str, float]:
        """
        Get nutrition data for a food item asynchronously using USDA FoodData Central API.
        Falls back to defaults if API fails or no data found.
        Returns nutrients per specified quantity.
        
        Args:
            food_name: Name of the food item
            quantity: Quantity in the specified unit (default: 100)
            unit: Unit of measurement (default: "g")
            barcode: Optional barcode (not used, kept for API compatibility)
        """
        # Try USDA API
        base_nutrition = await self.get_nutrition_from_usda(food_name)
        
        # Fall back to default if USDA API failed or no data found
        if not base_nutrition:
            base_nutrition = self.DEFAULT_NUTRITION.copy()
        
        # Calculate nutrients based on quantity
        multiplier = quantity / 100.0  # Assuming base is per 100g
        
        nutrition = {}
        for nutrient, value in base_nutrition.items():
            if nutrient != "unit" and isinstance(value, (int, float)):
                nutrition[nutrient] = value * multiplier
        
        return nutrition
    
    def get_nutrition_data(
        self, 
        food_name: str, 
        quantity: float = 100, 
        unit: str = "g",
        barcode: Optional[str] = None
    ) -> Dict[str, float]:
        """
        Get nutrition data for a food item (synchronous wrapper).
        Uses USDA FoodData Central API.
        For async contexts, use get_nutrition_data_async instead.
        """
        # Create event loop if none exists (for sync calls)
        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        if loop.is_running():
            # If loop is already running, use the async version
            # This is a fallback - ideally call get_nutrition_data_async directly
            print("Warning: Using sync method in async context. Use get_nutrition_data_async instead.")
            # Return default for now
            base_nutrition = self.DEFAULT_NUTRITION.copy()
            multiplier = quantity / 100.0
            nutrition = {}
            for nutrient, value in base_nutrition.items():
                if nutrient != "unit" and isinstance(value, (int, float)):
                    nutrition[nutrient] = value * multiplier
            return nutrition
        else:
            # Run async method in event loop
            return loop.run_until_complete(
                self.get_nutrition_data_async(food_name, quantity, unit, barcode)
            )
    
    # Map nutrient names to standard units
    nutrient_units = {
        "calories": "kcal",
        "protein": "g",
        "carbs": "g",
        "fiber": "g",
        "fat": "g",
        "saturated_fat": "g",
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

