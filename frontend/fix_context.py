import re

with open('lib/ui/features/import/import_view.dart', 'r') as f:
    content = f.read()

# Fix context in _pickAndUploadImages
bad_snack = """      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Extracted ${extracted.length} positions via OCR!"),
          backgroundColor: AppColors.positive,
        ),
      );"""

good_snack = """      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Extracted ${extracted.length} positions via OCR!"),
          backgroundColor: AppColors.positive,
        ),
      );"""

content = content.replace(bad_snack, good_snack)

bad_snack2 = """      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OCR failed: $e"),
          backgroundColor: AppColors.negative,
        ),
      );"""

good_snack2 = """      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OCR failed: $e"),
          backgroundColor: AppColors.negative,
        ),
      );"""
      
content = content.replace(bad_snack2, good_snack2)

with open('lib/ui/features/import/import_view.dart', 'w') as f:
    f.write(content)
