import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_config.dart';

/// 配置持久化服务
class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  PlayerConfig loadConfig() => PlayerConfig(
    soundEnabled:
        _prefs.getBool('soundEnabled') ?? PlayerConfig.defaults.soundEnabled,
    volume: _prefs.getDouble('volume') ?? PlayerConfig.defaults.volume,
    dotDurationMs:
        _prefs.getInt('dotDurationMs') ?? PlayerConfig.defaults.dotDurationMs,
    autoRepeatIntervalMs:
        _prefs.getInt('autoRepeatIntervalMs') ??
        PlayerConfig.defaults.autoRepeatIntervalMs,
    manualLongPressThreshold:
        _prefs.getDouble('manualLongPressThreshold') ??
        PlayerConfig.defaults.manualLongPressThreshold,
    charIntervalFactor:
        _prefs.getDouble('charIntervalFactor') ??
        PlayerConfig.defaults.charIntervalFactor,
    wordIntervalFactor:
        _prefs.getDouble('wordIntervalFactor') ??
        PlayerConfig.defaults.wordIntervalFactor,
  );

  Future<void> saveConfig(PlayerConfig config) async {
    await Future.wait([
      _prefs.setBool('soundEnabled', config.soundEnabled),
      _prefs.setDouble('volume', config.volume),
      _prefs.setInt('dotDurationMs', config.dotDurationMs),
      _prefs.setInt('autoRepeatIntervalMs', config.autoRepeatIntervalMs),
      _prefs.setDouble(
        'manualLongPressThreshold',
        config.manualLongPressThreshold,
      ),
      _prefs.setDouble('charIntervalFactor', config.charIntervalFactor),
      _prefs.setDouble('wordIntervalFactor', config.wordIntervalFactor),
    ]);
  }
}
