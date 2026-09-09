import re

with open('lib/data/services/api_service.dart', 'r') as f:
    content = f.read()

upload_method = """
  // Import OCR images
  Future<List<Map<String, dynamic>>> uploadOcrImages(List<String> imagePaths) async {
    // We would use http.MultipartRequest in a real scenario
    // For now, let's assume we use http package
    // BUT we need to implement multipart upload.
    // For MVP, we can just stub it or implement properly if http is available.
    return [];
  }
"""
if "uploadOcrImages" not in content:
    # insert before the last closing brace
    content = content[:content.rfind('}')] + upload_method + "\n}"

with open('lib/data/services/api_service.dart', 'w') as f:
    f.write(content)
