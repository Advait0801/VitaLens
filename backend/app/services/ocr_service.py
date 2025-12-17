"""
OCR service for extracting text from images and PDFs
"""
import os
from typing import Optional
from pathlib import Path
import easyocr
import pytesseract
from PIL import Image
import pdf2image

from app.core.config import settings


class OCRService:
    """Service for OCR operations"""
    
    def __init__(self):
        self.engine = settings.OCR_ENGINE.lower()
        self.easyocr_reader = None
        
        if self.engine == "easyocr":
            try:
                self.easyocr_reader = easyocr.Reader(['en'], gpu=False)
            except Exception as e:
                print(f"Warning: EasyOCR initialization failed: {e}")
                print("Falling back to Tesseract")
                self.engine = "tesseract"
    
    async def extract_text_from_image(self, image_path: str) -> str:
        """Extract text from an image file"""
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found: {image_path}")
        
        if self.engine == "easyocr" and self.easyocr_reader:
            return await self._extract_with_easyocr(image_path)
        else:
            return await self._extract_with_tesseract(image_path)
    
    async def _extract_with_easyocr(self, image_path: str) -> str:
        """Extract text using EasyOCR"""
        try:
            results = self.easyocr_reader.readtext(image_path)
            text = " ".join([result[1] for result in results])
            return text.strip()
        except Exception as e:
            print(f"EasyOCR failed: {e}, falling back to Tesseract")
            return await self._extract_with_tesseract(image_path)
    
    async def _extract_with_tesseract(self, image_path: str) -> str:
        """Extract text using Tesseract"""
        try:
            image = Image.open(image_path)
            text = pytesseract.image_to_string(image)
            return text.strip()
        except Exception as e:
            raise Exception(f"Tesseract OCR failed: {e}")
    
    async def extract_text_from_pdf(self, pdf_path: str) -> str:
        """Extract text from a PDF file"""
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF file not found: {pdf_path}")
        
        try:
            # Convert PDF to images
            images = pdf2image.convert_from_path(pdf_path)
            all_text = []
            
            for image in images:
                if self.engine == "easyocr" and self.easyocr_reader:
                    text = await self._extract_with_easyocr_from_image(image)
                else:
                    text = pytesseract.image_to_string(image)
                all_text.append(text)
            
            return "\n".join(all_text).strip()
        except Exception as e:
            raise Exception(f"PDF extraction failed: {e}")
    
    async def _extract_with_easyocr_from_image(self, image) -> str:
        """Extract text from PIL Image using EasyOCR"""
        try:
            import numpy as np
            img_array = np.array(image)
            results = self.easyocr_reader.readtext(img_array)
            text = " ".join([result[1] for result in results])
            return text.strip()
        except Exception as e:
            print(f"EasyOCR from image failed: {e}, falling back to Tesseract")
            return pytesseract.image_to_string(image)


# Global OCR service instance
ocr_service = OCRService()

