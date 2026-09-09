import re

with open('lib/data/services/api_service.dart', 'r') as f:
    content = f.read()

upload_method_new = """
  // Import OCR images
  Future<List<Map<String, dynamic>>> uploadOcrImages(List<String> imagePaths) async {
    final uri = Uri.parse('$baseUrl/import/ocr');
    final request = http.MultipartRequest('POST', uri);

    for (var path in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      print("OCR Error: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
      print("Exception in uploadOcrImages: $e");
      return [];
    }
  }
"""

# Replace the stub we just added
content = re.sub(r"// Import OCR images.*?return \[\];\n  }", upload_method_new.strip(), content, flags=re.DOTALL)

with open('lib/data/services/api_service.dart', 'w') as f:
    f.write(content)
