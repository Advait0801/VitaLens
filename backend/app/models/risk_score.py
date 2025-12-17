"""
Risk score model
"""
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


class RiskLevel(str, enum.Enum):
    """Risk level enumeration"""
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class RiskType(str, enum.Enum):
    """Risk type enumeration"""
    DEFICIENCY = "deficiency"
    EXCESS = "excess"
    IMBALANCE = "imbalance"
    ALLERGY = "allergy"
    INTERACTION = "interaction"


class RiskScore(Base):
    """Risk score model for storing health risk assessments"""
    __tablename__ = "risk_scores"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    risk_type = Column(SQLEnum(RiskType), nullable=False, index=True)
    nutrient_name = Column(String, nullable=True, index=True)  # Related nutrient if applicable
    risk_level = Column(SQLEnum(RiskLevel), nullable=False, index=True)
    score = Column(Float, nullable=False)  # Risk score (0-100)
    description = Column(Text, nullable=True)  # Human-readable description
    explanation = Column(Text, nullable=True)  # LLM-generated explanation
    recommendation = Column(Text, nullable=True)  # LLM-generated recommendation
    calculated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

