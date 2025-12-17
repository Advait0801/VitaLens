"""
API dependencies
"""
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User


async def get_db_session() -> AsyncSession:
    """Get database session"""
    async for session in get_db():
        yield session


def get_current_user_dependency() -> User:
    """Get current user dependency"""
    return Depends(get_current_active_user)

