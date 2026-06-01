import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

class MorseCodec {
  static const Map<String, String> _codeToChar = {
    '.-': 'A',
    '-...': 'B',
    '-.-.': 'C',
    '-..': 'D',
    '.': 'E',
    '..-.': 'F',
    '--.': 'G',
    '....': 'H',
    '..': 'I',
    '.---': 'J',
    '-.-': 'K',
    '.-..': 'L',
    '--': 'M',
    '-.': 'N',
    '---': 'O',
    '.--.': 'P',
    '--.-': 'Q',
    '.-.': 'R',
    '...': 'S',
    '-': 'T',
    '..-': 'U',
    '...-': 'V',
    '.--': 'W',
    '-..-': 'X',
    '-.--': 'Y',
    '--..': 'Z',
    '-----': '0',
    '.----': '1',
    '..---': '2',
    '...--': '3',
    '....-': '4',
    '.....': '5',
    '-....': '6',
    '--...': '7',
    '---..': '8',
    '----.': '9',
    '.-.-.-': '.',
    '--..--': ',',
    '..--..': '?',
    '.----.': '\'',
    '-.-.--': '!',
    '-..-.': '/',
    '-.--.': '(',
    '-.--.-': ')',
    '.-...': '&',
    '---...': ':',
    '-.-.-.': ';',
    '-...-': '=',
    '.-.-.': '+',
    '-....-': '-',
    '..--.-': '_',
    '.-..-.': '"',
    '...-..-': r'\$',
    '.--.-.': '@',
  };
  static String? morseToChar(String morse) => _codeToChar[morse];
}

enum KeyMode { manual, semiauto, auto }

enum InputSource { touch, mouse }

class CWPlayer extends StatefulWidget {
  final Function(String)? onCharDecoded;
  const CWPlayer({super.key, this.onCharDecoded});

  @override
  State<CWPlayer> createState() => _CWPlayerState();
}

class _CWPlayerState extends State<CWPlayer> with WidgetsBindingObserver {
  late SharedPreferences _prefs;
  bool _soundEnabled = false;
  double _volume = 0.8;
  int _dotDurationMs = 120;
  int _autoRepeatIntervalMs = 200;
  double _manualLongPressThreshold = 2.0;
  double _charIntervalFactor = 3.0;
  double _wordIntervalFactor = 7.0;

  static const _defaultSoundEnabled = false;
  static const _defaultVolume = 0.8;
  static const _defaultDotDurationMs = 120;
  static const _defaultAutoRepeatIntervalMs = 200;
  static const _defaultManualLongPressThreshold = 2.0;
  static const _defaultCharIntervalFactor = 3.0;
  static const _defaultWordIntervalFactor = 7.0;

  KeyMode _keyMode = KeyMode.auto;
  InputSource _inputSource = InputSource.mouse;
  String _customDitKey = ' ';
  String _customDashKey = 'a';

  String _currentMorse = '';
  String _displayText = '';
  Timer? _charTimer;
  Timer? _wordTimer;

  DateTime? _pressStart;
  bool _isPressing = false;

  Timer? _autoRepeatTimer;
  String? _autoActiveKey;

