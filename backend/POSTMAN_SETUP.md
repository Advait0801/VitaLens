# VitaLens API - Postman Manual Setup Guide

This guide shows you how to manually create each request in Postman.

## Initial Setup

### 1. Create Collection Variables
1. Create a new collection called "VitaLens API"
2. Go to collection → Variables tab
3. Add these variables:

| Variable | Initial Value | Current Value |
|----------|--------------|---------------|
| base_url | http://localhost:8000 | http://localhost:8000 |
| access_token | | |
| refresh_token | | |
| meal_id | | |
| user_id | | |

---

## Health Check Endpoints

### 1. Health Check

**Request:**
- Method: `GET`
- URL: `{{base_url}}/health`
- Headers: None
- Body: None

**Expected Response:**
```json
{
    "status": "healthy",
    "database": "connected"
}
```

---

## Authentication Endpoints

### 2. Register

**Request:**
- Method: `POST`
- URL: `{{base_url}}/auth/register`
- Headers:
  - `Content-Type`: `application/json`
- Body (raw JSON):
```json
{
    "email": "test@example.com",
    "username": "testuser",
    "password": "testpass123"
}
```

**Test Script (Tests tab):**
```javascript
if (pm.response.code === 201) {
    const response = pm.response.json();
    pm.collectionVariables.set('user_id', response.id);
}
```

**Expected Response (201 Created):**
```json
{
    "id": 1,
    "email": "test@example.com",
    "username": "testuser",
    "is_active": true,
    "created_at": "2024-12-17T10:00:00.000000"
}
```

---

### 3. Login

**Request:**
- Method: `POST`
- URL: `{{base_url}}/auth/login`
- Headers:
  - `Content-Type`: `application/json`
- Body (raw JSON):
```json
{
    "username_or_email": "testuser",
    "password": "testpass123"
}
```

**Note:** You can use either username OR email in the `username_or_email` field:
```json
{
    "username_or_email": "test@example.com",
    "password": "testpass123"
}
```

**Test Script (Tests tab):**
```javascript
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.collectionVariables.set('access_token', response.access_token);
    pm.collectionVariables.set('refresh_token', response.refresh_token);
}
```

**Expected Response (200 OK):**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
}
```

---

### 4. Refresh Token

**Request:**
- Method: `POST`
- URL: `{{base_url}}/auth/refresh`
- Headers:
  - `Content-Type`: `application/json`
- Body (raw JSON):
```json
{
    "refresh_token": "{{refresh_token}}"
}
```

**Test Script (Tests tab):**
```javascript
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.collectionVariables.set('access_token', response.access_token);
    pm.collectionVariables.set('refresh_token', response.refresh_token);
}
```

---

### 5. Get Current User

**Request:**
- Method: `GET`
- URL: `{{base_url}}/auth/me`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`
- Body: None

**Expected Response:**
```json
{
    "id": 1,
    "email": "test@example.com",
    "username": "testuser",
    "is_active": true,
    "created_at": "2024-12-17T10:00:00.000000"
}
```

---

## Meal Endpoints

### 6. Create Meal Manually

**Request:**
- Method: `POST`
- URL: `{{base_url}}/meals`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`
- Headers:
  - `Content-Type`: `application/json`
- Body (raw JSON):
```json
{
    "meal_type": "lunch",
    "source_type": "manual",
    "notes": "Delicious lunch",
    "meal_date": "2024-12-17T12:00:00",
    "food_items": [
        {
            "name": "apple",
            "quantity": 1,
            "unit": "piece",
            "brand": null
        },
        {
            "name": "chicken breast",
            "quantity": 150,
            "unit": "g",
            "brand": null
        }
    ]
}
```

**Test Script (Tests tab):**
```javascript
if (pm.response.code === 201) {
    const response = pm.response.json();
    pm.collectionVariables.set('meal_id', response.id);
}
```

**Expected Response (201 Created):**
```json
{
    "id": 1,
    "user_id": 1,
    "meal_type": "lunch",
    "source_type": "manual",
    "source_file_path": null,
    "raw_text": null,
    "notes": "Delicious lunch",
    "meal_date": "2024-12-17T12:00:00",
    "food_items": [
        {
            "id": 1,
            "name": "apple",
            "normalized_name": null,
            "quantity": 1,
            "unit": "piece",
            "brand": null,
            "barcode": null,
            "description": null,
            "created_at": "2024-12-17T10:00:00"
        }
    ],
    "created_at": "2024-12-17T10:00:00",
    "updated_at": "2024-12-17T10:00:00"
}
```

---

### 7. Upload Meal (Image/PDF/CSV)

**Request:**
- Method: `POST`
- URL: `{{base_url}}/meals/upload?meal_type=breakfast`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`
- Body:
  - Type: `form-data`
  - Key: `file` (Type: File) → Select your image/PDF/CSV file

