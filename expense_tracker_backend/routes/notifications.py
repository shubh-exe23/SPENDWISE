from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import db
from models.notification import Notification
from datetime import datetime, timedelta

notifications_bp = Blueprint('notifications', __name__, url_prefix='/notifications')

@notifications_bp.route('', methods=['GET'])
@jwt_required()
def get_notifications():
    user_id   = get_jwt_identity()
    week_ago  = datetime.utcnow() - timedelta(days=7)
    # only return last 7 days
    notifs = Notification.query\
        .filter_by(user_id=user_id)\
        .filter(Notification.created_at >= week_ago)\
        .order_by(Notification.created_at.desc())\
        .all()
    return jsonify([n.to_dict() for n in notifs]), 200

@notifications_bp.route('', methods=['POST'])
@jwt_required()
def add_notification():
    user_id = get_jwt_identity()
    data    = request.json
    n = Notification(
        title   = data['title'],
        message = data['message'],
        type    = data['type'],
        user_id = user_id,
    )
    db.session.add(n)
    db.session.commit()
    return jsonify(n.to_dict()), 201

@notifications_bp.route('/clear', methods=['DELETE'])
@jwt_required()
def clear_old_notifications():
    user_id  = get_jwt_identity()
    week_ago = datetime.utcnow() - timedelta(days=7)
    Notification.query\
        .filter_by(user_id=user_id)\
        .filter(Notification.created_at < week_ago)\
        .delete()
    db.session.commit()
    return jsonify({'message': 'cleared'}), 200

@notifications_bp.route('/<int:id>/read', methods=['PUT'])
@jwt_required()
def mark_read(id):
    n         = Notification.query.get_or_404(id)
    n.is_read = True
    db.session.commit()
    return jsonify(n.to_dict()), 200