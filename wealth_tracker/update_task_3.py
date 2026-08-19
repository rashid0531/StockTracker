import re

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'r') as f:
    content = f.read()

content = content.replace('- `[ ]` **Phase 3: Authentication & Security (JWT)**', '- `[x]` **Phase 3: Authentication & Security (JWT)**')
content = content.replace('  - `[ ]` Install `PyJWT`, `passlib`, `bcrypt`.', '  - `[x]` Install `PyJWT`, `passlib`, `bcrypt`.')
content = content.replace('  - `[ ]` Add `hashed_password` to `User` model.', '  - `[x]` Add `hashed_password` to `User` model.')
content = content.replace('  - `[ ]` Create `app/auth.py` for token generation.', '  - `[x]` Create `app/auth.py` for token generation.')
content = content.replace('  - `[ ]` Create `/register` and `/token` routes.', '  - `[x]` Create `/register` and `/token` routes.')
content = content.replace('  - `[ ]` Secure endpoints with `Depends(get_current_user)`.', '  - `[x]` Secure endpoints with `Depends(get_current_user)`.')

with open('/Users/rashid/.gemini/antigravity/brain/699e2fbd-b06f-40cf-be3b-dbb8b54df6b7/task.md', 'w') as f:
    f.write(content)
