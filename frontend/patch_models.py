import re

with open('../wealth_tracker/app/models.py', 'r') as f:
    content = f.read()

# Add is_primary_residence to RealEstateAsset
if 'is_primary_residence:' not in content:
    content = content.replace(
        '    purchase_date: Mapped[datetime.date] = mapped_column(Date, nullable=True)',
        '    purchase_date: Mapped[datetime.date] = mapped_column(Date, nullable=True)\n    is_primary_residence: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)'
    )

# Add RealEstateProjection class if not exists
if 'class RealEstateProjection' not in content:
    projection_class = """

class RealEstateProjection(Base):
    __tablename__ = "real_estate_projections"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    real_estate_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("real_estate_assets.id", ondelete="CASCADE"), nullable=False
    )
    projection_year: Mapped[int] = mapped_column(Integer, nullable=False)
    projected_value: Mapped[Decimal] = mapped_column(Numeric(14, 4), nullable=False)
    generated_at: Mapped[datetime.datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
"""
    content += projection_class

with open('../wealth_tracker/app/models.py', 'w') as f:
    f.write(content)
