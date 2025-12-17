from contextlib import asynccontextmanager
from typing import AsyncGenerator
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from app.core.config import settings
from app.core.database import engine, async_session_maker


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """
    Lifespan context manager for startup and shutdown events.
    """
    # Startup: Test database connection
    try:
        async with async_session_maker() as session:
            result = await session.execute(text("SELECT 1"))
            result.scalar()
        print("✓ Database connection established")
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
    
    yield
    
    # Shutdown: Close database connections
    await engine.dispose()
    print("✓ Database connections closed")


# Initialize FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    description="AI-powered nutrition and health insight API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware
# Handle CORS origins: split by comma or use ["*"] if wildcard
if settings.CORS_ORIGINS == "*":
    cors_origins = ["*"]
    # If using wildcard, credentials must be False
    cors_credentials = False
else:
    cors_origins = [origin.strip() for origin in settings.CORS_ORIGINS.split(",")]
    cors_credentials = settings.CORS_ALLOW_CREDENTIALS

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=cors_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to VitaLens API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint for Docker health checks.
    Tests database connectivity.
    """
    try:
        async with async_session_maker() as session:
            result = await session.execute(text("SELECT 1"))
            result.scalar()
        
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "status": "healthy",
                "database": "connected",
            }
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "unhealthy",
                "database": "disconnected",
                "error": str(e),
            }
        )


@app.get("/api/v1/health", tags=["Health"])
async def health_check_v1():
    """Versioned health check endpoint"""
    return await health_check()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
    )