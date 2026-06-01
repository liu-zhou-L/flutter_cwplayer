/// 播放器配置数据模型
class PlayerConfig {
  bool soundEnabled;
  double volume;
  int dotDurationMs;
  int autoRepeatIntervalMs;
  double manualLongPressThreshold;
  double charIntervalFactor;
  double wordIntervalFactor;

  PlayerConfig({
    this.soundEnabled = true,
    this.volume = 0.8,
    this.dotDurationMs = 120,
    this.autoRepeatIntervalMs = 200,
    this.manualLongPressThreshold = 2.0,
    this.charIntervalFactor = 3.0,
    this.wordIntervalFactor = 7.0,
  });

  static final defaults = PlayerConfig();

  PlayerConfig copy() => PlayerConfig(
    soundEnabled: soundEnabled,
    volume: volume,
    dotDurationMs: dotDurationMs,
    autoRepeatIntervalMs: autoRepeatIntervalMs,
    manualLongPressThreshold: manualLongPressThreshold,
    charIntervalFactor: charIntervalFactor,
    wordIntervalFactor: wordIntervalFactor,
  );

  void reset() {
    soundEnabled = defaults.soundEnabled;
    volume = defaults.volume;
    dotDurationMs = defaults.dotDurationMs;
    autoRepeatIntervalMs = defaults.autoRepeatIntervalMs;
    manualLongPressThreshold = defaults.manualLongPressThreshold;
    charIntervalFactor = defaults.charIntervalFactor;
    wordIntervalFactor = defaults.wordIntervalFactor;
  }
}
