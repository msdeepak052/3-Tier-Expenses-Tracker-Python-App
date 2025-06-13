from sqlalchemy.orm import Session
from app import models, schemas

def get_expenses(db: Session):
    return db.query(models.Expense).order_by(models.Expense.created_at.desc()).all()

def create_expense(db: Session, expense: schemas.ExpenseCreate):
    db_exp = models.Expense(**expense.dict())
    db.add(db_exp)
    db.commit()
    db.refresh(db_exp)
    return db_exp

def delete_expense(db: Session, expense_id: int):
    expense = db.query(models.Expense).filter(models.Expense.id == expense_id).first()
    if expense:
        db.delete(expense)
        db.commit()
        return True
    return False