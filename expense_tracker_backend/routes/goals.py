from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import db
from models.goal import Goal
from datetime import datetime

goals_bp = Blueprint('goals', __name__, url_prefix='/goals')

@goals_bp.route('', methods=['GET'])
@jwt_required()
def get_goals():
    user_id = get_jwt_identity()
    goals   = Goal.query.filter_by(user_id=user_id).all()
    return jsonify([g.to_dict() for g in goals]), 200

@goals_bp.route('', methods=['POST'])
@jwt_required()
def add_goal():
    user_id = get_jwt_identity()
    data    = request.json
    g = Goal(
        name          = data['name'],
        category      = data['category'],
        budget_amount = data['budget_amount'],
        start_date    = datetime.fromisoformat(data['start_date']),
        end_date      = datetime.fromisoformat(data['end_date']),
        alert_threshold = data.get('alert_threshold', None),
        user_id       = user_id,
    )
    db.session.add(g)
    db.session.commit()
    return jsonify(g.to_dict()), 201

@goals_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_goal(id):
    g    = Goal.query.get_or_404(id)
    data = request.json
    g.name          = data.get('name',          g.name)
    g.category      = data.get('category',      g.category)
    g.budget_amount = data.get('budget_amount', g.budget_amount)
    g.start_date    = datetime.fromisoformat(data['start_date']) if 'start_date' in data else g.start_date
    g.end_date      = datetime.fromisoformat(data['end_date'])   if 'end_date'   in data else g.end_date
    db.session.commit()
    return jsonify(g.to_dict()), 200

@goals_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_goal(id):
    g = Goal.query.get_or_404(id)
    db.session.delete(g)
    db.session.commit()
    return jsonify({'message': 'deleted'}), 200