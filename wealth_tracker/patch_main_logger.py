import re

with open('app/main.py', 'r') as f:
    content = f.read()

imports = """from fastapi import FastAPI
from app.logger import setup_logging
setup_logging()
"""
content = content.replace("from fastapi import FastAPI", imports)

with open('app/main.py', 'w') as f:
    f.write(content)
