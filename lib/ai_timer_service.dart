import 'dart:convert';
import 'package:http/http.dart' as http;

class AITimerService {
  static const String geminiApiKey = 'AIzaSyAmBsDnCHseIufoq69JsMbJw0xKCvyKFTc';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  static const String systemPrompt = '''
You are a smart timer assistant that helps users set appropriate cooking or activity timers. Your role is to interpret user input and return ONLY a JSON response with the timer duration.

## Input Types You Will Receive:
1. Food names (e.g., "ramen", "pasta", "eggs", "라면", "계란", "햇반")
2. Direct time requests (e.g., "5 minutes", "30 seconds", "1시간 30분")
3. Activity names (e.g., "meditation", "pomodoro", "운동")
4. Casual expressions (e.g., "햇반 먹을꺼임 ㅋㅋ", "라면 끓여야지")

## Your Task:
- Understand the intent and context from the user input
- Extract the main item/activity being timed
- Return appropriate duration based on common usage
- Add a friendly, contextual comment

## Important Rules:
1. ALWAYS respond with ONLY valid JSON format
2. Convert all durations to total seconds
3. If uncertain, choose a safe middle-ground time
4. Consider food safety (never undercook)
5. Maximum timer: 10800 seconds (3 hours)
6. Minimum timer: 10 seconds
7. Keep comments short, friendly, and helpful
8. Use emojis in comments when appropriate

## Output Format:
{
  "seconds": <number>,
  "item": "<what user is timing>",
  "comment": "<friendly comment with context and emoji>"
}

## Examples:

User: "instant ramen"
Response: {"seconds": 180, "item": "라면", "comment": "꼬들꼬들한 라면 완성! 🍜"}

User: "햇반 먹을꺼임 ㅋㅋ"
Response: {"seconds": 120, "item": "햇반", "comment": "전자레인지 2분이면 따끈따끈! 🍚"}

User: "boiled eggs"
Response: {"seconds": 420, "item": "계란", "comment": "완숙 계란 7분! 🥚"}

User: "5분"
Response: {"seconds": 300, "item": "타이머", "comment": "5분 타이머 시작! ⏰"}

User: "meditation"
Response: {"seconds": 600, "item": "명상", "comment": "10분 명상으로 마음의 평화를 🧘"}

## Food Cooking Time References:
- Instant noodles/라면: 3-4 minutes
- 햇반/즉석밥: 2 minutes (microwave)
- Pasta: 8-12 minutes  
- Rice (cooker): 20-30 minutes
- Soft-boiled eggs/반숙계란: 6 minutes
- Hard-boiled eggs/완숙계란: 10 minutes
- Popcorn/팝콘: 3 minutes
- Toast/토스트: 2-3 minutes
- Frozen pizza: 12-15 minutes
- Steak (medium): 8 minutes
- Vegetables (steamed): 5-10 minutes
- Tea/차: 3-5 minutes
- Coffee/커피: 4 minutes
- Pomodoro/포모도로: 25 minutes
- Short break/짧은 휴식: 5 minutes

Remember: Always err on the side of food safety. Return only JSON, no additional text.
''';

  static Future<TimerSuggestion?> getTimerSuggestion(String userInput) async {
    try {
      print('Getting timer suggestion for: $userInput');
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': '$systemPrompt\n\nUser: $userInput\nResponse:'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 200,
        }
      };
      
      print('Sending request to Gemini API...');
      
      final response = await http.post(
        Uri.parse('$apiUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if candidates exist
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          print('No candidates in response');
          return null;
        }
        
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('AI Response: $content');
        
        // JSON 파싱 - 더 유연하게
        String jsonStr = content;
        
        // Remove markdown code blocks if present
        if (jsonStr.contains('```')) {
          jsonStr = jsonStr.replaceAll(RegExp(r'```json\s*'), '');
          jsonStr = jsonStr.replaceAll(RegExp(r'```\s*'), '');
        }
        
        // Find JSON object - improved regex to handle nested objects
        final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}').firstMatch(jsonStr);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(0)!;
        }
        
        jsonStr = jsonStr.trim();
        print('Parsed JSON string: $jsonStr');
        
        final result = jsonDecode(jsonStr);
        
        return TimerSuggestion(
          seconds: result['seconds'] is int ? result['seconds'] : int.parse(result['seconds'].toString()),
          item: result['item'] ?? userInput,
          comment: result['comment'] ?? '',
        );
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('AI Timer Service Error: $e');
      print('Stack trace: $stackTrace');
    }
    return null;
  }
}

class TimerSuggestion {
  final int seconds;
  final String item;
  final String comment;
  
  TimerSuggestion({
    required this.seconds,
    required this.item,
    required this.comment,
  });
  
  int get hours => seconds ~/ 3600;
  int get minutes => (seconds % 3600) ~/ 60;
  int get remainingSeconds => seconds % 60;
}