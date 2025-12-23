"""
LLM service for food normalization and health insights
"""
import httpx
from typing import Dict
from app.core.config import settings


class LLMService:
    """Service for interacting with Ollama LLM"""
    
    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = settings.OLLAMA_MODEL
        # Increased timeout for LLM processing (nutrition label parsing can take longer)
        self.client = httpx.AsyncClient(timeout=180.0)
    
    async def normalize_food_text(self, raw_text: str) -> Dict[str, any]:
        """
        Normalize food text using LLM to extract structured food information.
        Returns a list of food items with normalized names and quantities.
        Handles both food lists AND nutrition labels.
        """
        # Check if this looks like a nutrition label
        is_nutrition_label = any(keyword in raw_text.lower() for keyword in 
            ["nutrition facts", "calories", "total fat", "serving size", "daily value"])
        
        if is_nutrition_label:
            prompt = f"""This is a nutrition facts label. Extract ALL nutritional information from the text.

Return a JSON object with:
- "is_nutrition_label": true
- "serving_size": the serving size text (e.g., "1 Serving (720g)" or "1 cup (255g)")
- "servings_per_container": number of servings per container (if mentioned)
- "nutrients": an array of ALL nutrient objects found, each with:
  * "name": normalized nutrient name (use lowercase, underscores: calories, total_fat, saturated_fat, trans_fat, cholesterol, sodium, total_carbohydrate, dietary_fiber, total_sugars, added_sugars, protein, vitamin_d, calcium, iron, potassium, etc.)
  * "value": numeric value (float or int)
  * "unit": unit of measurement (g, mg, mcg, kcal, etc.)

IMPORTANT:
- Extract ALL nutrients mentioned in the label, not just the main ones
- Convert percentage values to actual amounts if needed (e.g., if it says "Total Fat 16g (21%)", use 16g, not 21%)
- Use standard nutrient names: calories, total_fat, saturated_fat, cholesterol, sodium, total_carbohydrate, dietary_fiber, total_sugars, added_sugars, protein, vitamin_d, calcium, iron, potassium
- If a value is 0, still include it (e.g., "Trans Fat 0g")
- Parse numbers carefully - handle decimals, fractions, and various formats

Text to parse:
{raw_text}

Return only valid JSON, no other text. Example format:
{{
  "is_nutrition_label": true,
  "serving_size": "1 Serving (720g)",
  "servings_per_container": 4,
  "nutrients": [
    {{"name": "calories", "value": 570, "unit": "kcal"}},
    {{"name": "total_fat", "value": 16, "unit": "g"}},
    {{"name": "saturated_fat", "value": 2.5, "unit": "g"}},
    {{"name": "trans_fat", "value": 0, "unit": "g"}},
    {{"name": "cholesterol", "value": 155, "unit": "mg"}},
    {{"name": "sodium", "value": 2170, "unit": "mg"}},
    {{"name": "total_carbohydrate", "value": 56, "unit": "g"}},
    {{"name": "dietary_fiber", "value": 7, "unit": "g"}},
    {{"name": "total_sugars", "value": 42, "unit": "g"}},
    {{"name": "added_sugars", "value": 9, "unit": "g"}},
    {{"name": "protein", "value": 53, "unit": "g"}},
    {{"name": "vitamin_d", "value": 0.1, "unit": "mcg"}},
    {{"name": "calcium", "value": 80, "unit": "mg"}},
    {{"name": "iron", "value": 3.4, "unit": "mg"}},
    {{"name": "potassium", "value": 1370, "unit": "mg"}}
  ]
}}"""
        else:
            prompt = f"""Extract food items from the following text and normalize them. 
Return a JSON object with:
- "is_nutrition_label": false
- "food_items": array of food objects, each with: name (normalized food name), quantity (number), unit (g, ml, pieces, etc.), and brand (if mentioned).

Text: {raw_text}

Return only valid JSON, no other text. Example:
{{
  "is_nutrition_label": false,
  "food_items": [
    {{"name": "apple", "quantity": 1, "unit": "piece", "brand": null}},
    {{"name": "whole milk", "quantity": 250, "unit": "ml", "brand": "Organic Valley"}}
  ]
}}"""
        
        try:
            response = await self.client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "format": "json"
                }
            )
            response.raise_for_status()
            result = response.json()
            
            # Extract JSON from response
            import json
            response_text = result.get("response", "")
            print(f"LLM raw response length: {len(response_text)} chars")
            print(f"LLM raw response preview: {response_text[:500]}")
            
            # Try to extract JSON from the response
            try:
                # Remove markdown code blocks if present
                if "```json" in response_text:
                    response_text = response_text.split("```json")[1].split("```")[0]
                elif "```" in response_text:
                    response_text = response_text.split("```")[1].split("```")[0]
                
                parsed = json.loads(response_text.strip())
                print(f"LLM parsed JSON keys: {list(parsed.keys()) if isinstance(parsed, dict) else 'Not a dict'}")
                
                # Handle nutrition label response
                if isinstance(parsed, dict) and parsed.get("is_nutrition_label"):
                    nutrients = parsed.get("nutrients", [])
                    print(f"LLM extracted {len(nutrients)} nutrients from nutrition label")
                    if nutrients:
                        print(f"First few nutrients: {nutrients[:3]}")
                    else:
                        print("WARNING: LLM returned empty nutrients array!")
                    
                    return {
                        "is_nutrition_label": True,
                        "serving_size": parsed.get("serving_size", "1 serving"),
                        "servings_per_container": parsed.get("servings_per_container", 1),
                        "nutrients": nutrients,
                        "food_items": []
                    }
                # Handle food items list response
                elif isinstance(parsed, dict) and "food_items" in parsed:
                    return {
                        "is_nutrition_label": False,
                        "food_items": parsed.get("food_items", [])
                    }
                # Handle raw array (legacy format)
                elif isinstance(parsed, list):
                    return {"is_nutrition_label": False, "food_items": parsed}
                else:
                    print(f"WARNING: LLM returned unexpected format: {type(parsed)}")
                    return {"is_nutrition_label": False, "food_items": []}
            except json.JSONDecodeError as je:
                print(f"LLM JSON decode error: {je}")
                print(f"Failed to parse response text: {response_text[:300]}")
                return {"is_nutrition_label": False, "food_items": []}
        except httpx.TimeoutException as te:
            print(f"LLM request timed out after 120 seconds. Ollama may be slow or the model may not be loaded.")
            print(f"Check if Ollama is running: docker compose ps ollama")
            print(f"Check if model is loaded: docker exec vitalens-ollama ollama list")
            print(f"To load the model, run: docker exec vitalens-ollama ollama pull {self.model}")
            return {"is_nutrition_label": False, "food_items": []}
        except httpx.ConnectError as ce:
            print(f"LLM connection error: Cannot connect to Ollama at {self.base_url}")
            print(f"Check if Ollama service is running: docker compose ps ollama")
            return {"is_nutrition_label": False, "food_items": []}
        except Exception as e:
            print(f"LLM normalization failed: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()
            return {"is_nutrition_label": False, "food_items": []}
    
    async def generate_health_insight(
        self,
        nutrient_summary: Dict[str, float],
        time_period: str = "7 days"
    ) -> Dict[str, str]:
        """
        Generate health insights based on nutrient data.
        Returns explanation and recommendations.
        """
        prompt = f"""Based on the following nutrient intake over {time_period}, provide:
1. A brief explanation of the nutritional status
2. Recommendations for improvement

Nutrient Summary: {nutrient_summary}

IMPORTANT: Do not provide medical diagnosis or treatment advice. Only provide general nutritional information and recommendations.

Return JSON format:
{{
  "explanation": "brief explanation",
  "recommendations": "actionable recommendations"
}}"""
        
        try:
            response = await self.client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "format": "json"
                }
            )
            response.raise_for_status()
            result = response.json()
            
            import json
            response_text = result.get("response", "")
            try:
                if "```json" in response_text:
                    response_text = response_text.split("```json")[1].split("```")[0]
                elif "```" in response_text:
                    response_text = response_text.split("```")[1].split("```")[0]
                
                insight = json.loads(response_text.strip())
                return {
                    "explanation": insight.get("explanation", ""),
                    "recommendations": insight.get("recommendations", "")
                }
            except json.JSONDecodeError:
                return {
                    "explanation": "Unable to generate insight at this time.",
                    "recommendations": "Please consult with a healthcare professional."
                }
        except Exception as e:
            print(f"LLM insight generation failed: {e}")
            return {
                "explanation": "Unable to generate insight at this time.",
                "recommendations": "Please consult with a healthcare professional."
            }
    
    async def explain_risk_score(
        self,
        risk_type: str,
        nutrient_name: str,
        risk_level: str,
        score: float
    ) -> Dict[str, str]:
        """Generate explanation for a risk score"""
        prompt = f"""Explain the following health risk assessment in simple terms:

Risk Type: {risk_type}
Nutrient: {nutrient_name}
Risk Level: {risk_level}
Score: {score}/100

Provide:
1. A clear explanation of what this means
2. Why this risk level was assigned
3. General recommendations (NOT medical advice)

Return JSON:
{{
  "explanation": "explanation text",
  "recommendation": "recommendation text"
}}"""
        
        try:
            response = await self.client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "format": "json"
                }
            )
            response.raise_for_status()
            result = response.json()
            
            import json
            response_text = result.get("response", "")
            try:
                if "```json" in response_text:
                    response_text = response_text.split("```json")[1].split("```")[0]
                elif "```" in response_text:
                    response_text = response_text.split("```")[1].split("```")[0]
                
                explanation = json.loads(response_text.strip())
                return {
                    "explanation": explanation.get("explanation", ""),
                    "recommendation": explanation.get("recommendation", "")
                }
            except json.JSONDecodeError:
                return {
                    "explanation": "Risk assessment completed.",
                    "recommendation": "Please consult with a healthcare professional for personalized advice."
                }
        except Exception as e:
            print(f"LLM risk explanation failed: {e}")
            return {
                "explanation": "Risk assessment completed.",
                "recommendation": "Please consult with a healthcare professional for personalized advice."
            }
    
    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()


# Global LLM service instance
llm_service = LLMService()

