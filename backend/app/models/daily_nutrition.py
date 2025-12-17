"""
Daily nutrition aggregation model
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey, DateTime, Index
from sqlalchemy.orm import relationship

from app.core.database import Base


class DailyNutrition(Base):
    """Daily nutrition aggregation model for tracking daily nutrient totals"""
    __tablename__ = "daily_nutrition"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    nutrient_name = Column(String, nullable=False, index=True)  # e.g., "calories", "protein"
    total_value = Column(Float, nullable=False)  # Total for the day
    unit = Column(String, nullable=False)  # e.g., "kcal", "g", "mg"
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Unique constraint: one record per user per date per nutrient
    __table_args__ = (
        Index('ix_daily_nutrition_user_date_nutrient', 'user_id', 'date', 'nutrient_name', unique=True),
    )

