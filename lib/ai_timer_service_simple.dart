import 'dart:convert';
import 'package:http/http.dart' as http;

class AITimerServiceSimple {
  static const String geminiApiKey = 'AIzaSyAmBsDnCHseIufoq69JsMbJw0xKCvyKFTc';
  
  // 여러 모델 시도
  static const List<String> models = [
    'gemini-pro',
    'gemini-1.5-flash-latest', 
    'gemini-1.5-pro-latest',
  ];
  
  static Future<void> testModels() async {
    for (String model in models) {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiApiKey';
      
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [{
              'parts': [{'text': 'Hello, respond with JSON: {"status": "ok"}'}]
            }]
          }),
        );
        
        print('Model $model: Status ${response.statusCode}');
        if (response.statusCode == 200) {
          print('✓ Model $model works!');
          final data = jsonDecode(response.body);
          print('Response: ${data['candidates'][0]['content']['parts'][0]['text']}');
        } else {
          print('✗ Model $model failed: ${response.body}');
        }
      } catch (e) {
        print('✗ Model $model error: $e');
      }
    }
  }
  
  // 간단한 타이머 매핑 (AI 없이 로컬에서 처리)
  static Map<String, int> quickTimers = {
    // 음식 (초 단위)
    'ramen': 180,
    '라면': 180,
    'instant noodles': 180,
    'eggs': 420,
    '계란': 420,
    'boiled eggs': 420,
    'soft boiled eggs': 360,
    'hard boiled eggs': 600,
    'pasta': 600,
    '파스타': 600,
    'rice': 1200,
    '밥': 1200,
    '햇반': 120,  // 전자레인지 2분
    'hetbahn': 120,
    'instant rice': 120,
    '즉석밥': 120,
    'toast': 120,
    '토스트': 120,
    'tea': 180,
    '차': 180,
    'coffee': 240,
    '커피': 240,
    'popcorn': 180,
    '팝콘': 180,
    'pizza': 900,
    '피자': 900,
    'steak': 480,
    '스테이크': 480,
    
    // 활동
    'meditation': 600,
    '명상': 600,
    'pomodoro': 1500,
    '포모도로': 1500,
    'break': 300,
    '휴식': 300,
    'exercise': 1800,
    '운동': 1800,
    'nap': 1200,
    '낮잠': 1200,
  };
  
  static int? getQuickTimer(String input) {
    final lower = input.toLowerCase().trim();
    
    // 먼저 키워드로 음식/활동 찾기
    for (final key in quickTimers.keys) {
      if (lower.contains(key)) {
        return quickTimers[key];
      }
    }
    
    // 직접 시간 입력 처리
    final timePatterns = [
      RegExp(r'(\d+)\s*분'),
      RegExp(r'(\d+)\s*min'),
      RegExp(r'(\d+)\s*minutes?'),
    ];
    
    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final minutes = int.tryParse(match.group(1)!);
        if (minutes != null) {
          return minutes * 60;
        }
      }
    }
    
    // 초 단위
    final secPatterns = [
      RegExp(r'(\d+)\s*초'),
      RegExp(r'(\d+)\s*sec'),
      RegExp(r'(\d+)\s*seconds?'),
    ];
    
    for (final pattern in secPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final seconds = int.tryParse(match.group(1)!);
        if (seconds != null) {
          return seconds;
        }
      }
    }
    
    // 시간 단위
    final hourPatterns = [
      RegExp(r'(\d+)\s*시간'),
      RegExp(r'(\d+)\s*hour'),
      RegExp(r'(\d+)\s*hours?'),
    ];
    
    for (final pattern in hourPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final hours = int.tryParse(match.group(1)!);
        if (hours != null) {
          return hours * 3600;
        }
      }
    }
    
    // 사전 정의된 타이머 확인
    return quickTimers[lower];
  }
}