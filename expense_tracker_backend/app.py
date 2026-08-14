from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager, jwt_required, get_jwt_identity
from config import Config
from models.database import db
from datetime import datetime, timedelta

app = Flask(__name__)
app.config.from_object(Config)

CORS(app)
JWTManager(app)
db.init_app(app)

# import models explicitly here
from models.user         import User
from models.transaction  import Transaction
from models.goal         import Goal
from models.notification import Notification

@app.route('/')
def index():
    return {'message': 'Expense Tracker API is running!'}, 200

@app.route('/api/transactions/clear', methods=['DELETE'])
@jwt_required()
def clear_transactions():
    user_id = get_jwt_identity()
    period = request.args.get('period', 'All Time')
    
    now = datetime.utcnow()
    
    # Start the base SQLAlchemy query for this user
    query = Transaction.query.filter_by(user_id=user_id)
    
    if period == 'Today':
        start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.filter(Transaction.date >= start_of_day)
    elif period == 'Yesterday':
        yesterday_start = (now - timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        yesterday_end = now.replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.filter(Transaction.date >= yesterday_start, Transaction.date < yesterday_end)
    elif period == 'This Week':
        start_of_week = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.filter(Transaction.date >= start_of_week)
    elif period == 'This Month':
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        query = query.filter(Transaction.date >= start_of_month)
    # 'All Time' keeps the query as is, affecting all user transactions

    # Execute the delete and commit to PostgreSQL
    deleted_count = query.delete()
    db.session.commit()
    
    return jsonify({"message": f"Cleared {deleted_count} transactions for {period}"}), 200

from routes.auth          import auth_bp
from routes.transactions  import transactions_bp
from routes.goals         import goals_bp
from routes.notifications import notifications_bp

app.register_blueprint(auth_bp,url_prefix='/auth')
app.register_blueprint(transactions_bp)
app.register_blueprint(goals_bp)
app.register_blueprint(notifications_bp)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print('Database created successfully')
    app.run(host='0.0.0.0', port=5000, debug=True)