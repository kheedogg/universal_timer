import 'dart:convert';
import 'package:http/http.dart' as http;

class ModelTester {
  static const String apiKey = 'AIzaSyAmBsDnCHseIufoq69JsMbJw0xKCvyKFTc';
  
  static Future<void> testAllModels() async {
    final models = [
      // v1beta models
      'v1beta/models/gemini-1.5-flash',
      'v1beta/models/gemini-1.5-pro', 
      'v1beta/models/gemini-pro',
      'v1beta/models/gemini-1.0-pro',
      
      // v1 models  
      'v1/models/gemini-1.5-flash',
      'v1/models/gemini-1.5-pro',
      'v1/models/gemini-pro',
      'v1/models/gemini-1.0-pro',
    ];
    
    for (String model in models) {
      await testModel(model);
    }
  }
  
  static Future<void> testModel(String modelPath) async {
    final url = 'https://generativelanguage.googleapis.com/$modelPath:generateContent?key=$apiKey';
    
    try {
      print('\n=== Testing: $modelPath ===');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Respond with JSON only: {"seconds": 180, "item": "test", "note": "3 minutes"}'
            }]
          }],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 100,
          }
        }),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('✅ SUCCESS: $modelPath works!');
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          print('Response: $content');
        }
        return;
      } else {
        print('❌ FAILED: Status ${response.statusCode}');
        final error = jsonDecode(response.body);
        if (error['error'] != null) {
          print('Error: ${error['error']['message']}');
        }
      }
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }
  
  // 사용 가능한 모델 목록 조회
  static Future<void> listAvailableModels() async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
    
    try {
      print('\n=== Fetching Available Models ===');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        
        print('Available models:');
        for (var model in models) {
          if (model['supportedGenerationMethods']?.contains('generateContent') == true) {
            print('  ✅ ${model['name']} - supports generateContent');
          }
        }
      } else {
        print('Failed to fetch models: ${response.body}');
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
  }
}