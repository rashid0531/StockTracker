import re

with open('alembic/env.py', 'r') as f:
    content = f.read()

# Add imports
imports = """from alembic import context

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from app.models import Base
from app.config import settings
"""
content = content.replace('from alembic import context', imports)

# Set target metadata
content = content.replace('target_metadata = None', 'target_metadata = Base.metadata')

# Set database URL
content = content.replace(
    'if config.config_file_name is not None:',
    'config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)\nif config.config_file_name is not None:'
)

with open('alembic/env.py', 'w') as f:
    f.write(content)
