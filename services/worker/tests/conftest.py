"""
Override slow mock executor settings for fast CI tests.
"""

import os

os.environ["MOCK_EXEC_TIMEOUT"] = "0"
os.environ["MOCK_EXEC_MAX_MEMORY_MB"] = "1"
