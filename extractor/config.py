import os
from dotenv import load_dotenv

# This reads your .env file and loads all the variables into memory
load_dotenv()

# ERP API settings
API_KEY = os.getenv("API_KEY")
API_BASE_URL = os.getenv("API_BASE_URL")

# How many records to fetch per API request
PAGE_LIMIT = 100

# How many times to retry a failed API request
MAX_RETRIES = 5

# List of all 9 entities we need to extract from the API
ENTITIES = [
    "customers",
    "products",
    "stores",
    "employees",
    "orders",
    "order_items",
    "payments",
    "inventory_movements",
    "payment_methods",
]

# Lake database connection settings
LAKE_DB = {
    "host": os.getenv("LAKE_HOST", "localhost"),
    "port": os.getenv("LAKE_PORT", "5433"),
    "dbname": os.getenv("LAKE_DB", "lake"),
    "user": os.getenv("LAKE_USER", "lake_user"),
    "password": os.getenv("LAKE_PASSWORD", "lake_pass"),
}