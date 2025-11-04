"""merge multiple heads

Revision ID: a6fe06d73a37
Revises: 86d6177c9a79, 5696f1a4c7ef
Create Date: 2025-11-02 12:16:43.042578

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a6fe06d73a37'
down_revision = ('86d6177c9a79', '5696f1a4c7ef')
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass