import re

with open('app/main.py', 'r') as f:
    content = f.read()

content = content.replace('from app.routers import holdings, admin', 'from app.routers import holdings, admin, users')
content = content.replace('app.include_router(admin.router)', 'app.include_router(admin.router)\napp.include_router(users.router)')

with open('app/main.py', 'w') as f:
    f.write(content)
