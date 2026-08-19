import re

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'r') as f:
    content = f.read()

content = content.replace('- `[ ]` **Phase 4: Observability**', '- `[x]` **Phase 4: Observability**')
content = content.replace('  - `[ ]` Install `structlog`.', '  - `[x]` Install `structlog`.')
content = content.replace('  - `[ ]` Create `app/logger.py` and integrate into `main.py`.', '  - `[x]` Create `app/logger.py` and integrate into `main.py`.')

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'w') as f:
    f.write(content)
