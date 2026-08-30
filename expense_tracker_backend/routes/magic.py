import os
import json
from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import db
from models.transaction import Transaction
from models.category import Category
from models.goal import Goal 
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

magic_bp = Blueprint('magic', __name__)

class TransactionSchema(BaseModel):
    title: str = Field(description="A short 1-3 word title (e.g., 'Cabbage', 'Masala Dosa', 'Salary').")
    amount: float = Field(description="The numeric amount (e.g., 50.0).")
    is_expense: bool = Field(description="True if spent/paid, False if received/earned.")
    date: str = Field(description="Date in YYYY-MM-DD format.")
    category: str = Field(description="The category strictly matching one of the available category options.")
    payment_method: str = Field(description="If expense, use Cash, UPI, Credit Card, or Debit Card. If income, use Bank Transfer or Cash.")

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

        user_cats = Category.query.filter_by(user_id=user_id).all()
        db_cat_names = {c.name for c in user_cats if c.name}
        
        user_goals = Goal.query.filter_by(user_id=user_id).all()
        db_goal_names = {g.name for g in user_goals if g.name}
        
        past_txns = Transaction.query.filter_by(user_id=user_id).with_entities(Transaction.category).distinct().all()
        past_cat_names = {t[0] for t in past_txns if t[0]}

        flutter_defaults = {
            'Food', 'Hobbies', 'Study', 'Travel', 'Extra', 
            'Salary', 'Bank Interest', 'Selling', 'Business', 'Allowance'
        }
        
        valid_categories_list = list(flutter_defaults.union(db_cat_names).union(past_cat_names).union(db_goal_names))
        cat_map = {c.lower(): c for c in valid_categories_list}
        categories_str = ", ".join(valid_categories_list)

        knowledge_base = {
            "cabbage": 'Text: "spent 50 on cabbage" -> Category: Vegetables (or Groceries / Food if Vegetables is not in available list)',
            "vegetable": 'Text: "bought vegetables" -> Category: Vegetables (or Groceries / Food)',
            "potato": 'Text: "potatoes" -> Category: Vegetables (or Groceries / Food)',
            "onion": 'Text: "onions" -> Category: Vegetables (or Groceries / Food)',
            "dosa": 'Text: "masala dosa" -> Category: Dining Out (or Food. NEVER Groceries)',
            "restaurant": 'Text: "dinner at restaurant" -> Category: Dining Out (or Food)',
            "swiggy": 'Text: "swiggy order" -> Category: Dining Out (or Food)',
            "zomato": 'Text: "zomato" -> Category: Dining Out (or Food)',
            "rice": 'Text: "10kg rice" -> Category: Groceries (or Food)',
            "dal": 'Text: "dal and oil" -> Category: Groceries (or Food)',
            "electricity": 'Text: "electricity bill" -> Category: Bills',
            "netflix": 'Text: "netflix subscription" -> Category: Bills (or Entertainment)'
        }

        user_text_lower = user_text.lower()
        relevant_examples = [ex for kw, ex in knowledge_base.items() if kw in user_text_lower]

        recent_txns = Transaction.query.filter_by(user_id=user_id).order_by(Transaction.date.desc()).limit(3).all()
        personal_examples = [f'Text: "{t.title}" -> Category: {t.category}' for t in recent_txns if t.category]

        dynamic_prompt = ""
        if relevant_examples or personal_examples:
            dynamic_prompt += "\nDYNAMIC FEW-SHOT CONTEXT:\n"
            if relevant_examples:
                dynamic_prompt += "Precision Rules for this input:\n- " + "\n- ".join(relevant_examples) + "\n"
            if personal_examples:
                dynamic_prompt += "User's Recent Categorization Style:\n- " + "\n- ".join(personal_examples) + "\n"

        prompt = f"""
        You are an intelligent financial transaction parser. Extract details from the input sentence.
        
        RULES:
        1. Today's date is {datetime.now().strftime('%Y-%m-%d')}.
        2. AVAILABLE CATEGORIES: [{categories_str}]. You MUST select the SINGLE MOST APPROPRIATE category from this list.
        3. CATEGORIZATION HIERARCHY:
           - Raw produce (e.g., cabbage, onions, potatoes): Map to "Vegetables" if available. If not, map to "Groceries". If neither exists, fallback to "Food". NEVER map raw produce to "Dining Out".
           - Prepared/Cooked meals (e.g., Masala Dosa, Pizza, Restaurant meals): Map to "Dining Out" if available, else "Food". NEVER map to "Groceries" or "Vegetables".
        4. If payment method is not specified, default to "UPI" or "Cash" for expenses, and "Bank Transfer" for income.
        {dynamic_prompt}
        
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

        raw_response = response.text.strip().replace('```json', '').replace('```', '').strip()
        extracted_data = json.loads(raw_response)
        
        ai_category_raw = extracted_data['category'].strip().lower()
        is_expense = extracted_data['is_expense']
        
        if ai_category_raw in cat_map:
            final_category = cat_map[ai_category_raw] 
        else:
            final_category = cat_map.get('food', 'Extra') if is_expense else cat_map.get('salary', 'Salary')

        new_txn = Transaction(
            title=extracted_data['title'],
            amount=float(extracted_data['amount']),
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
        return jsonify({'error': str(e)}), 500