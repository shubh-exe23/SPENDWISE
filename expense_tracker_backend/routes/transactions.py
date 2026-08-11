from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import db
from models.transaction import Transaction
from datetime import datetime

transactions_bp = Blueprint('transactions', __name__, url_prefix='/transactions')

@transactions_bp.route('', methods=['GET'])
@jwt_required()
def get_transactions():
    user_id = get_jwt_identity()
    transactions = Transaction.query.filter_by(user_id=user_id).all()
    return jsonify([t.to_dict() for t in transactions]), 200

@transactions_bp.route('', methods=['POST'])
@jwt_required()
def add_transaction():
    user_id = get_jwt_identity()
    data    = request.json
    t = Transaction(
        title      = data['title'],
        amount     = data['amount'],
        is_expense = data['is_expense'],
        date       = datetime.fromisoformat(data['date']),
        category   = data['category'],
        user_id    = user_id,
    )
    db.session.add(t)
    db.session.commit()
    return jsonify(t.to_dict()), 201

@transactions_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_transaction(id):
    t = Transaction.query.get_or_404(id)
    db.session.delete(t)
    db.session.commit()
    return jsonify({'message': 'deleted'}), 200

@transactions_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_transaction(id):
    t    = Transaction.query.get_or_404(id)
    data = request.json
    t.title      = data.get('title',      t.title)
    t.amount     = data.get('amount',     t.amount)
    t.is_expense = data.get('is_expense', t.is_expense)
    t.category   = data.get('category',   t.category)
    db.session.commit()
    return jsonify(t.to_dict()), 200