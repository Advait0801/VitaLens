"""
Meal schemas
"""
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.meal import MealType, MealSource


class FoodItemBase(BaseModel):
    """Base schema for food item"""
    name: str
    quantity: Optional[float] = None
    unit: Optional[str] = None
    brand: Optional[str] = None
    barcode: Optional[str] = None


class FoodItemCreate(FoodItemBase):
    """Schema for creating food item"""
    pass


class FoodItemResponse(FoodItemBase):
    """Schema for food item response"""
    id: int
    normalized_name: Optional[str] = None
    description: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class NutrientBase(BaseModel):
    """Base schema for nutrient"""
    name: str
    value: float
    unit: str
    per_100g: Optional[float] = None


class NutrientResponse(NutrientBase):
    """Schema for nutrient response"""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class NutrientSummary(BaseModel):
    """Schema for nutrient summary (without id/timestamps)"""
    name: str
    value: float
    unit: str


class MealBase(BaseModel):
    """Base schema for meal"""
    meal_type: MealType
    notes: Optional[str] = None
    meal_date: Optional[datetime] = None


class MealCreate(MealBase):
    """Schema for creating meal"""
    source_type: MealSource
    food_items: Optional[List[FoodItemCreate]] = []


class MealResponse(MealBase):
    """Schema for meal response"""
    id: int
    user_id: int
    source_type: MealSource
    source_file_path: Optional[str] = None
    raw_text: Optional[str] = None
    food_items: List[FoodItemResponse] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class MealWithNutrients(MealResponse):
    """Schema for meal with nutrient summary"""
    total_nutrients: Optional[List[NutrientSummary]] = None

