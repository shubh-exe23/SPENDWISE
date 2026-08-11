from models.database import db
from datetime import datetime


class User(db.Model):
    __tablename__ = 'users'

    id         = db.Column(db.Integer, primary_key=True)
    email      = db.Column(db.String(120), unique=True, nullable=False)
    password   = db.Column(db.String(200), nullable=False)
    name       = db.Column(db.String(100), default='User')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # relationships
    transactions  = db.relationship('Transaction',  backref='user', lazy=True)
    goals         = db.relationship('Goal',         backref='user', lazy=True)
    notifications = db.relationship('Notification', backref='user', lazy=True)

    def to_dict(self):
        return {
            'id':    self.id,
            'email': self.email,
            'name':  self.name,
        }