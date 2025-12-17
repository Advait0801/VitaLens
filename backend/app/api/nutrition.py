"""
Nutrition and health insights routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional, Dict
from datetime import date, datetime, timedelta

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User
from app.models.meal import Meal
from app.models.food_item import FoodItem
from app.models.nutrient import Nutrient
from app.models.daily_nutrition import DailyNutrition
from app.services.llm_service import llm_service

router = APIRouter(prefix="/nutrition", tags=["Nutrition"])


@router.get("/daily")
async def get_daily_nutrition(
    target_date: Optional[date] = None,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get daily nutrition summary for a specific date"""
    if not target_date:
        target_date = date.today()
    
    # Get all meals for the date
    start_datetime = datetime.combine(target_date, datetime.min.time())
    end_datetime = datetime.combine(target_date, datetime.max.time())
    
    result = await db.execute(
        select(Meal)
        .where(
            and_(
                Meal.user_id == current_user.id,
                Meal.meal_date >= start_datetime,
                Meal.meal_date <= end_datetime
            )
        )
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meals = result.scalars().all()
    
    # Aggregate nutrients
    nutrient_totals = {}
    for meal in meals:
        for food_item in meal.food_items:
            for nutrient in food_item.nutrients:
                if nutrient.name not in nutrient_totals:
                    nutrient_totals[nutrient.name] = {
                        "name": nutrient.name,
                        "value": 0,
                        "unit": nutrient.unit
                    }
                nutrient_totals[nutrient.name]["value"] += nutrient.value
    
    return {
        "date": target_date,
        "nutrients": list(nutrient_totals.values()),
        "meal_count": len(meals)
    }


@router.get("/summary")
async def get_nutrition_summary(
    days: int = 7,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get nutrition summary for the last N days"""
    end_date = date.today()
    start_date = end_date - timedelta(days=days-1)
    
    start_datetime = datetime.combine(start_date, datetime.min.time())
    end_datetime = datetime.combine(end_date, datetime.max.time())
    
    result = await db.execute(
        select(Meal)
        .where(
            and_(
                Meal.user_id == current_user.id,
                Meal.meal_date >= start_datetime,
                Meal.meal_date <= end_datetime
            )
        )
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meals = result.scalars().all()
    
    # Aggregate nutrients
    nutrient_totals = {}
    for meal in meals:
        for food_item in meal.food_items:
            for nutrient in food_item.nutrients:
                if nutrient.name not in nutrient_totals:
                    nutrient_totals[nutrient.name] = {
                        "name": nutrient.name,
                        "total": 0,
                        "average_per_day": 0,
                        "unit": nutrient.unit
                    }
                nutrient_totals[nutrient.name]["total"] += nutrient.value
    
    # Calculate averages
    for nutrient in nutrient_totals.values():
        nutrient["average_per_day"] = nutrient["total"] / days
    
    return {
        "period_days": days,
        "start_date": start_date,
        "end_date": end_date,
        "nutrients": list(nutrient_totals.values()),
        "total_meals": len(meals)
    }


@router.get("/insights")
async def get_health_insights(
    days: int = 7,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get AI-generated health insights based on nutrition data"""
    # Get nutrition summary
    end_date = date.today()
    start_date = end_date - timedelta(days=days-1)
    
    start_datetime = datetime.combine(start_date, datetime.min.time())
    end_datetime = datetime.combine(end_date, datetime.max.time())
    
    result = await db.execute(
        select(Meal)
        .where(
            and_(
                Meal.user_id == current_user.id,
                Meal.meal_date >= start_datetime,
                Meal.meal_date <= end_datetime
            )
        )
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meals = result.scalars().all()
    
    # Aggregate nutrients
    nutrient_summary = {}
    for meal in meals:
        for food_item in meal.food_items:
            for nutrient in food_item.nutrients:
                if nutrient.name not in nutrient_summary:
                    nutrient_summary[nutrient.name] = 0
                nutrient_summary[nutrient.name] += nutrient.value
    
    # Generate insights using LLM
    insights = await llm_service.generate_health_insight(
        nutrient_summary,
        time_period=f"{days} days"
    )
    
    return {
        "period_days": days,
        "nutrient_summary": nutrient_summary,
        "explanation": insights.get("explanation", ""),
        "recommendations": insights.get("recommendations", ""),
        "disclaimer": "This information is for general educational purposes only and is not intended as medical advice. Please consult with a healthcare professional for personalized recommendations."
    }

