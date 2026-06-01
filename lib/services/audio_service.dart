import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:js_interop';

// ---- JS 类型映射（扩展类型名 = JS 构造函数名） ----

extension type AudioContext(JSObject _) implements JSObject {
  external factory AudioContext._();
  external JSPromise<JSObject?> resume();
  external JSObject get destination;
  external OscillatorNode createOscillator();
  external GainNode createGain();
  external double get currentTime;
  external void close();
}

extension type OscillatorNode(JSObject _) implements JSObject {
  external AudioParam get frequency;
  external set type(String v);
  external void connect(JSObject dest);
  external void start([double when]);
  external void stop([double when]);
}

extension type GainNode(JSObject _) implements JSObject {
  external AudioParam get gain;
  external void connect(JSObject dest);
}

extension type AudioParam(JSObject _) implements JSObject {
  external set value(double v);
  external void setValueAtTime(double value, double startTime);
  external void exponentialRampToValueAtTime(double target, double endTime);
}

/// Web Audio API 音频服务（使用 dart:js_interop 扩展类型，无名称混淆）
class AudioService {
  AudioContext? _ctx;
  bool _ready = false;
  bool _enabled = true;
  double _volume = 0.8;
  Future<bool>? _initFuture;

  GainNode? _continuousGain;
  OscillatorNode? _continuousOsc;
  bool _isBeeping = false;

  bool get isReady => _ready;
  bool get isBeeping => _isBeeping;
  set enabled(bool v) => _enabled = v;
  void setVolume(double v) => _volume = v;

  Future<bool> ensureContext() async {
    if (!kIsWeb) return false;
    if (_ready) return true;
    final pending = _initFuture;
    if (pending != null) return pending;

    _initFuture = _doInit();
    final ok = await _initFuture;
    _initFuture = null;
    return ok ?? false;
  }

  Future<bool> _doInit() async {
    try {
      _ctx = AudioContext._(); // → new AudioContext() in JS
      await _ctx!.resume().toDart;
      _ready = true;
      debugPrint('AudioContext ready');
      return true;
    } catch (e) {
      debugPrint('AudioContext init failed: $e');
      return false;
    }
  }

  Future<void> playBeep(double durationSec) async {
    if (!kIsWeb || !_enabled) return;
    if (!_ready) {
      final ok = await ensureContext();
      if (!ok) return;
    }
    try {
      final ctx = _ctx!;
      const freq = 700.0; // 真实 CW 音调
      final now = ctx.currentTime;
      final gain = ctx.createGain();
      gain.gain.value = _volume;
      gain.connect(ctx.destination);
      final osc = ctx.createOscillator();
      osc.frequency.value = freq;
      osc.type = 'sine';
      osc.connect(gain);
      osc.start();
      // 极短衰减防止爆音，保持硬朗音色
      const antiClick = 0.005;
      final stopTime = now + durationSec;
      gain.gain.setValueAtTime(_volume, stopTime - antiClick);
      gain.gain.exponentialRampToValueAtTime(0.0001, stopTime);
      osc.stop(stopTime + antiClick);
    } catch (e) {
      debugPrint('Beep error: $e');
    }
  }

  Future<void> startContinuousBeep() async {
    if (!kIsWeb || !_enabled) return;
    if (!_ready) {
      final ok = await ensureContext();
      if (!ok) return;
    }
    if (_isBeeping) return;
    try {
      final ctx = _ctx!;
      const freq = 700.0; // 真实 CW 音调
      _continuousGain = ctx.createGain();
      _continuousGain!.gain.value = _volume;
      _continuousGain!.connect(ctx.destination);
      _continuousOsc = ctx.createOscillator();
      _continuousOsc!.frequency.value = freq;
      _continuousOsc!.type = 'sine';
      _continuousOsc!.connect(_continuousGain!);
      _continuousOsc!.start();
      _isBeeping = true;
    } catch (e) {
      debugPrint('Continuous beep start error: $e');
    }
  }

  void stopContinuousBeep() {
    if (!_isBeeping) return;
    try {
      final now = _ctx!.currentTime;
      // 极短 5ms 衰减防止爆音
      _continuousGain!.gain.exponentialRampToValueAtTime(0.0001, now + 0.005);
      _continuousOsc!.stop(now + 0.008);
    } catch (_) {}
    _continuousGain = null;
    _continuousOsc = null;
    _isBeeping = false;
  }

  void dispose() {
    stopContinuousBeep();
    if (_ctx != null && kIsWeb) {
      try {
        _ctx!.close();
      } catch (_) {}
    }
    _ctx = null;
    _ready = false;
  }
}
