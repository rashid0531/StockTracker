import re

with open('app/main.py', 'r') as f:
    content = f.read()

import_statement = "from app.routers import market_data, profiles, portfolios, real_estate, health, admin, users, import_ocr\n"
content = re.sub(r"from app\.routers import .*?\n", import_statement, content)

register_statement = "app.include_router(import_ocr.router)\n"
if register_statement not in content:
    content = content.replace("app.include_router(users.router)", "app.include_router(users.router)\n" + register_statement)

with open('app/main.py', 'w') as f:
    f.write(content)
