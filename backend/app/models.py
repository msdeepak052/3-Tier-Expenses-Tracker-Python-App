from sqlalchemy import Column, Integer, String, Float, DateTime, func
from app.database import Base

class Expense(Base):
    __tablename__ = "expenses"
    
    id = Column(Integer, primary_key=True, index=True)
    category = Column(String, index=True)
    amount = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())