import re

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'r') as f:
    content = f.read()

content = content.replace('- `[ ]` **Phase 5: Dockerization**', '- `[x]` **Phase 5: Dockerization**')
content = content.replace('  - `[ ]` Finalize `requirements.txt`.', '  - `[x]` Finalize `requirements.txt`.')
content = content.replace('  - `[ ]` Create `Dockerfile`.', '  - `[x]` Create `Dockerfile`.')
content = content.replace('  - `[ ]` Create `docker-compose.yml`.', '  - `[x]` Create `docker-compose.yml`.')

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'w') as f:
    f.write(content)
