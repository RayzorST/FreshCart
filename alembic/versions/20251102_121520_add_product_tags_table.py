"""Add product_tags table

Revision ID: 86d6177c9a79
Revises: 7095b3b31405  # ЗАМЕНИТЕ НА АКТУАЛЬНЫЙ ID ИЗ ПУНКТА 1
Create Date: 2024-01-15 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '86d6177c9a79'
down_revision = '7095b3b31405'  # ЗАМЕНИТЕ НА АКТУАЛЬНЫЙ ID ИЗ ПУНКТА 1
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('product_tags',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('tag', sa.String(length=50), nullable=False),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    op.create_index(op.f('ix_product_tags_id'), 'product_tags', ['id'], unique=False)
    op.create_index(op.f('ix_product_tags_product_id'), 'product_tags', ['product_id'], unique=False)
    op.create_index('ix_product_tags_tag', 'product_tags', ['tag'], unique=False)

def downgrade():
    op.drop_index('ix_product_tags_tag', table_name='product_tags')
    op.drop_index(op.f('ix_product_tags_product_id'), table_name='product_tags')
    op.drop_index(op.f('ix_product_tags_id'), table_name='product_tags')
    op.drop_table('product_tags')
