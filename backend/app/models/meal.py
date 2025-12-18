"""
Meal model
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


class MealType(str, enum.Enum):
    """Meal type enumeration"""
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"
    OTHER = "other"


class MealSource(str, enum.Enum):
    """Meal source type"""
    IMAGE = "image"
    PDF = "pdf"
    CSV = "csv"
    MANUAL = "manual"


class Meal(Base):
    """Meal model for storing meal information"""
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    meal_type = Column(SQLEnum(MealType), nullable=False)
    source_type = Column(SQLEnum(MealSource), nullable=False)
    source_file_path = Column(String, nullable=True)  # Path to uploaded file
    raw_text = Column(Text, nullable=True)  # OCR extracted text
    notes = Column(Text, nullable=True)
    meal_date = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    user = relationship("User", back_populates="meals")
    food_items = relationship("FoodItem", back_populates="meal", cascade="all, delete-orphan")

