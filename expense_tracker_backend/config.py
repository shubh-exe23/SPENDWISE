import os
from dotenv import load_dotenv
from pathlib import Path
from datetime import timedelta
# explicitly point to .env file
dotenv_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=dotenv_path)



class Config:
    SQLALCHEMY_DATABASE_URI        = 'postgresql://postgres.wrkyozutykbharblqhok:ArthurIsLegend10@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY                 = 'your_secret_key_change_this'
    JWT_ACCESS_TOKEN_EXPIRES       = timedelta(days=30)