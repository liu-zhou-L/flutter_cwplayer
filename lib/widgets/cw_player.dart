import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/morse_codec.dart';
import '../models/player_config.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/steampunk_theme.dart';
import 'mode_selector.dart';
import 'touch_buttons.dart';
import 'manual_key_button.dart';
import 'key_binding_panel.dart';
import 'morse_display.dart';
import 'decode_display.dart';
import 'config_dialog.dart';

class CWPlayer extends StatefulWidget {
  final void Function(String)? onCharDecoded;
  const CWPlayer({super.key, this.onCharDecoded});

  @override
  State<CWPlayer> createState() => _CWPlayerState();
}

class _CWPlayerState extends State<CWPlayer> with WidgetsBindingObserver {
  // ---- 服务 ----
  final AudioService _audio = AudioService();
  final StorageService _storage = StorageService();

  // ---- 配置 ----
  PlayerConfig _cfg = PlayerConfig();
  bool _storageReady = false;

  // ---- 模式 ----
  KeyMode _keyMode = KeyMode.auto;
  InputSource _inputSource = InputSource.mouse;
  String _ditKey = ' ';
  String _dashKey = 'A';

  // ---- 莫尔斯状态 ----
  String _currentMorse = '';
  String _displayText = '';
  Timer? _charTimer;
  Timer? _wordTimer;

  // ---- 手动键状态 ----
  bool _isPressing = false;
  Timer? _holdTimer; // 按下后判断是否变划

  // ---- 自动键状态 ----
  Timer? _autoRepeatTimer;
  String? _autoActiveKey;

