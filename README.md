# 🥗 VitaLens

<div align="center">

**An AI-powered nutrition and health insight mobile application with intelligent food recognition and personalized health analytics**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Python](https://img.shields.io/badge/Python-3.13-blue.svg)](https://www.python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green.svg)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-lightgrey.svg)](https://developer.apple.com/ios)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com)
[![Ollama](https://img.shields.io/badge/Ollama-Local%20LLM-FF6B6B.svg)](https://ollama.ai)

</div>

---

## 📱 Overview

**VitaLens** is a full-stack nutrition tracking application that leverages AI and machine learning to provide intelligent food recognition, nutrition analysis, and personalized health insights. Built with SwiftUI for iOS and FastAPI for the backend, it enables users to upload food images, nutrition labels, or CSV logs, automatically extract nutritional information using OCR and LLM normalization, and gain actionable health insights through time-series analysis and risk assessment.

### Key Highlights

- 🤖 **AI-Powered Food Recognition**: OCR extraction with LLM-based normalization for accurate food identification
- 📊 **Intelligent Nutrition Analysis**: Time-series nutrient tracking with deficiency and excess detection
- 🔐 **Secure Authentication**: JWT-based authentication with bcrypt password hashing
- 🐳 **Dockerized Services**: Complete containerized backend with PostgreSQL and Ollama
- 🎨 **Modern UI/UX**: Clean, responsive SwiftUI interface with adaptive layouts and light/dark themes
- 📈 **Health Risk Assessment**: Automated risk scoring with safety-aware LLM explanations
- 🔄 **Real-time Analytics**: Interactive charts and trends powered by Swift Charts
- 🏥 **Safety-First Design**: Explicit health disclaimers and no medical diagnosis claims

---

## ✨ Features

### Core Functionality
- **Multi-Format Upload**: Support for food images, nutrition labels (PDF/Image), and CSV logs
- **OCR Text Extraction**: Automatic text extraction using EasyOCR and Tesseract
- **LLM Food Normalization**: Local LLM (Ollama) for intelligent food entity recognition and ingredient decomposition
- **Nutrition Database Mapping**: Integration with USDA FoodData Central API for comprehensive nutrient data
- **Meal Management**: 
  - Create meals with multiple food items
  - Automatic nutrient aggregation
  - Daily and rolling nutrition summaries
- **User Authentication**: Secure registration and login with JWT access and refresh tokens
- **Persistent Storage**: PostgreSQL database with optimized schema for nutrition tracking

### Analytics & Insights
- **Daily Nutrition Dashboard**: Real-time summary of calories, macros, and micronutrients
- **Time-Series Analysis**: Track nutrient trends over time with interactive charts
- **Health Risk Scoring**: Automated detection of nutrient deficiencies and excesses
- **Personalized Insights**: LLM-generated explanations with safety disclaimers
- **Trend Visualization**: Swift Charts integration for visual nutrition analysis

### User Experience
- **Adaptive Layouts**: Dynamic sizing that adapts to iPhone and iPad
- **Theme Support**: Beautiful light and dark modes with "Vital Earth" color system
- **Input Validation**: Comprehensive client-side validation with visual feedback
- **Loading States**: Optimistic UI updates with proper state management
- **Error Handling**: Comprehensive error messages and alerts
- **Simulator-Friendly**: Full functionality in iOS Simulator with FileImporter for uploads

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│   iOS Client    │◄───────►│   FastAPI Backend│◄───────►│   PostgreSQL    │
│   (SwiftUI)     │  REST   │   (Python)       │  Async  │   (Database)    │
└─────────────────┘         └──────────────────┘         └─────────────────┘
      │                              │
      │                              │
      ▼                              ▼
┌─────────────┐              ┌──────────────┐
│  JWT Token  │              │  Ollama LLM  │
│  Storage    │              │  (Local)     │
│ (Keychain)  │              └──────┬───────┘
└─────────────┘                     │
                           ┌────────┴────────┐
                           │                 │
                           ▼                 ▼
                    ┌──────────────┐  ┌──────────────┐
                    │  OCR Service │  │  Nutrition   │
                    │ (EasyOCR/    │  │  Engine      │
                    │  Tesseract)  │  │  (USDA)      │
                    └──────────────┘  └──────────────┘
```

### Data Flow

1. **Upload**: User uploads food image/label/CSV via iOS app
2. **OCR Extraction**: Backend extracts text using OCR service
3. **LLM Normalization**: Local LLM normalizes food entities and decomposes ingredients
4. **Nutrition Mapping**: Food items mapped to USDA FoodData Central API
5. **Aggregation**: Nutrients aggregated at meal and daily levels
6. **Analysis**: Time-series analysis and risk scoring performed
7. **Insights**: LLM generates safety-aware health explanations
8. **Visualization**: iOS app displays data with interactive charts

### Workflow 

1. **User uploads something**  
   They send a photo of food, a nutrition label (image/PDF), or a CSV. We save the file and decide: is it an image, a PDF, or a CSV?

2. **We get text out of it**  
   - **Image or PDF**: We need to “read” the picture → that’s **OCR**.  
     - We **try EasyOCR first** (better for messy/photographed text).  
     - **If EasyOCR fails** (error or empty text), we **automatically switch to Tesseract** and run OCR again.  
     - For PDFs we first convert each page to an image, then run the same OCR on each page.  
   - **CSV**: No OCR — we just read the file as text.

3. **We ask the LLM what’s in that text**  
   We send the raw text to **Ollama** (local LLM). It either:  
   - Detects a **nutrition label** → extracts serving size and all nutrients from the label, or  
   - Treats it as a **list of foods** → returns a list of food names and quantities.  
   So we always end up with structured “food items” and/or nutrients.

4. **We fill in missing nutrition numbers**  
   For each food item we need calories, protein, carbs, etc.  
   - We **try USDA FoodData Central API** first (by food name).  
   - **If we don’t have a USDA API key**, or **USDA doesn’t return a match**, we use **sensible default values** (e.g. average meal estimates) so the app still works and shows something reasonable.

5. **We save everything**  
   We create one **Meal** in the database, attach the **FoodItem(s)** and their **Nutrient** rows, and store it for that user and date. Later we use this for the dashboard, trends, and insights.

---

## 🛠️ Tech Stack

### Frontend (iOS)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Charts**: Swift Charts
- **Networking**: URLSession with async/await
- **Storage**: Keychain for secure token storage
- **Minimum iOS**: 17.0+
- **Theme**: "Vital Earth" color system with light/dark mode support

### Backend (Python)
- **Framework**: FastAPI 0.104.1
- **ASGI Server**: Uvicorn
- **Database**: PostgreSQL 16 (via SQLAlchemy async)
- **ORM**: SQLAlchemy 2.0 with Alembic migrations
- **Authentication**: JWT (python-jose) + bcrypt (passlib)
- **Python Version**: 3.13+

### AI & ML Services
- **LLM**: Ollama (local) - Llama 3.1 / Mistral
- **OCR**: EasyOCR 1.7.0, Tesseract (pytesseract)
- **Image Processing**: OpenCV, Pillow
- **PDF Processing**: pdf2image
- **ML Libraries**: scikit-learn 1.3.2, XGBoost 2.0.2 (optional)

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Database**: PostgreSQL 16 Alpine
- **Services**: 
  - FastAPI backend service
  - PostgreSQL database
  - Ollama LLM service

---

## 🚧 Future Enhancements

- [ ] Receipt scanning with enhanced OCR accuracy
- [ ] Barcode scanning for packaged foods
- [ ] Meal planning and recipe suggestions
- [ ] Social features: share meals and insights
- [ ] Export nutrition data to CSV/PDF
- [ ] Multi-currency and unit conversion
- [ ] Integration with fitness trackers (Apple Health)
- [ ] Advanced ML models for personalized recommendations
- [ ] Widget support for quick meal logging
- [ ] Apple Watch companion app
- [ ] Voice input for meal descriptions
- [ ] Photo gallery for meal history
- [ ] Nutrition goal customization
- [ ] Meal reminders and notifications
- [ ] Family/group nutrition tracking

---

## ⚠️ Health Disclaimer

**Important**: VitaLens is designed for informational and educational purposes only. It does not provide medical advice, diagnosis, or treatment. The health insights and risk assessments generated by the application are based on general nutrition data and should not replace professional medical consultation. Always consult with a qualified healthcare provider before making significant changes to your diet or health routine.

---

## 🙏 Acknowledgments

- **USDA FoodData Central** for comprehensive nutrition database
- **Ollama** for local LLM capabilities
- **EasyOCR** and **Tesseract** for OCR capabilities

---

<div align="center">

**Built with ❤️ using Swift, Python, AI, and Machine Learning**

⭐ Star this repo if you find it helpful!

</div>

