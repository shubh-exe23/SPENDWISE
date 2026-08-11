from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import Config
from models.database import db

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

from routes.auth          import auth_bp
from routes.transactions  import transactions_bp
from routes.goals         import goals_bp
from routes.notifications import notifications_bp

app.register_blueprint(auth_bp)
app.register_blueprint(transactions_bp)
app.register_blueprint(goals_bp)
app.register_blueprint(notifications_bp)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print('Database created successfully')
    app.run(debug=True)