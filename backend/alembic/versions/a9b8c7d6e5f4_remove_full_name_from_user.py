"""remove full_name from user

Revision ID: a9b8c7d6e5f4
Revises: 581dc55dba32
Create Date: 2024-12-17 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a9b8c7d6e5f4'
down_revision: Union[str, None] = '581dc55dba32'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Remove full_name column from users table
    op.drop_column('users', 'full_name')


def downgrade() -> None:
    # Add full_name column back to users table
    op.add_column('users', sa.Column('full_name', sa.String(), nullable=True))

