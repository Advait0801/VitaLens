"""
Nutrition and health insights routes
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from sqlalchemy.orm import selectinload
from typing import Optional
from datetime import date, datetime, timedelta, timezone

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User
from app.models.meal import Meal
from app.models.food_item import FoodItem
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
        target_date = datetime.now(timezone.utc).date()
    
    # Get all meals for the date using date range comparison
    # meal_date is stored as timezone-naive DateTime (assumed to be UTC)
    # Create datetime range covering the entire target date (00:00:00 to 23:59:59.999999)
    start_of_day = datetime.combine(target_date, datetime.min.time())
    end_of_day = datetime.combine(target_date, datetime.max.time())
    
    result = await db.execute(
        select(Meal)
        .where(
            and_(
                Meal.user_id == current_user.id,
                Meal.meal_date >= start_of_day,
                Meal.meal_date <= end_of_day
            )
        )
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meals = result.scalars().all()
    
    # Debug logging - check ALL meals for this user to see what dates exist
    all_meals_result = await db.execute(
        select(Meal).where(Meal.user_id == current_user.id).order_by(Meal.meal_date.desc()).limit(10)
    )
    all_meals = all_meals_result.scalars().all()
    print(f"Querying meals for date: {target_date} (UTC range: {start_of_day} to {end_of_day})")
    print(f"Found {len(meals)} meals for user {current_user.id} on {target_date}")
    print(f"Recent meals for user {current_user.id} (last 10):")
    for meal in all_meals:
        meal_date_str = str(meal.meal_date) if meal.meal_date else "None"
        meal_date_obj = meal.meal_date
        meal_date_only = meal_date_obj.date() if meal_date_obj else None
        matches = "✓" if meal_date_only == target_date else "✗"
        print(f"  {matches} Meal ID {meal.id}: meal_date = {meal_date_str}, extracted date = {meal_date_only}")
    
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
    
    # Use date comparison for consistency
    
    result = await db.execute(
        select(Meal)
        .where(
            and_(
                Meal.user_id == current_user.id,
                func.date(Meal.meal_date) >= start_date,
                func.date(Meal.meal_date) <= end_date
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
    
    # Use date comparison for consistency
    
    result = await db.execute(
        select(Meal)
        .where(
            and_(
                Meal.user_id == current_user.id,
                func.date(Meal.meal_date) >= start_date,
                func.date(Meal.meal_date) <= end_date
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

