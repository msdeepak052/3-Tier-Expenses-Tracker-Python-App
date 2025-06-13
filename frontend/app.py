from flask import Flask, render_template, request, flash, redirect, url_for
import requests
from datetime import datetime
import socket

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'

API_URL = "http://backend:8000"

def get_server_info():
    """Get hostname and IP address of the server"""
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    return {
        'hostname': hostname,
        'ip_address': ip_address
    }

def format_expense_date(expense):
    """Format the datetime string for display"""
    if 'created_at' in expense:
        try:
            dt = datetime.fromisoformat(expense['created_at'].replace('Z', '+00:00'))
            expense['formatted_date'] = dt.strftime("%b %d, %Y %H:%M")
        except (ValueError, AttributeError):
            expense['formatted_date'] = ""
    return expense

@app.route("/", methods=["GET", "POST"])
def index():
    expenses = []
    total = 0
    server_info = get_server_info()
    
    try:
        if request.method == "POST":
            category = request.form.get("category", "").strip()
            amount = request.form.get("amount", "0").strip()
            
            if not category or not amount:
                flash("Both category and amount are required", "danger")
            else:
                try:
                    amount_float = float(amount)
                    response = requests.post(
                        f"{API_URL}/expenses/",
                        json={"category": category, "amount": amount_float},
                        timeout=5
                    )
                    response.raise_for_status()
                    flash("Expense added successfully!", "success")
                except (ValueError, requests.exceptions.RequestException) as e:
                    flash(f"Error adding expense: {str(e)}", "danger")

        # Get current expenses
        response = requests.get(f"{API_URL}/expenses/", timeout=5)
        response.raise_for_status()
        expenses = [format_expense_date(e) for e in response.json()]
        total = sum(e["amount"] for e in expenses)
        
    except requests.exceptions.RequestException as e:
        flash(f"Error connecting to backend: {str(e)}", "danger")
    
    return render_template(
        "index.html", 
        expenses=expenses, 
        total=total,
        server_info=server_info
    )

@app.route("/expenses/<int:expense_id>/delete", methods=["POST"])
def delete_expense(expense_id):
    try:
        response = requests.delete(f"{API_URL}/expenses/{expense_id}", timeout=5)
        response.raise_for_status()
        flash("Expense deleted successfully!", "success")
    except requests.exceptions.RequestException as e:
        flash(f"Error deleting expense: {str(e)}", "danger")
    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)