  // ---- 辅助 ----
  Timer? _suppressTimer;
  bool _suppressNextPointer = false;
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ==================== 生命周期 ====================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStorage();
  }

  Future<void> _initStorage() async {
    await _storage.init();
    _cfg = _storage.loadConfig();
    _syncAudioSettings();
    if (mounted) setState(() => _storageReady = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _cfg.soundEnabled) {
      _audio.ensureContext();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _stopAutoRepeat();
    _stopHoldTimer();
    _suppressTimer?.cancel();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ==================== 音频 ====================

  /// 同步音频设置到 AudioService
  void _syncAudioSettings() {
    _audio.enabled = _cfg.soundEnabled;
    _audio.setVolume(_cfg.volume);
  }

  // ==================== 莫尔斯核心 ====================

  void _addDot() {
    _cancelTimers();
    setState(() => _currentMorse += '.');
    _startTimers();
    _audio.playBeep(_cfg.dotDurationMs / 1000.0);
  }

  void _addDash() {
    _cancelTimers();
    setState(() => _currentMorse += '-');
    _startTimers();
    _audio.playBeep(_cfg.dotDurationMs * 3 / 1000.0);
  }

  /// 手动键：将当前符号替换为 '-'
  void _switchToDash() {
    if (!_isPressing) return;
    setState(() {
      if (_currentMorse.endsWith('.')) {
        _currentMorse =
            _currentMorse.substring(0, _currentMorse.length - 1) + '-';
      }
    });
  }

  void _cancelTimers() {
    _charTimer?.cancel();
    _wordTimer?.cancel();
  }

  void _startTimers() {
    final charDelay = (_cfg.dotDurationMs * _cfg.charIntervalFactor).round();
    final wordDelay = (_cfg.dotDurationMs * _cfg.wordIntervalFactor).round();
    _charTimer = Timer(Duration(milliseconds: charDelay), _decodeCurrentChar);
    _wordTimer = Timer(Duration(milliseconds: wordDelay), _addSpace);
  }

  void _decodeCurrentChar() {
    if (_currentMorse.isEmpty) return;
    final ch = MorseCodec.decode(_currentMorse);
    setState(() {
      _displayText += ch ?? '?';
      _currentMorse = '';
    });
    if (ch != null) widget.onCharDecoded?.call(ch);
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
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== 半自动/自动键 ====================

  void _sendDot() {
    if (_keyMode != KeyMode.semiauto && _keyMode != KeyMode.auto) return;
    _addDot();
  }

  void _sendDash() {
    if (_keyMode != KeyMode.semiauto && _keyMode != KeyMode.auto) return;
    _addDash();
  }

  // ==================== 手动键（新逻辑：按下即点→持续变划） ====================

  void _manualPress() {
    if (_isPressing) return;
    _isPressing = true;

    // 取消旧定时器，立即添加点信号（不启动新定时器，等松手后再计时间隔）
    _cancelTimers();
    setState(() => _currentMorse += '.');
    _audio.startContinuousBeep();

    // 设定时器：超时后变为划
    final threshold = (_cfg.dotDurationMs * _cfg.manualLongPressThreshold)
        .round();
    _stopHoldTimer();
    _holdTimer = Timer(Duration(milliseconds: threshold), () {
      if (!_isPressing) return;
      _switchToDash();
    });
  }

  void _manualRelease() {
    if (!_isPressing) return;
    _isPressing = false;
    _stopHoldTimer();
    _audio.stopContinuousBeep();
    // 松手后才开始计时间隔，留给用户充足时间输入同一字符的下一个符号
    _startTimers();
  }

  void _stopHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  // ==================== 自动键连发 ====================

  void _startAutoRepeat(String type) {
    if (_autoActiveKey != null) return;
    _autoActiveKey = type;
    type == 'dit' ? _sendDot() : _sendDash();
    _autoRepeatTimer = Timer.periodic(
      Duration(milliseconds: _cfg.autoRepeatIntervalMs),
      (_) => _autoActiveKey == 'dit' ? _sendDot() : _sendDash(),
    );
  }

  /// 比较按键标签（单字符大小写不敏感）
  static bool _keysMatch(String a, String b) {
    if (a == b) return true;
    if (a.length == 1 && b.length == 1) {
      return a.toLowerCase() == b.toLowerCase();
    }
    return false;
  }

  void _stopAutoRepeat() {
    _autoRepeatTimer?.cancel();
    _autoRepeatTimer = null;
    _autoActiveKey = null;
  }

  // ==================== 辅助 ====================

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

  /// 仅清除当前电码区（模式切换时用）
  void _clearMorse() {
    setState(() => _currentMorse = '');
    _cancelTimers();
  }

  void _resetState() {
    _isPressing = false;
    _stopHoldTimer();
    _stopAutoRepeat();
    _suppressNextPointer = false;
    _suppressTimer?.cancel();
    _audio.stopContinuousBeep();
  }

  // ==================== 键盘绑定 ====================

  Future<String?> _bindKeyDialog(String title) async {
    final c = Completer<String?>();
    if (!mounted) return null;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.bgMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: SteampunkTheme.brassDark.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          '按下 $title',
          style: const TextStyle(color: SteampunkTheme.brass),
        ),
        content: SizedBox(
          height: 80,
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && !c.isCompleted) {
                c.complete(event.logicalKey.keyLabel);
                Navigator.of(ctx).pop();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Center(
              child: Text(
                '请按任意键...',
                style: TextStyle(color: SteampunkTheme.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
    return c.future;
  }

  Future<void> _handleBindDit() async {
    final key = await _bindKeyDialog('点键 (Dit)');
    if (key != null && mounted) setState(() => _ditKey = key);
  }

  Future<void> _handleBindDash() async {
    final key = await _bindKeyDialog('划键 (Dash)');
    if (key != null && mounted) setState(() => _dashKey = key);
  }

  // ==================== 配置 ====================

  void _showConfig() {
    showDialog(
      context: context,
      builder: (_) => ConfigDialog(
        config: _cfg,
        onApply: (newConfig) {
          setState(() => _cfg = newConfig);
          _storage.saveConfig(_cfg);
          _syncAudioSettings();
        },
        onReset: () {},
      ),
    );
  }

  // ==================== 键盘事件处理 ====================

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final label = event.logicalKey.keyLabel;
    final isDit = _keysMatch(label, _ditKey);
    final isDash = _keysMatch(label, _dashKey);

    if (event is KeyDownEvent) {
      if (isDit || isDash) {
        if (_keyMode == KeyMode.manual) {
          _manualPress();
        } else if (_keyMode == KeyMode.auto) {
          _startAutoRepeat(isDit ? 'dit' : 'dash');
        } else {
          isDit ? _sendDot() : _sendDash();
        }
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if (isDit || isDash) {
        if (_keyMode == KeyMode.manual) {
          _manualRelease();
        } else if (_keyMode == KeyMode.auto) {
          _stopAutoRepeat();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ==================== 构建 UI ====================

  @override
  Widget build(BuildContext context) {
    if (!_storageReady) {
      return const Center(
        child: CircularProgressIndicator(color: SteampunkTheme.brass),
      );
    }

    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 600;
    final btnSize = isSmall ? 80.0 : 100.0;
    final btnFontSize = isSmall ? 22.0 : 26.0;

    final content = Column(
      children: [
        const SizedBox(height: 8),
        // 齿轮装饰条
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SteampunkTheme.gearDecoration(size: 22),
            const SizedBox(width: 16),
            const Text(
              '⚙ CW PLAYER ⚙',
              style: TextStyle(
                color: SteampunkTheme.brass,
                fontSize: 16,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            SteampunkTheme.gearDecoration(size: 22),
          ],
        ),
        const SizedBox(height: 14),

        // 模式选择器
        ModeSelector(
          keyMode: _keyMode,
          inputSource: _inputSource,
          onModeChanged: (m) => setState(() {
            _keyMode = m;
            _resetState();
            _clearMorse();
          }),
          onSourceChanged: (s) => setState(() {
            _inputSource = s;
            _resetState();
            _clearMorse();
          }),
          onConfigTap: _showConfig,
          onInteraction: _suppressPointer,
        ),
        const SizedBox(height: 16),

        // 触摸按钮区
        if (_inputSource == InputSource.touch) ...[
          if (_keyMode == KeyMode.manual)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ManualKeyButton(
                size: btnSize + 20,
                onPressStart: _manualPress,
                onPressEnd: _manualRelease,
              ),
            )
          else
            TouchButtons(
              btnSize: btnSize,
              btnFontSize: btnFontSize,
              onDotDown: () {
                _suppressPointer();
                _keyMode == KeyMode.auto ? _startAutoRepeat('dit') : _sendDot();
              },
              onDotUp: _keyMode == KeyMode.auto ? _stopAutoRepeat : null,
              onDashDown: () {
                _suppressPointer();
                _keyMode == KeyMode.auto
                    ? _startAutoRepeat('dash')
                    : _sendDash();
              },
              onDashUp: _keyMode == KeyMode.auto ? _stopAutoRepeat : null,
            ),
          const SizedBox(height: 10),
        ],

        // 键位绑定
        KeyBindingPanel(
          ditKey: _ditKey,
          dashKey: _dashKey,
          onBindDit: _handleBindDit,
          onBindDash: _handleBindDash,
          onInteraction: _suppressPointer,
        ),
        const SizedBox(height: 16),

        // 莫尔斯输入显示
        MorseDisplay(morseText: _currentMorse, isSmall: isSmall),
        const SizedBox(height: 16),

        // 解码文本
        DecodeDisplay(
          text: _displayText,
          scrollController: _scrollCtrl,
          onBackspace: _backspace,
          onClear: _clearAll,
          isSmall: isSmall,
        ),
      ],
    );

    // ---- 鼠标模式 ----
    if (_inputSource == InputSource.mouse) {
      Widget child = SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      );

      // 手动键用 Listener（需要持续按压），半自动/自动用 GestureDetector（手势竞技场确保按钮优先）
      if (_keyMode == KeyMode.manual) {
        child = Listener(
          onPointerDown: (_) {
            if (_suppressNextPointer) return;
            _manualPress();
          },
          onPointerUp: (_) {
            if (_suppressNextPointer) return;
            _manualRelease();
          },
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      } else {
        child = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _sendDot(),
          onSecondaryTap: () => _sendDash(),
          onLongPressStart: _keyMode == KeyMode.auto
              ? (_) => _startAutoRepeat('dit')
              : null,
          onLongPressEnd: _keyMode == KeyMode.auto
              ? (_) => _stopAutoRepeat
              : null,
          onSecondaryLongPressStart: _keyMode == KeyMode.auto
              ? (_) => _startAutoRepeat('dash')
              : null,
          onSecondaryLongPressEnd: _keyMode == KeyMode.auto
              ? (_) => _stopAutoRepeat
              : null,
          child: child,
        );
      }

      return Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: child,
      );
    }

    // ---- 触摸模式 ----
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }
}
