import re

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'r') as f:
    content = f.read()

content = content.replace('- `[ ]` **Phase 1: Database Migrations (Alembic)**', '- `[x]` **Phase 1: Database Migrations (Alembic)**')
content = content.replace('  - `[ ]` Install Alembic (`pip install alembic`).', '  - `[x]` Install Alembic (`pip install alembic`).')
content = content.replace('  - `[ ]` Initialize Alembic (`alembic init -t async alembic`).', '  - `[x]` Initialize Alembic (`alembic init -t async alembic`).')
content = content.replace('  - `[ ]` Configure `alembic/env.py` and `alembic.ini`.', '  - `[x]` Configure `alembic/env.py` and `alembic.ini`.')
content = content.replace('  - `[ ]` Generate baseline migration (`alembic revision --autogenerate -m "Baseline"`).', '  - `[x]` Generate baseline migration (`alembic revision --autogenerate -m "Baseline"`).')

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'w') as f:
    f.write(content)
