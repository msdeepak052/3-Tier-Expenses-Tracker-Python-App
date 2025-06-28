from flask import Flask, render_template, request, flash, redirect, url_for
import requests
from datetime import datetime
import socket

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'

API_URL = "http://backend:8000"

import socket
import os

def get_server_info():
    """Get container and host info (works for Docker/Kubernetes)"""
    # Container info (always available)
    container_hostname = socket.gethostname()
    container_ip = socket.gethostbyname(container_hostname)
    
    # Host machine info (cross-platform method)
    host_hostname = "N/A"
    host_ip = "N/A"
    
    try:
        # Method 1: Use Docker's host.docker.internal (macOS/Windows)
        try:
            host_ip = socket.gethostbyname("host.docker.internal")
            host_hostname = "host.docker.internal"
        except socket.gaierror:
            # Method 2: Use default gateway (Linux)
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 53))  # Google DNS
                host_ip = s.getsockname()[0]  # Gets host's LAN IP
                host_hostname = socket.gethostbyaddr(host_ip)[0]  # Gets hostname
    except Exception:
        pass  # Fallback to N/A if detection fails
    
    return {
        'container': {
            'hostname': container_hostname,
            'ip': container_ip
        },
        'infra_host': {
            'hostname': host_hostname,
            'ip': host_ip
        }
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