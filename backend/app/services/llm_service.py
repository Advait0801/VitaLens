"""
LLM service for food normalization and health insights
"""
import httpx
from typing import List, Dict, Optional
from app.core.config import settings


class LLMService:
    """Service for interacting with Ollama LLM"""
    
    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = settings.OLLAMA_MODEL
        self.client = httpx.AsyncClient(timeout=60.0)
    
    async def normalize_food_text(self, raw_text: str) -> Dict[str, any]:
        """
        Normalize food text using LLM to extract structured food information.
        Returns a list of food items with normalized names and quantities.
        """
        prompt = f"""Extract food items from the following text and normalize them. 
Return a JSON array of food objects, each with: name (normalized food name), quantity (number), unit (g, ml, pieces, etc.), and brand (if mentioned).

Text: {raw_text}

Return only valid JSON array, no other text. Example format:
[
  {{"name": "apple", "quantity": 1, "unit": "piece", "brand": null}},
  {{"name": "whole milk", "quantity": 250, "unit": "ml", "brand": "Organic Valley"}}
]"""
        
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
            # Try to extract JSON from the response
            try:
                # Remove markdown code blocks if present
                if "```json" in response_text:
                    response_text = response_text.split("```json")[1].split("```")[0]
                elif "```" in response_text:
                    response_text = response_text.split("```")[1].split("```")[0]
                
                food_items = json.loads(response_text.strip())
                return {"food_items": food_items if isinstance(food_items, list) else []}
            except json.JSONDecodeError:
                return {"food_items": []}
        except Exception as e:
            print(f"LLM normalization failed: {e}")
            return {"food_items": []}
    
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

