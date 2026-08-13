from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import db
from models.transaction import Transaction
from datetime import datetime

transactions_bp = Blueprint('transactions', __name__, url_prefix='/transactions')

@transactions_bp.route('', methods=['GET'])
@jwt_required()
def get_transactions():
    try:
        user_id = get_jwt_identity()
        transactions = Transaction.query.filter_by(user_id=user_id).all()
        return jsonify([t.to_dict() for t in transactions]), 200
    except Exception as e:
        print(f"Error fetching transactions: {e}")
        return jsonify({'message': str(e)}), 500


@transactions_bp.route('', methods=['POST'])
@jwt_required()
def add_transaction():
    try:
        user_id = get_jwt_identity()
        data = request.get_json() or {}

        title = data.get('title')
        amount = data.get('amount')
        category = data.get('category')
        date_str = data.get('date')
        is_expense = data.get('is_expense', True)

        if not title or amount is None or not category or not date_str:
            return jsonify({'message': 'Missing required fields'}), 400

        # Parse ISO 8601 string sent by date.toIso8601String()
        try:
            parsed_date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        except ValueError:
            parsed_date = datetime.now()

        t = Transaction(
            title=title,
            amount=float(amount),
            is_expense=bool(is_expense),
            date=parsed_date,
            category=category,
            user_id=user_id,
        )

        db.session.add(t)
        db.session.commit()
        return jsonify(t.to_dict()), 201

    except Exception as e:
        db.session.rollback()
        print(f"Error saving transaction: {e}")
        return jsonify({'message': 'Failed to save transaction', 'error': str(e)}), 500


@transactions_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_transaction(id):
    try:
        t = Transaction.query.get_or_404(id)
        db.session.delete(t)
        db.session.commit()
        return jsonify({'message': 'deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@transactions_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_transaction(id):
    try:
        t = Transaction.query.get_or_404(id)
        data = request.get_json() or {}

        t.title = data.get('title', t.title)
        t.amount = data.get('amount', t.amount)
        t.is_expense = data.get('is_expense', t.is_expense)
        t.category = data.get('category', t.category)

        db.session.commit()
        return jsonify(t.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500