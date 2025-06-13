from pydantic import BaseModel
from datetime import datetime

class ExpenseCreate(BaseModel):
    category: str
    amount: float

class Expense(BaseModel):
    id: int
    category: str
    amount: float
    created_at: datetime  # Changed from str to datetime

    class Config:
        orm_mode = True
        json_encoders = {
            datetime: lambda v: v.isoformat()  # Serializes datetime to ISO format
        }