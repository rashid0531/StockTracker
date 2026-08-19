from typing import Sequence, Union

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
