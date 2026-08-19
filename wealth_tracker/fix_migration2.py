import os

migration_dir = "alembic/versions"
for filename in os.listdir(migration_dir):
    if filename.endswith(".py") and "add_hashed_password" in filename:
        filepath = os.path.join(migration_dir, filename)
        content = """from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'ee120976b474'
down_revision: Union[str, None] = 'ae44a6df6a38'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.add_column('users', sa.Column('hashed_password', sa.String(length=255), nullable=True))

def downgrade() -> None:
    op.drop_column('users', 'hashed_password')
"""
        with open(filepath, "w") as f:
            f.write(content)