  Timer? _suppressTimer;
  bool _suppressNextPointer = false;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  dynamic _audioContext;
  bool _audioContextReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadConfig();
    if (mounted) setState(() {});
  }

  void _loadConfig() {
    _soundEnabled = _prefs.getBool('soundEnabled') ?? _defaultSoundEnabled;
    _volume = _prefs.getDouble('volume') ?? _defaultVolume;
    _dotDurationMs = _prefs.getInt('dotDurationMs') ?? _defaultDotDurationMs;
    _autoRepeatIntervalMs =
        _prefs.getInt('autoRepeatIntervalMs') ?? _defaultAutoRepeatIntervalMs;
    _manualLongPressThreshold =
        _prefs.getDouble('manualLongPressThreshold') ??
        _defaultManualLongPressThreshold;
    _charIntervalFactor =
        _prefs.getDouble('charIntervalFactor') ?? _defaultCharIntervalFactor;
    _wordIntervalFactor =
        _prefs.getDouble('wordIntervalFactor') ?? _defaultWordIntervalFactor;
  }

  void _saveConfig() {
    _prefs.setBool('soundEnabled', _soundEnabled);
    _prefs.setDouble('volume', _volume);
    _prefs.setInt('dotDurationMs', _dotDurationMs);
    _prefs.setInt('autoRepeatIntervalMs', _autoRepeatIntervalMs);
    _prefs.setDouble('manualLongPressThreshold', _manualLongPressThreshold);
    _prefs.setDouble('charIntervalFactor', _charIntervalFactor);
    _prefs.setDouble('wordIntervalFactor', _wordIntervalFactor);
  }

  void _resetAllConfig() {
    setState(() {
      _soundEnabled = _defaultSoundEnabled;
      _volume = _defaultVolume;
      _dotDurationMs = _defaultDotDurationMs;
      _autoRepeatIntervalMs = _defaultAutoRepeatIntervalMs;
      _manualLongPressThreshold = _defaultManualLongPressThreshold;
      _charIntervalFactor = _defaultCharIntervalFactor;
      _wordIntervalFactor = _defaultWordIntervalFactor;
    });
    _saveConfig();
  }

  // ---------- 蜂鸣器 ----------
  Future<bool> _ensureAudioContext() async {
    if (!kIsWeb) return false;
    if (!_soundEnabled) return false;
    if (_audioContextReady) return true;

    try {
      if (_audioContext == null) {
        final audioContextConstructor = (html.window as dynamic).AudioContext;
        if (audioContextConstructor != null) {
          _audioContext = audioContextConstructor();
        } else {
          debugPrint('AudioContext not supported');
          return false;
        }
      }
      await _audioContext!.resume();
      _audioContextReady = true;
      debugPrint('AudioContext resumed');
      return true;
    } catch (e) {
      debugPrint('AudioContext init failed: $e');
      return false;
    }
  }

  Future<void> _playBeep(double durationSec) async {
    if (!kIsWeb) return;
    if (!_soundEnabled) return;
    if (!_audioContextReady) {
      final ready = await _ensureAudioContext();
      if (!ready) return;
    }
    try {
      const frequency = 1000.0; // 蜂鸣器频率 1000Hz
      final now = _audioContext!.currentTime;
      final gain = _audioContext!.createGain();
      gain.gain.value = _volume;
      gain.connect(_audioContext!.destination);
      final osc = _audioContext!.createOscillator();
      osc.frequency.value = frequency;
      osc.type = 'sine';
      osc.connect(gain);
      osc.start();
      gain.gain.exponentialRampToValueAtTime(0.0001, now + durationSec);
      osc.stop(now + durationSec);
    } catch (e) {
      debugPrint('Beep error: $e');
    }
  }

  // ---------- 莫尔斯核心操作 ----------
  void _addDot() {
    _cancelTimers();
    setState(() => _currentMorse += '.');
    _startTimers();
    _playBeep(_dotDurationMs / 1000.0);
  }

  void _addDash() {
    _cancelTimers();
    setState(() => _currentMorse += '-');
    _startTimers();
    _playBeep(_dotDurationMs * 3 / 1000.0);
  }

  void _cancelTimers() {
    _charTimer?.cancel();
    _wordTimer?.cancel();
  }

  void _startTimers() {
    final charDelay = (_dotDurationMs * _charIntervalFactor).round();
    final wordDelay = (_dotDurationMs * _wordIntervalFactor).round();
    _charTimer = Timer(Duration(milliseconds: charDelay), _decodeCurrentChar);
    _wordTimer = Timer(Duration(milliseconds: wordDelay), _addSpace);
  }

  void _decodeCurrentChar() {
    if (_currentMorse.isEmpty) return;
    final char = MorseCodec.morseToChar(_currentMorse);
    setState(() {
      _displayText += char ?? '?';
      _currentMorse = '';
    });
    if (char != null && widget.onCharDecoded != null) {
      widget.onCharDecoded!(char);
    }
    _charTimer?.cancel();
    _scrollToBottom();
  }

  void _addSpace() {
    if (_displayText.isNotEmpty && !_displayText.endsWith(' ')) {
      setState(() => _displayText += ' ');
      _scrollToBottom();
    }
    _wordTimer?.cancel();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------- 输入处理 ----------
  void _sendDot() {
    if (_keyMode == KeyMode.semiauto ||
        _keyMode == KeyMode.auto ||
        _keyMode == KeyMode.manual) {
      _addDot();
    }
  }

  void _sendDash() {
    if (_keyMode == KeyMode.semiauto ||
        _keyMode == KeyMode.auto ||
        _keyMode == KeyMode.manual) {
      _addDash();
    }
  }

  void _manualPress() {
    if (_isPressing) return;
    _isPressing = true;
    _pressStart = DateTime.now();
  }

  void _manualRelease() {
    if (!_isPressing) return;
    _isPressing = false;
    if (_pressStart == null) return;
    final duration = DateTime.now().difference(_pressStart!).inMilliseconds;
    final threshold = (_dotDurationMs * _manualLongPressThreshold).round();
    if (duration < threshold) {
      _sendDot();
    } else {
      _sendDash();
    }
    _pressStart = null;
  }

  void _startAutoRepeat(String type) {
    if (_autoActiveKey != null) return;
    _autoActiveKey = type;
    if (type == 'dit')
      _sendDot();
    else
      _sendDash();
    _autoRepeatTimer = Timer.periodic(
      Duration(milliseconds: _autoRepeatIntervalMs),
      (_) {
        if (_autoActiveKey == 'dit')
          _sendDot();
        else
          _sendDash();
      },
    );
  }

  void _stopAutoRepeat() {
    _autoRepeatTimer?.cancel();
    _autoRepeatTimer = null;
    _autoActiveKey = null;
  }

  void _suppressPointer() {
    _suppressNextPointer = true;
    _suppressTimer?.cancel();
    _suppressTimer = Timer(const Duration(milliseconds: 150), () {
      _suppressNextPointer = false;
    });
  }

  void _backspace() {
    _suppressPointer();
    setState(() {
      if (_displayText.isNotEmpty)
        _displayText = _displayText.substring(0, _displayText.length - 1);
    });
    _scrollToBottom();
  }

  void _clearAll() {
    _suppressPointer();
    setState(() {
      _displayText = '';
      _currentMorse = '';
      _cancelTimers();
    });
  }

  Future<String?> _bindKey(String title) async {
    final completer = Completer<String?>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text('按下 $title 键'),
        content: SizedBox(
          height: 100,
          child: Focus(
            autofocus: true,
            onKey: (node, event) {
              if (event is KeyDownEvent && !completer.isCompleted) {
                completer.complete(event.logicalKey.keyLabel);
                Navigator.of(ctx).pop();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: const Center(child: Text('请按任意键...')),
          ),
        ),
      ),
    );
    return completer.future;
  }

  void _resetState() {
    _isPressing = false;
    _pressStart = null;
    _stopAutoRepeat();
    _suppressNextPointer = false;
    _suppressTimer?.cancel();
  }

  // ---------- 配置对话框 ----------
  Future<void> _showConfigDialog() async {
    bool localSound = _soundEnabled;
    double localVolume = _volume;
    int localDotDur = _dotDurationMs;
    int localAutoRepeat = _autoRepeatIntervalMs;
    double localManualThreshold = _manualLongPressThreshold;
    double localCharFactor = _charIntervalFactor;
    double localWordFactor = _wordIntervalFactor;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('配置参数'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildConfigSwitch('音效开关', localSound, (v) {
                        setDialogState(() => localSound = v);
                      }),
                      _buildConfigSlider(
                        '音量',
                        0,
                        1,
                        localVolume,
                        (v) {
                          setDialogState(() => localVolume = v);
                        },
                        divisions: 20,
                        label: '${(localVolume * 100).round()}%',
                      ),
                      _buildConfigSlider(
                        '点信号时长(ms)',
                        30,
                        500,
                        localDotDur.toDouble(),
                        (v) {
                          setDialogState(() => localDotDur = v.round());
                        },
                        divisions: 470,
                        label: '${localDotDur}ms',
                      ),
                      _buildConfigSlider(
                        '自动键重复间隔(ms)',
                        50,
                        500,
                        localAutoRepeat.toDouble(),
                        (v) {
                          setDialogState(() => localAutoRepeat = v.round());
                        },
                        divisions: 450,
                        label: '${localAutoRepeat}ms',
                      ),
                      _buildConfigSlider(
                        '手动键长按阈值(倍数)',
                        1.0,
                        5.0,
                        localManualThreshold,
                        (v) {
                          setDialogState(() => localManualThreshold = v);
                        },
                        divisions: 40,
                        label: '${localManualThreshold.toStringAsFixed(1)}x',
                      ),
                      _buildConfigSlider(
                        '字符间隔(倍数)',
                        2.0,
                        6.0,
                        localCharFactor,
                        (v) {
                          setDialogState(() => localCharFactor = v);
                        },
                        divisions: 40,
                        label: '${localCharFactor.toStringAsFixed(1)}x',
                      ),
                      _buildConfigSlider(
                        '单词间隔(倍数)',
                        5.0,
                        10.0,
                        localWordFactor,
                        (v) {
                          setDialogState(() => localWordFactor = v);
                        },
                        divisions: 50,
                        label: '${localWordFactor.toStringAsFixed(1)}x',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      localSound = _defaultSoundEnabled;
                      localVolume = _defaultVolume;
                      localDotDur = _defaultDotDurationMs;
                      localAutoRepeat = _defaultAutoRepeatIntervalMs;
                      localManualThreshold = _defaultManualLongPressThreshold;
                      localCharFactor = _defaultCharIntervalFactor;
                      localWordFactor = _defaultWordIntervalFactor;
                    });
                  },
                  child: const Text('全部重置'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _soundEnabled = localSound;
                      _volume = localVolume;
                      _dotDurationMs = localDotDur;
                      _autoRepeatIntervalMs = localAutoRepeat;
                      _manualLongPressThreshold = localManualThreshold;
                      _charIntervalFactor = localCharFactor;
                      _wordIntervalFactor = localWordFactor;
                    });
                    _saveConfig();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConfigSwitch(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildConfigSlider(
    String title,
    double min,
    double max,
    double value,
    Function(double) onChanged, {
    int divisions = 100,
    String label = '',
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(label.isNotEmpty ? label : value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _soundEnabled &&
        _audioContext != null &&
        kIsWeb) {
      try {
        _audioContext!.resume();
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _stopAutoRepeat();
    _suppressTimer?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    if (_audioContext != null && kIsWeb) {
      try {
        _audioContext!.close();
      } catch (e) {}
    }
    super.dispose();
  }

  // ---------- 构建UI ----------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final btnSize = isSmall ? 80.0 : 100.0;
    final btnFontSize = isSmall ? 20.0 : 24.0;

    Widget content = Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            SegmentedButton<KeyMode>(
              segments: const [
                ButtonSegment(value: KeyMode.manual, label: Text('手动键')),
                ButtonSegment(value: KeyMode.semiauto, label: Text('半自动键')),
                ButtonSegment(value: KeyMode.auto, label: Text('自动键')),
              ],
              selected: {_keyMode},
              onSelectionChanged: (set) {
                setState(() {
                  _keyMode = set.first;
                  _resetState();
                });
              },
            ),
            SegmentedButton<InputSource>(
              segments: const [
                ButtonSegment(value: InputSource.mouse, label: Text('🐭 鼠标')),
                ButtonSegment(value: InputSource.touch, label: Text('👆 触摸')),
              ],
              selected: {_inputSource},
              onSelectionChanged: (set) {
                setState(() {
                  _inputSource = set.first;
                  _resetState();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showConfigDialog,
              tooltip: '配置参数',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 触摸模式下的按钮
        if (_inputSource == InputSource.touch &&
            (_keyMode == KeyMode.semiauto || _keyMode == KeyMode.auto))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTouchButton(
                  '•',
                  () {
                    _suppressPointer();
                    _sendDot();
                  },
                  () {
                    if (_keyMode == KeyMode.auto) _startAutoRepeat('dit');
                  },
                  () {
                    if (_keyMode == KeyMode.auto) _stopAutoRepeat();
                  },
                  btnSize,
                  btnFontSize,
                ),
                const SizedBox(width: 32),
                _buildTouchButton(
                  '—',
                  () {
                    _suppressPointer();
                    _sendDash();
                  },
                  () {
                    if (_keyMode == KeyMode.auto) _startAutoRepeat('dash');
                  },
                  () {
                    if (_keyMode == KeyMode.auto) _stopAutoRepeat();
                  },
                  btnSize,
                  btnFontSize,
                ),
              ],
            ),
          ),

        if (_inputSource == InputSource.touch && _keyMode == KeyMode.manual)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Listener(
              onPointerDown: (_) {
                _ensureAudioContext();
                _manualPress();
              },
              onPointerUp: (_) => _manualRelease(),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  '电键',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('点键: $_customDitKey'),
                  TextButton(
                    onPressed: () async {
                      final key = await _bindKey('点键');
                      if (key != null) setState(() => _customDitKey = key);
                    },
                    child: const Text('绑定键盘'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('划键: $_customDashKey'),
                  TextButton(
                    onPressed: () async {
                      final key = await _bindKey('划键');
                      if (key != null) setState(() => _customDashKey = key);
                    },
                    child: const Text('绑定键盘'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _currentMorse.isEmpty ? '✎ 等待输入' : _currentMorse,
            style: TextStyle(
              fontSize: isSmall ? 22 : 28,
              letterSpacing: 6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '解码文本',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    _displayText.isEmpty ? '（空）' : _displayText,
                    style: TextStyle(fontSize: isSmall ? 16 : 20),
                    softWrap: true,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _backspace,
                    icon: const Icon(Icons.backspace),
                  ),
                  IconButton(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    // ---------- 鼠标模式：全屏捕获 ----------
    if (_inputSource == InputSource.mouse) {
      if (_keyMode == KeyMode.manual) {
        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (node, event) {
            if (event is KeyDownEvent) {
              final label = event.logicalKey.keyLabel;
              if (label == _customDitKey || label == _customDashKey) {
                _ensureAudioContext();
                _manualPress();
                return KeyEventResult.handled;
              }
            } else if (event is KeyUpEvent) {
              final label = event.logicalKey.keyLabel;
              if (label == _customDitKey || label == _customDashKey) {
                _manualRelease();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerDown: (_) {
              if (!_suppressNextPointer) {
                _ensureAudioContext();
                _manualPress();
              }
            },
            onPointerUp: (_) {
              if (!_suppressNextPointer) _manualRelease();
            },
            behavior: HitTestBehavior.opaque,
            child: SafeArea(child: content),
          ),
        );
      } else {
        // 半自动/自动鼠标模式
        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (node, event) {
            if (event is KeyDownEvent) {
              final label = event.logicalKey.keyLabel;
              if (label == _customDitKey) {
                _ensureAudioContext();
                if (_keyMode == KeyMode.auto)
                  _startAutoRepeat('dit');
                else
                  _sendDot();
                return KeyEventResult.handled;
              } else if (label == _customDashKey) {
                _ensureAudioContext();
                if (_keyMode == KeyMode.auto)
                  _startAutoRepeat('dash');
                else
                  _sendDash();
                return KeyEventResult.handled;
              }
            } else if (event is KeyUpEvent) {
              final label = event.logicalKey.keyLabel;
              if (label == _customDitKey || label == _customDashKey) {
                if (_keyMode == KeyMode.auto) _stopAutoRepeat();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerDown: (PointerDownEvent event) {
              if (_suppressNextPointer) return;
              _ensureAudioContext();
              if (event.buttons == 1 || event.buttons == 0) {
                if (_keyMode == KeyMode.auto)
                  _startAutoRepeat('dit');
                else
                  _sendDot();
              } else if (event.buttons == 2) {
                if (_keyMode == KeyMode.auto)
                  _startAutoRepeat('dash');
                else
                  _sendDash();
              }
            },
            onPointerUp: (PointerUpEvent event) {
              if (_keyMode == KeyMode.auto) _stopAutoRepeat();
            },
            behavior: HitTestBehavior.opaque,
            child: SafeArea(child: content),
          ),
        );
      }
    } else {
      // ---------- 触摸模式：只响应屏幕按钮，键盘仍然有效 ----------
      return Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (node, event) {
          if (event is KeyDownEvent) {
            final label = event.logicalKey.keyLabel;
            if (label == _customDitKey) {
              _ensureAudioContext();
              if (_keyMode == KeyMode.auto)
                _startAutoRepeat('dit');
              else if (_keyMode == KeyMode.semiauto)
                _sendDot();
              else if (_keyMode == KeyMode.manual)
                _manualPress();
              return KeyEventResult.handled;
            } else if (label == _customDashKey) {
              _ensureAudioContext();
              if (_keyMode == KeyMode.auto)
                _startAutoRepeat('dash');
              else if (_keyMode == KeyMode.semiauto)
                _sendDash();
              else if (_keyMode == KeyMode.manual)
                _manualPress();
              return KeyEventResult.handled;
            }
          } else if (event is KeyUpEvent) {
            final label = event.logicalKey.keyLabel;
            if (label == _customDitKey || label == _customDashKey) {
              if (_keyMode == KeyMode.auto) _stopAutoRepeat();
              if (_keyMode == KeyMode.manual) _manualRelease();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(child: content),
      );
    }
  }

  // 辅助方法：带长按支持的触摸按钮
  Widget _buildTouchButton(
    String label,
    VoidCallback onTap,
    VoidCallback? onLongPressStart,
    VoidCallback? onLongPressEnd,
    double size,
    double fontSize,
  ) {
    return GestureDetector(
      onTap: () {
        _ensureAudioContext();
        onTap();
      },
      onLongPressStart: onLongPressStart != null
          ? (_) {
              _ensureAudioContext();
              onLongPressStart();
            }
          : null,
      onLongPressEnd: onLongPressEnd != null
          ? (_) {
              onLongPressEnd();
            }
          : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
