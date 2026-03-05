"""
Mock database engine BEFORE app imports,
so tests never need a real PostgreSQL connection.
"""

from unittest.mock import MagicMock
import app.database as db_module

# Replace the real engine with a mock so no DB connection is attempted
db_module.engine = MagicMock()
db_module.SessionLocal = MagicMock()
