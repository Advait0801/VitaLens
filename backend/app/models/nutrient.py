"""
Nutrient model
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship

from app.core.database import Base


class Nutrient(Base):
    """Nutrient model for storing nutrient information for food items"""
    __tablename__ = "nutrients"

    id = Column(Integer, primary_key=True, index=True)
    food_item_id = Column(Integer, ForeignKey("food_items.id"), nullable=False, index=True)
    name = Column(String, nullable=False, index=True)  # e.g., "calories", "protein", "vitamin_c"
    value = Column(Float, nullable=False)  # Nutrient value
    unit = Column(String, nullable=False)  # e.g., "kcal", "g", "mg", "mcg"
    per_100g = Column(Float, nullable=True)  # Value per 100g for reference
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    food_item = relationship("FoodItem", back_populates="nutrients")

