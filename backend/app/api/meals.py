"""
Meal routes
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, date, timezone
from pathlib import Path
import os
import uuid

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.core.config import settings
from app.models.user import User
from app.models.meal import Meal, MealType, MealSource
from app.models.food_item import FoodItem
from app.models.nutrient import Nutrient
from app.schemas.meal import MealCreate, MealResponse, MealWithNutrients
from app.services.ocr_service import ocr_service
from app.services.llm_service import llm_service
from app.services.nutrition_service import nutrition_service

router = APIRouter(prefix="/meals", tags=["Meals"])


@router.post("/upload", response_model=MealResponse, status_code=status.HTTP_201_CREATED)
async def upload_meal(
    file: UploadFile = File(...),
    meal_type: MealType = MealType.OTHER,
    meal_date: Optional[datetime] = None,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Upload a meal image, PDF, or CSV file"""
    # Determine source type
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext in [".jpg", ".jpeg", ".png", ".gif", ".bmp"]:
        source_type = MealSource.IMAGE
    elif file_ext == ".pdf":
        source_type = MealSource.PDF
    elif file_ext == ".csv":
        source_type = MealSource.CSV
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type: {file_ext}"
        )
    
    # Save file
    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    file_id = str(uuid.uuid4())
    file_path = upload_dir / f"{file_id}{file_ext}"
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    # Extract text using OCR
    raw_text = ""
    try:
        if source_type == MealSource.IMAGE:
            raw_text = await ocr_service.extract_text_from_image(str(file_path))
        elif source_type == MealSource.PDF:
            raw_text = await ocr_service.extract_text_from_pdf(str(file_path))
        elif source_type == MealSource.CSV:
            # For CSV, read directly
            with open(file_path, "r") as f:
                raw_text = f.read()
        
        # Log extracted text length for debugging
        print(f"Extracted {len(raw_text)} characters from {source_type.value} file")
        if not raw_text or len(raw_text.strip()) < 10:
            print(f"WARNING: OCR extracted very little text: '{raw_text[:100]}'")
    except Exception as e:
        print(f"OCR extraction error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to extract text: {str(e)}"
        )
    
    # Normalize food items using LLM
    normalized_data = await llm_service.normalize_food_text(raw_text)
    print(f"LLM normalization result: is_nutrition_label={normalized_data.get('is_nutrition_label')}, "
          f"nutrients_count={len(normalized_data.get('nutrients', []))}, "
          f"food_items_count={len(normalized_data.get('food_items', []))}")
    
    # Create meal
    # Normalize meal_date to timezone-naive datetime for consistent storage
    if meal_date:
        # If meal_date is provided and timezone-aware, convert to naive UTC
        if meal_date.tzinfo is not None:
            meal_date = meal_date.replace(tzinfo=None)
    else:
        # Default to current UTC time as timezone-naive
        meal_date = datetime.now(timezone.utc).replace(tzinfo=None)
    
    meal = Meal(
        user_id=current_user.id,
        meal_type=meal_type,
        source_type=source_type,
        source_file_path=str(file_path),
        raw_text=raw_text,
        meal_date=meal_date
    )
    
    db.add(meal)
    await db.flush()
    
    # Handle nutrition label vs food items list
    if normalized_data.get("is_nutrition_label"):
        # Create a single food item from nutrition label
        serving_size = normalized_data.get("serving_size", "1 serving")
        nutrients_data = normalized_data.get("nutrients", [])
        
        food_item = FoodItem(
            meal_id=meal.id,
            name=f"Food item ({serving_size})",
            normalized_name="nutrition_label_item",
            quantity=1,
            unit="serving",
            description=f"Nutrition label - {serving_size}"
        )
        db.add(food_item)
        await db.flush()
        
        # Create nutrients directly from label data
        created_nutrients_count = 0
        for nutrient_data in nutrients_data:
            nutrient_name = nutrient_data.get("name", "").strip()
            nutrient_value = nutrient_data.get("value", 0)
            nutrient_unit = nutrient_data.get("unit", "g")
            
            # Skip if name is empty or value is invalid
            if not nutrient_name:
                print(f"WARNING: Skipping nutrient with empty name: {nutrient_data}")
                continue
            
            try:
                # Normalize nutrient name
                normalized_name = nutrient_name.lower().replace(" ", "_")
                nutrient_value_float = float(nutrient_value) if nutrient_value is not None else 0.0
                
                nutrient = Nutrient(
                    food_item_id=food_item.id,
                    name=normalized_name,
                    value=nutrient_value_float,
                    unit=nutrient_unit,
                    per_100g=None  # Not applicable for nutrition labels
                )
                db.add(nutrient)
                created_nutrients_count += 1
            except (ValueError, TypeError) as e:
                print(f"WARNING: Failed to create nutrient {nutrient_name}: {e}, data: {nutrient_data}")
                continue
        
        print(f"Created {created_nutrients_count} nutrients from nutrition label")
        
        if created_nutrients_count == 0:
            print(f"WARNING: No nutrients were created from nutrition label. Raw data: {nutrients_data}")
    else:
        # Handle regular food items list
        food_items_data = normalized_data.get("food_items", [])
        for item_data in food_items_data:
            food_item = FoodItem(
                meal_id=meal.id,
                name=item_data.get("name", ""),
                normalized_name=item_data.get("name", ""),
                quantity=item_data.get("quantity"),
                unit=item_data.get("unit", "g"),
                brand=item_data.get("brand")
            )
            db.add(food_item)
            await db.flush()
            
            # Get nutrition data from APIs (Open Food Facts or USDA)
            nutrition_data = await nutrition_service.get_nutrition_data_async(
                food_item.normalized_name or food_item.name,
                food_item.quantity or 100,
                food_item.unit or "g",
                barcode=food_item.barcode
            )
            
            # Create nutrient objects
            for nutrient_name, value in nutrition_data.items():
                nutrient = Nutrient(
                    food_item_id=food_item.id,
                    name=nutrient_name,
                    value=value,
                    unit=nutrition_service.nutrient_units.get(nutrient_name, "g"),
                    per_100g=value / (food_item.quantity / 100.0) if food_item.quantity and food_item.quantity > 0 else value
                )
                db.add(nutrient)
    
    await db.commit()
    await db.refresh(meal)
    
    # Load relationships
    result = await db.execute(
        select(Meal)
        .where(Meal.id == meal.id)
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meal = result.scalar_one()
    
    return meal


@router.post("", response_model=MealResponse, status_code=status.HTTP_201_CREATED)
async def create_meal(
    meal_data: MealCreate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a meal manually"""
    # Normalize meal_date to timezone-naive datetime for consistent storage
    meal_date_value = meal_data.meal_date
    if meal_date_value:
        # If meal_date is provided and timezone-aware, convert to naive UTC
        if meal_date_value.tzinfo is not None:
            meal_date_value = meal_date_value.replace(tzinfo=None)
    else:
        # Default to current UTC time as timezone-naive
        meal_date_value = datetime.now(timezone.utc).replace(tzinfo=None)
    
    meal = Meal(
        user_id=current_user.id,
        meal_type=meal_data.meal_type,
        source_type=MealSource.MANUAL,
        notes=meal_data.notes,
        meal_date=meal_date_value
    )
    
    db.add(meal)
    await db.flush()
    
    # Create food items
    for item_data in meal_data.food_items:
        food_item = FoodItem(
            meal_id=meal.id,
            name=item_data.name,
            quantity=item_data.quantity,
            unit=item_data.unit,
            brand=item_data.brand,
            barcode=item_data.barcode
        )
        db.add(food_item)
        await db.flush()
        
        # Get nutrition data from APIs (Open Food Facts or USDA)
        nutrition_data = await nutrition_service.get_nutrition_data_async(
            food_item.name,
            food_item.quantity or 100,
            food_item.unit or "g",
            barcode=food_item.barcode
        )
        
        # Create nutrient objects
        for nutrient_name, value in nutrition_data.items():
            nutrient = Nutrient(
                food_item_id=food_item.id,
                name=nutrient_name,
                value=value,
                unit=nutrition_service.nutrient_units.get(nutrient_name, "g"),
                per_100g=value / (food_item.quantity / 100.0) if food_item.quantity and food_item.quantity > 0 else value
            )
            db.add(nutrient)
    
    await db.commit()
    await db.refresh(meal)
    
    result = await db.execute(
        select(Meal)
        .where(Meal.id == meal.id)
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meal = result.scalar_one()
    
    return meal


@router.get("", response_model=List[MealResponse])
async def get_meals(
    skip: int = 0,
    limit: int = 100,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's meals"""
    query = select(Meal).where(Meal.user_id == current_user.id)
    
    if start_date:
        query = query.where(Meal.meal_date >= start_date)
    if end_date:
        query = query.where(Meal.meal_date <= end_date)
    
    query = query.order_by(Meal.meal_date.desc()).offset(skip).limit(limit)
    query = query.options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    
    result = await db.execute(query)
    meals = result.scalars().all()
    
    return meals


@router.get("/{meal_id}", response_model=MealWithNutrients)
async def get_meal(
    meal_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific meal with nutrients"""
    result = await db.execute(
        select(Meal)
        .where(and_(Meal.id == meal_id, Meal.user_id == current_user.id))
        .options(selectinload(Meal.food_items).selectinload(FoodItem.nutrients))
    )
    meal = result.scalar_one_or_none()
    
    if not meal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meal not found"
        )
    
    # Calculate total nutrients
    total_nutrients = {}
    for food_item in meal.food_items:
        for nutrient in food_item.nutrients:
            if nutrient.name not in total_nutrients:
                total_nutrients[nutrient.name] = {
                    "name": nutrient.name,
                    "value": 0,
                    "unit": nutrient.unit
                }
            total_nutrients[nutrient.name]["value"] += nutrient.value
    
    from app.schemas.meal import MealResponse
    meal_dict = {
        "id": meal.id,
        "user_id": meal.user_id,
        "meal_type": meal.meal_type,
        "source_type": meal.source_type,
        "source_file_path": meal.source_file_path,
        "raw_text": meal.raw_text,
        "notes": meal.notes,
        "meal_date": meal.meal_date,
        "food_items": [
            {
                "id": item.id,
                "name": item.name,
                "normalized_name": item.normalized_name,
                "quantity": item.quantity,
                "unit": item.unit,
                "brand": item.brand,
                "barcode": item.barcode,
                "description": item.description,
                "created_at": item.created_at,
            }
            for item in meal.food_items
        ],
        "created_at": meal.created_at,
        "updated_at": meal.updated_at,
        "total_nutrients": list(total_nutrients.values())
    }
    return meal_dict


@router.delete("/{meal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meal(
    meal_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a meal"""
    result = await db.execute(
        select(Meal).where(and_(Meal.id == meal_id, Meal.user_id == current_user.id))
    )
    meal = result.scalar_one_or_none()
    
    if not meal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meal not found"
        )
    
    # Delete associated file if exists
    if meal.source_file_path and os.path.exists(meal.source_file_path):
        try:
            os.remove(meal.source_file_path)
        except Exception:
            pass
    
    await db.delete(meal)
    await db.commit()
    
    return None

