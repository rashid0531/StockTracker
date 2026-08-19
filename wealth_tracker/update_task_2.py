import re

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'r') as f:
    content = f.read()

content = content.replace('- `[ ]` **Phase 2: Data Engineering & Caching**', '- `[x]` **Phase 2: Data Engineering & Caching**')
content = content.replace('  - `[ ]` Install `redis`, `apscheduler`.', '  - `[x]` Install `redis`, `apscheduler`.')
content = content.replace('  - `[ ]` Create `app/services/cache.py` (Redis client).', '  - `[x]` Create `app/services/cache.py` (Redis client).')
content = content.replace('  - `[ ]` Create `app/services/scheduler.py` (6-hour refresh job).', '  - `[x]` Create `app/services/scheduler.py` (6-hour refresh job).')
content = content.replace('  - `[ ]` Implement `POST /admin/force-refresh-market-data`.', '  - `[x]` Implement `POST /admin/force-refresh-market-data`.')

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'w') as f:
    f.write(content)
