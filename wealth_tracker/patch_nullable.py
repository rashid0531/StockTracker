import os
import re

migration_dir = "alembic/versions"
for filename in os.listdir(migration_dir):
    if filename.endswith(".py") and "add_hashed_password" in filename:
        filepath = os.path.join(migration_dir, filename)
        with open(filepath, "r") as f:
            content = f.read()

        content = content.replace("nullable=False)", "nullable=True)")
        content = content.replace("op.create_table('real_estate_assets',", "op.create_table('real_estate_assets_new',")
        content = content.replace("op.create_table('precious_metal_assets',", "op.create_table('precious_metal_assets_new',")
        content = content.replace("op.create_table('health_metric_logs',", "op.create_table('health_metric_logs_new',")
        content = content.replace("op.create_table('real_estate_projections',", "op.create_table('real_estate_projections_new',")
        content = content.replace("op.create_table('dividend_received',", "op.create_table('dividend_received_new',")

        with open(filepath, "w") as f:
            f.write(content)