**Query Parameters:**
- `meal_type`: `breakfast`, `lunch`, `dinner`, `snack`, or `other`
- `meal_date` (optional): ISO date format like `2024-12-17T10:00:00`

**Supported File Types:**
- Images: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`
- PDF: `.pdf`
- CSV: `.csv`

---

### 8. Get All Meals

**Request:**
- Method: `GET`
- URL: `{{base_url}}/meals`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`

**Query Parameters (all optional):**
- `skip`: Number of records to skip (default: 0)
- `limit`: Maximum records to return (default: 100)
- `start_date`: Filter from date (format: `YYYY-MM-DD`)
- `end_date`: Filter until date (format: `YYYY-MM-DD`)

**Example with params:**
```
{{base_url}}/meals?skip=0&limit=100&start_date=2024-12-01&end_date=2024-12-31
```

---

### 9. Get Meal by ID

**Request:**
- Method: `GET`
- URL: `{{base_url}}/meals/{{meal_id}}`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`

**Note:** Replace `{{meal_id}}` with actual ID or use the variable after creating a meal.

---

### 10. Delete Meal

**Request:**
- Method: `DELETE`
- URL: `{{base_url}}/meals/{{meal_id}}`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`

**Expected Response:** `204 No Content`

---

## Nutrition Endpoints

### 11. Get Daily Nutrition

**Request:**
- Method: `GET`
- URL: `{{base_url}}/nutrition/daily`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`

**Query Parameters (optional):**
- `target_date`: Date in `YYYY-MM-DD` format (defaults to today)

**Example:**
```
{{base_url}}/nutrition/daily?target_date=2024-12-17
```

**Expected Response:**
```json
{
    "date": "2024-12-17",
    "nutrients": [
        {"name": "calories", "value": 250.0, "unit": "kcal"},
        {"name": "protein", "value": 32.0, "unit": "g"},
        {"name": "carbs", "value": 14.0, "unit": "g"}
    ],
    "meal_count": 2
}
```

---

### 12. Get Nutrition Summary

**Request:**
- Method: `GET`
- URL: `{{base_url}}/nutrition/summary`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`

**Query Parameters (optional):**
- `days`: Number of days to summarize (default: 7)

**Example:**
```
{{base_url}}/nutrition/summary?days=7
```

**Expected Response:**
```json
{
    "period_days": 7,
    "start_date": "2024-12-11",
    "end_date": "2024-12-17",
    "nutrients": [
        {"name": "calories", "total": 14000.0, "average_per_day": 2000.0, "unit": "kcal"},
        {"name": "protein", "total": 350.0, "average_per_day": 50.0, "unit": "g"}
    ],
    "total_meals": 21
}
```

---

### 13. Get Health Insights

**Request:**
- Method: `GET`
- URL: `{{base_url}}/nutrition/insights`
- Authorization:
  - Type: `Bearer Token`
  - Token: `{{access_token}}`

**Query Parameters (optional):**
- `days`: Number of days to analyze (default: 7)

**Example:**
```
{{base_url}}/nutrition/insights?days=7
```

**Note:** Requires Ollama model. Run first:
```bash
docker exec vitalens-ollama ollama pull llama3.1
```

**Expected Response:**
```json
{
    "period_days": 7,
    "nutrient_summary": {
        "calories": 14000.0,
        "protein": 350.0,
        "carbs": 1400.0
    },
    "explanation": "Your protein intake is good, but you may need more fiber...",
    "recommendations": "Try adding more vegetables and whole grains...",
    "disclaimer": "This information is for general educational purposes only..."
}
```

---

## Meal Types Reference

Use these values for `meal_type`:
- `breakfast`
- `lunch`
- `dinner`
- `snack`
- `other`

## Source Types Reference

Use these values for `source_type`:
- `image` - Uploaded image
- `pdf` - Uploaded PDF
- `csv` - Uploaded CSV
- `manual` - Manually entered

---

## Testing Order

1. **Health Check** → Verify API is running
2. **Register** → Create account (saves user_id)
3. **Login** → Get tokens (saves access_token, refresh_token)
4. **Create Meal** → Add a meal (saves meal_id)
5. **Get All Meals** → List meals
6. **Get Meal by ID** → View specific meal
7. **Get Daily Nutrition** → View daily summary
8. **Get Nutrition Summary** → View period summary
9. **Get Health Insights** → Get AI insights
10. **Delete Meal** → Clean up

---

## Troubleshooting

**401 Unauthorized:**
- Token expired → Run Login again
- Missing token → Check Authorization header

**404 Not Found:**
- Wrong URL → Check endpoint path
- Meal doesn't exist → Check meal_id

**422 Validation Error:**
- Invalid data → Check request body format
- Missing required fields → Check required fields

**500 Internal Server Error:**
- Check API logs: `docker-compose logs api`
- Restart services: `docker-compose restart`
