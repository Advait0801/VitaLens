"""
Food item model
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class FoodItem(Base):
    """Food item model for storing individual food items in meals"""
    __tablename__ = "food_items"

    id = Column(Integer, primary_key=True, index=True)
    meal_id = Column(Integer, ForeignKey("meals.id"), nullable=False, index=True)
    name = Column(String, nullable=False, index=True)
    normalized_name = Column(String, nullable=True, index=True)  # LLM normalized name
    quantity = Column(Float, nullable=True)  # Amount in grams or units
    unit = Column(String, nullable=True)  # Unit of measurement (g, ml, pieces, etc.)
    brand = Column(String, nullable=True)
    barcode = Column(String, nullable=True, index=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    meal = relationship("Meal", back_populates="food_items")
    nutrients = relationship("Nutrient", back_populates="food_item", cascade="all, delete-orphan")

