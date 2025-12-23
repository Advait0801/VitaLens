"""
OCR service for extracting text from images and PDFs
"""
import os
from typing import Optional
from pathlib import Path
import easyocr
import pytesseract
from PIL import Image, ImageEnhance, ImageFilter
import pdf2image
import cv2
import numpy as np

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
        """Extract text using EasyOCR with image preprocessing"""
        try:
            # Preprocess image for EasyOCR too
            image = Image.open(image_path)
            processed_image = self._preprocess_image(image)
            
            # Convert to numpy array for EasyOCR
            img_array = np.array(processed_image)
            
            # EasyOCR works better with BGR format for some images
            if len(img_array.shape) == 2:  # Grayscale
                img_array = cv2.cvtColor(img_array, cv2.COLOR_GRAY2RGB)
            
            results = self.easyocr_reader.readtext(img_array)
            text = " ".join([result[1] for result in results])
            
            # Log extracted text for debugging
            print(f"EasyOCR extracted {len(text.strip())} characters")
            if text.strip():
                print(f"EasyOCR preview: {text.strip()[:200]}...")
            else:
                print("WARNING: EasyOCR returned empty text")
            
            return text.strip()
        except Exception as e:
            print(f"EasyOCR failed: {e}, falling back to Tesseract")
            return await self._extract_with_tesseract(image_path)
    
    def _preprocess_image(self, image: Image.Image) -> Image.Image:
        """
        Preprocess image for better OCR accuracy.
        Converts to grayscale, enhances contrast, and applies denoising.
        Works well for both regular images and high-contrast nutrition labels.
        """
        try:
            # Convert to RGB if needed (handle RGBA, L, etc.)
            if image.mode != 'RGB':
                rgb_image = Image.new('RGB', image.size, (255, 255, 255))
                if image.mode == 'RGBA':
                    rgb_image.paste(image, mask=image.split()[3])  # Use alpha channel as mask
                else:
                    rgb_image.paste(image)
                image = rgb_image
            
            # Convert to numpy array for OpenCV processing
            img_array = np.array(image)
            
            # Convert to grayscale
            if len(img_array.shape) == 3:
                gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
            else:
                gray = img_array
            
            # Check image characteristics to choose best preprocessing
            # For high-contrast images (like nutrition labels), use adaptive thresholding
            # For regular images, use different approach
            
            # Calculate contrast (standard deviation)
            contrast = np.std(gray)
            
            if contrast > 50:  # High contrast image (likely nutrition label)
                # Apply adaptive thresholding for better text detection
                # This works well for black text on white background
                thresh = cv2.adaptiveThreshold(
                    gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                    cv2.THRESH_BINARY, 11, 2
                )
                processed = thresh
            else:  # Regular image, use different approach
                # Apply slight Gaussian blur to reduce noise
                blurred = cv2.GaussianBlur(gray, (3, 3), 0)
                # Apply OTSU thresholding
                _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
                processed = thresh
            
            # Apply denoising to reduce artifacts
            try:
                denoised = cv2.fastNlMeansDenoising(processed, h=10)
            except:
                denoised = processed  # If denoising fails, use thresholded image
            
            # Convert back to PIL Image
            processed_image = Image.fromarray(denoised)
            
            # Enhance contrast slightly (don't overdo it)
            enhancer = ImageEnhance.Contrast(processed_image)
            processed_image = enhancer.enhance(1.2)
            
            return processed_image
        except Exception as e:
            print(f"Image preprocessing failed: {e}, using original image")
            return image
    
    async def _extract_with_tesseract(self, image_path: str) -> str:
        """Extract text using Tesseract with image preprocessing"""
        try:
            image = Image.open(image_path)
            
            # Preprocess image for better OCR
            processed_image = self._preprocess_image(image)
            
            # Use Tesseract with optimized configuration for structured text
            # PSM 6: Assume uniform block of vertically aligned text (good for nutrition labels)
            # PSM 11: Sparse text (fallback)
            custom_config = r'--oem 3 --psm 6'
            
            text = pytesseract.image_to_string(processed_image, config=custom_config)
            
            # If we get very little text, try with a different PSM mode
            if len(text.strip()) < 50:
                print(f"Initial OCR returned limited text ({len(text.strip())} chars), trying PSM 11")
                custom_config = r'--oem 3 --psm 11'
                text_alt = pytesseract.image_to_string(processed_image, config=custom_config)
                if len(text_alt.strip()) > len(text.strip()):
                    text = text_alt
            
            # Log extracted text for debugging (first 500 chars)
            print(f"OCR extracted {len(text.strip())} characters")
            if text.strip():
                print(f"OCR preview: {text.strip()[:200]}...")
            else:
                print("WARNING: OCR returned empty text")
            
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
                    # Preprocess PDF images too
                    processed_image = self._preprocess_image(image)
                    custom_config = r'--oem 3 --psm 6'
                    text = pytesseract.image_to_string(processed_image, config=custom_config)
                all_text.append(text)
            
            return "\n".join(all_text).strip()
        except Exception as e:
            raise Exception(f"PDF extraction failed: {e}")
    
    async def _extract_with_easyocr_from_image(self, image) -> str:
        """Extract text from PIL Image using EasyOCR with preprocessing"""
        try:
            # Preprocess image for better accuracy
            processed_image = self._preprocess_image(image)
            img_array = np.array(processed_image)
            
            # EasyOCR works better with RGB format
            if len(img_array.shape) == 2:  # Grayscale
                img_array = cv2.cvtColor(img_array, cv2.COLOR_GRAY2RGB)
            
            results = self.easyocr_reader.readtext(img_array)
            text = " ".join([result[1] for result in results])
            return text.strip()
        except Exception as e:
            print(f"EasyOCR from image failed: {e}, falling back to Tesseract")
            processed_image = self._preprocess_image(image)
            custom_config = r'--oem 3 --psm 6'
            return pytesseract.image_to_string(processed_image, config=custom_config)


# Global OCR service instance
ocr_service = OCRService()

