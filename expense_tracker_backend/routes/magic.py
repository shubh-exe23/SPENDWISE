import os
import json
from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import db
from models.transaction import Transaction
from models.category import Category  
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

magic_bp = Blueprint('magic', __name__)

class TransactionSchema(BaseModel):
    title: str = Field(description="A short 1-3 word title (e.g., 'Pizza', 'Swiggy', 'Salary').")
    amount: float = Field(description="The numeric amount (e.g., 200.0).")
    is_expense: bool = Field(description="True if spent/paid, False if received/earned (like Salary).")
    date: str = Field(description="Date in YYYY-MM-DD format.")
    category: str = Field(description="The category. You must strictly follow the category rules provided in the prompt.")
    payment_method: str = Field(description="If expense, use Cash, UPI, Credit Card, or Debit Card. If income, use 'Bank Transfer' or 'Cash'.")

@magic_bp.route('/entry', methods=['POST'])
@jwt_required()
def magic_entry():
    data = request.get_json() or {}
    user_text = data.get('text')
    user_id = get_jwt_identity()

    if not user_text:
        return jsonify({'error': 'No text provided.'}), 400

    try:
        client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

        # ── 1. DYNAMICALLY SCAN ALL USER DATA & MERGE WITH DEFAULTS ──
        
        # A. Fetch user's custom categories from the Category table
        user_cats = Category.query.filter_by(user_id=user_id).all()
        db_cat_names = {c.name for c in user_cats}
        
        # B. Fetch historical categories from the user's past transactions
        past_txns = Transaction.query.filter_by(user_id=user_id).with_entities(Transaction.category).distinct().all()
        past_cat_names = {t[0] for t in past_txns if t[0]}

        # C. Inject the Flutter App Defaults to ensure standard buckets always exist
        flutter_defaults = {
            'Food', 'Hobbies', 'Study', 'Travel', 'Extra', 
            'Salary', 'Bank Interest', 'Selling', 'Business', 'Allowance'
        }
        
        # Merge all sources into one comprehensive master list
        valid_categories_list = list(flutter_defaults.union(db_cat_names).union(past_cat_names))
            
        # Lowercase map for safe, case-insensitive matching
        cat_map = {c.lower(): c for c in valid_categories_list}
        categories_str = ", ".join(valid_categories_list)

        # ── 2. SEMANTIC PROMPT ──
        prompt = f"""
        You are a highly intelligent financial extraction AI. Read the user's sentence and extract the transaction details.
        
        RULES:
        1. Today's date is {datetime.now().strftime('%Y-%m-%d')}.
        2. AVAILABLE CATEGORIES: [{categories_str}].
           - You MUST select the SINGLE MOST APPROPRIATE category from the list above.
           - Analyze the item semantically (e.g., 'Choco Moose', 'Pizza', 'Groceries' must be mapped to 'Food').
           - DO NOT invent new categories. Pick the closest logical match from the list.
        3. If the user does not specify a payment method, default to "Cash" for expenses and "Bank Transfer" for income.
        4. Output ONLY raw, valid JSON.
        
        User Input: "{user_text}"
        """

        response = client.models.generate_content(
            model='gemini-3.6-flash', 
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=TransactionSchema,
            ),
        )

        raw_response = response.text.strip()
        if raw_response.startswith('```json'):
            raw_response = raw_response[7:]
        if raw_response.endswith('```'):
            raw_response = raw_response[:-3]
        raw_response = raw_response.strip()

        extracted_data = json.loads(raw_response)
        
        # ── 3. ULTIMATE SAFETY NET ──
        ai_category_raw = extracted_data['category'].strip().lower()
        is_expense = extracted_data['is_expense']
        
        if ai_category_raw in cat_map:
            # Safe match! Restore the exact capitalization
            final_category = cat_map[ai_category_raw] 
        else:
            # If the AI STILL disobeys, force it into a guaranteed bucket
            if is_expense:
                final_category = cat_map.get('food', 'Extra') 
            else:
                final_category = cat_map.get('salary', 'Salary')

        new_txn = Transaction(
            title=extracted_data['title'],
            amount=extracted_data['amount'],
            is_expense=is_expense,
            date=datetime.strptime(extracted_data['date'], '%Y-%m-%d'),
            category=final_category,
            payment_method=extracted_data['payment_method'],
            user_id=user_id
        )

        db.session.add(new_txn)
        db.session.commit()

        return jsonify({
            'message': 'Magic Entry Successful!',
            'transaction': new_txn.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        print(f"\n❌ MAGIC ENTRY ERROR: {str(e)}\n") 
        return jsonify({'error': str(e)}), 500