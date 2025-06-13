from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from app import models, schemas, crud, database

models.Base.metadata.create_all(bind=database.engine)
app = FastAPI()

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/expenses/", response_model=schemas.Expense)
def add_expense(expense: schemas.ExpenseCreate, db: Session = Depends(get_db)):
    return crud.create_expense(db, expense)

@app.get("/expenses/", response_model=list[schemas.Expense])
def list_expenses(db: Session = Depends(get_db)):
    return crud.get_expenses(db)

@app.delete("/expenses/{expense_id}")
def delete_expense(expense_id: int, db: Session = Depends(get_db)):
    if crud.delete_expense(db, expense_id):
        return {"message": "Expense deleted successfully"}
    raise HTTPException(status_code=404, detail="Expense not found")