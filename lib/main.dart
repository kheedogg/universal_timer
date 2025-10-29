import 'package:flutter/material.dart';
import 'dart:async';
import 'ai_timer_service.dart';
import 'ai_timer_service_simple.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TimerHomePage(),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  bool _isRunning = false;
  
  // For countdown timer
  bool _isCountdown = true; // 기본값을 true로 변경 (Countdown Timer가 기본)
  int _countdownHours = 0;
  int _countdownMinutes = 5;
  int _countdownSeconds = 0;
  int _totalCountdownSeconds = 0;
  int _remainingSeconds = 0;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final TextEditingController _aiInputController = TextEditingController();
  bool _isLoadingAI = false;
  
  // 인라인 편집을 위한 컨트롤러들
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  
  // 편집 모드 상태
  bool _editingHours = false;
  bool _editingMinutes = false;
  bool _editingSeconds = false;
  
  // 경고 메시지
  String _warningMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 사용 가능한 모델 테스트 (디버깅용)
    // ModelTester.listAvailableModels();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _aiInputController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _startStopTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _animationController.reverse();
      } else {
        if (_isCountdown && _remainingSeconds == 0) {
          _remainingSeconds = _countdownHours * 3600 + _countdownMinutes * 60 + _countdownSeconds;
          _totalCountdownSeconds = _remainingSeconds;
        }
        _animationController.forward();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_isCountdown) {
              if (_remainingSeconds > 0) {
                _remainingSeconds--;
              } else {
                _timer?.cancel();
                _isRunning = false;
                _animationController.reverse();
                // Timer completed - could add notification here
              }
            } else {
              _seconds++;
              if (_seconds >= 60) {
                _seconds = 0;
                _minutes++;
                if (_minutes >= 60) {
                  _minutes = 0;
                  _hours++;
                }
              }
            }
          });
        });
      }
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _seconds = 0;
      _minutes = 0;
      _hours = 0;
      _remainingSeconds = 0;
      _animationController.reset();
    });
  }

  String _formatTime() {
    if (_isCountdown && (_isRunning || _remainingSeconds > 0)) {
      int hours = _remainingSeconds ~/ 3600;
      int minutes = (_remainingSeconds % 3600) ~/ 60;
      int seconds = _remainingSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (!_isCountdown || _totalCountdownSeconds == 0) return 0;
    return 1 - (_remainingSeconds / _totalCountdownSeconds);
  }
  
  Future<void> _getAITimerSuggestion() async {
    if (_aiInputController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter something to get a timer suggestion'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoadingAI = true;
    });
    
    try {
      final userInput = _aiInputController.text;
      print('Looking for timer suggestion for: $userInput');
      
      // AI API 호출
      print('Calling AI API...');
      final suggestion = await AITimerService.getTimerSuggestion(userInput);
      
      if (suggestion != null) {
        print('Got AI suggestion: ${suggestion.hours}h ${suggestion.minutes}m ${suggestion.remainingSeconds}s');
        setState(() {
          _countdownHours = suggestion.hours;
          _countdownMinutes = suggestion.minutes;
          _countdownSeconds = suggestion.remainingSeconds;
          _isLoadingAI = false;
        });
        
        if (suggestion.comment.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(suggestion.comment),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        // AI 실패하면 기본값 제안
        print('AI API failed, using default');
        setState(() {
          _countdownMinutes = 5; // 기본 5분
          _isLoadingAI = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not understand "$userInput". Set to 5 minutes as default.'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
      // 에러 발생시 기본값
      setState(() {
        _countdownMinutes = 5;
        _isLoadingAI = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred. Set to 5 minutes as default.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Universal Timer'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isCountdown ? Icons.timer : Icons.timer_off),
            onPressed: () {
              setState(() {
                _isCountdown = !_isCountdown;
                _resetTimer();
              });
            },
            tooltip: _isCountdown ? 'Switch to Stopwatch' : 'Switch to Timer',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isCountdown ? 'Countdown Timer' : 'Stopwatch',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              
              // AI Input Field for Countdown (Always visible when countdown mode)
              if (_isCountdown) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AI Timer Assistant',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _aiInputController,
                              decoration: InputDecoration(
                                hintText: 'e.g., "ramen", "5 minutes", "boiled eggs"',
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _getAITimerSuggestion(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _isLoadingAI ? null : _getAITimerSuggestion,
                            icon: _isLoadingAI
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Timer Display
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_animation.value * 0.05),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Clickable timer display for countdown mode
                          if (_isCountdown && !_isRunning && _remainingSeconds == 0)
                            _buildEditableTimeDisplay(theme)
                          else
                            Text(
                              _formatTime(),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: _isRunning 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurface,
                              ),
                            ),
                          if (_isCountdown && _totalCountdownSeconds > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: SizedBox(
                                width: 200,
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 8,
                                  backgroundColor: theme.colorScheme.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // 경고 메시지 표시
              if (_warningMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _warningMessage,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 60),
              
              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    onPressed: _startStopTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Start'),
                    backgroundColor: _isRunning 
                      ? Colors.orange 
                      : theme.colorScheme.primary,
                    heroTag: 'startStop',
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton.extended(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    backgroundColor: Colors.red,
                    heroTag: 'reset',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableTimeDisplay(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hours
        _buildEditableTimeField(
          value: _countdownHours,
          isEditing: _editingHours,
          controller: _hoursController,
          maxValue: 23,
          theme: theme,
          onTap: () {
            setState(() {
              _editingHours = true;
              _hoursController.text = _countdownHours.toString();
            });
          },
          onSubmitted: (value) {
            final newValue = int.tryParse(value);
            if (newValue != null && newValue >= 0 && newValue <= 23) {
              setState(() {
                _countdownHours = newValue;
                _editingHours = false;
                _warningMessage = '';
              });
            } else {
              setState(() {
                _editingHours = false;
                _warningMessage = 'Hours must be between 0 and 23';
              });
              // 3초 후 경고 메시지 자동 삭제
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _warningMessage = '';
                  });
                }
              });
            }
          },
          onFocusLost: () {
            setState(() {
              _editingHours = false;
            });
          },
        ),
        Text(
          ':',
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface,
          ),
        ),
        // Minutes
        _buildEditableTimeField(
          value: _countdownMinutes,
          isEditing: _editingMinutes,
          controller: _minutesController,
          maxValue: 59,
          theme: theme,
          onTap: () {
            setState(() {
              _editingMinutes = true;
              _minutesController.text = _countdownMinutes.toString();
            });
          },
          onSubmitted: (value) {
            final newValue = int.tryParse(value);
            if (newValue != null && newValue >= 0 && newValue <= 59) {
              setState(() {
                _countdownMinutes = newValue;
                _editingMinutes = false;
                _warningMessage = '';
              });
            } else {
              setState(() {
                _editingMinutes = false;
                _warningMessage = 'Minutes must be between 0 and 59';
              });
              // 3초 후 경고 메시지 자동 삭제
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _warningMessage = '';
                  });
                }
              });
            }
          },
          onFocusLost: () {
            setState(() {
              _editingMinutes = false;
            });
          },
        ),
        Text(
          ':',
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface,
          ),
        ),
        // Seconds
        _buildEditableTimeField(
          value: _countdownSeconds,
          isEditing: _editingSeconds,
          controller: _secondsController,
          maxValue: 59,
          theme: theme,
          onTap: () {
            setState(() {
              _editingSeconds = true;
              _secondsController.text = _countdownSeconds.toString();
            });
          },
          onSubmitted: (value) {
            final newValue = int.tryParse(value);
            if (newValue != null && newValue >= 0 && newValue <= 59) {
              setState(() {
                _countdownSeconds = newValue;
                _editingSeconds = false;
                _warningMessage = '';
              });
            } else {
              setState(() {
                _editingSeconds = false;
                _warningMessage = 'Seconds must be between 0 and 59';
              });
              // 3초 후 경고 메시지 자동 삭제
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _warningMessage = '';
                  });
                }
              });
            }
          },
          onFocusLost: () {
            setState(() {
              _editingSeconds = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEditableTimeField({
    required int value,
    required bool isEditing,
    required TextEditingController controller,
    required int maxValue,
    required ThemeData theme,
    required VoidCallback onTap,
    required Function(String) onSubmitted,
    required VoidCallback onFocusLost,
  }) {
    if (isEditing) {
      return Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(8),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          onSubmitted: onSubmitted,
          onTapOutside: (_) => onFocusLost(),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
  }


  Widget _buildTimeInput(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            controller: TextEditingController(text: value.toString()),
            onChanged: (text) {
              final newValue = int.tryParse(text) ?? 0;
              onChanged(newValue);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}