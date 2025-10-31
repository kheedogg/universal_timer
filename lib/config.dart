class Config {
  // Gemini API 키를 환경변수에서 가져오기
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // 기본값은 빈 문자열
  );
  
  // API 키가 설정되었는지 확인
  static bool get hasApiKey => geminiApiKey.isNotEmpty;
  
  // 디버그 모드에서 API 키 상태 확인
  static void checkApiKey() {
    if (geminiApiKey.isEmpty) {
      print('⚠️ GEMINI_API_KEY environment variable is not set');
      print('💡 Run with: flutter run --dart-define=GEMINI_API_KEY=your_api_key');
    } else {
      print('✅ Gemini API key configured');
    }
  }
}