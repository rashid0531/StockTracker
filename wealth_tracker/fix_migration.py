import os

migration_dir = "alembic/versions"
for filename in os.listdir(migration_dir):
    if filename.endswith(".py") and "add_hashed_password" in filename:
        filepath = os.path.join(migration_dir, filename)
        with open(filepath, "r") as f:
            lines = f.readlines()

        new_lines = []
        skip = False
        for line in lines:
            if "op.create_table('view_" in line or "op.drop_table('view_" in line:
                skip = True
                continue
            if skip and ")" in line and line.strip() == ")":
                skip = False
                continue
            if not skip:
                new_lines.append(line)

        with open(filepath, "w") as f:
            f.writelines(new_lines)
