// stopwatch_service.dart
import 'dart:async';

class StopwatchService {
  StopwatchService._privateConstructor();
  static final StopwatchService _instance = StopwatchService._privateConstructor();
  static StopwatchService get instance => _instance;

  final StreamController<Duration> _timeStreamController = StreamController.broadcast();
  Stream<Duration> get timeStream => _timeStreamController.stream;

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _timeStreamController.add(_elapsed);
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _elapsed = Duration.zero;
    _timeStreamController.add(_elapsed);
  }

  Duration get currentElapsed => _elapsed;
}