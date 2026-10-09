import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/hexasort_engine.dart';
import '../theme/hexa_themes.dart';

/// Persisted settings + stats for Hexa Sort. Survives app restarts.
///
/// The player profile (renameable display name) is stored as ONE
/// order-preserving JSON string under [_kNamesJson] via setString.
/// Android's SharedPreferences stores StringLists as an unordered
/// StringSet, which scrambles order on every restart — so ordered data
/// must never use setStringList. The list form also keeps the door open
/// for future extra slots without changing the storage contract.
class HexaSettings extends ChangeNotifier {
  static const _kMusic = 'hexasort_music_on';
  static const _kSfx = 'hexasort_sfx_on';
  static const _kVolume = 'hexasort_volume';
  static const _kDifficulty = 'hexasort_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kNamesJson = 'hexasort_player_names_json';
  static const _kLegacyProfile = 'hexasort_profile_json'; // dirty-tree v2 key
  static const _kLegacyNamesList = 'hexasort_player_names'; // legacy StringList
  static const _kLegacyUnlocked = 'hs_unlocked'; // legacy int key (v1.x)
  static const _kTheme = 'hexasort_theme_id';
  static const _kTileStyle = 'hexasort_tile_style';
  static const _kAccent = 'hexasort_board_accent';
  static const _kIsPro = 'hexasort_is_pro';
  static const _kGames = 'hexasort_games_played';
  static const _kLevelsDone = 'hexasort_levels_completed';
  static const _kReviewCount = 'hexasort_review_prompts';
  static const _kCustomPrefix = 'hexasort_custom_';
  static const _kDailyDone = 'hexasort_daily_done'; // YYYY-MM-DD
  static const _kDailyStreak = 'hexasort_daily_streak';
  static const _kDailyWins = 'hexasort_daily_wins';
  static const _kBestMovesJson = 'hexasort_best_moves_json';

  static String _unlockKey(HexaDifficulty d) => 'hexasort_unlocked_${d.name}';

  /// Encode the player names as ONE order-preserving JSON string
  /// (e.g. `["Wajiha"]`). Never a StringList — see the class doc.
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  /// Decode the JSON string back, preserving order. Tolerates the legacy
  /// `{'name': ...}` object shape and bare strings defensively.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return ['Player'];
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        final out = <String>[];
        for (final v in d) {
          if (v is String) {
            final s = v.trim();
            out.add(s.isEmpty ? 'Player' : s);
          }
        }
        if (out.isNotEmpty) return out;
      } else if (d is Map && d['name'] is String) {
        final s = (d['name'] as String).trim();
        return [s.isEmpty ? 'Player' : s];
      } else if (d is String) {
        final s = d.trim();
        return [s.isEmpty ? 'Player' : s];
      }
    } catch (_) {}
    return ['Player'];
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  HexaDifficulty difficulty = HexaDifficulty.medium;

  /// Order-preserving player names (slot 0 = the player). Persisted as one
  /// JSON string under [_kNamesJson]; never a StringList.
  List<String> playerNames = ['Player'];

  /// The player's display name (slot 0). While typing, this holds the live
  /// keystroke value; [commitPlayerName] trims and applies the default.
  String get playerName => playerNames.isEmpty ? 'Player' : playerNames.first;
  String themeId = 'honey';
  String tileStyleId = 'gloss';
  int boardAccent = 0;
  bool isPro = false;
  int gamesPlayed = 0;
  int levelsCompleted = 0;
  int reviewPrompts = 0;
  String dailyDoneDate = '';
  int dailyStreak = 0;
  int dailyWins = 0;

  /// Best move counts keyed "easy:7" -> moves, stored as one JSON string.
  Map<String, int> bestMoves = {};

  /// Custom theme colors (ARGB ints). Defaults mirror Honey Workshop.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'bgDark': 0xFF2A1A10,
    'bgMid': 0xFF4A2F1B,
    'surface': 0xFF5C3A21,
    'tube': 0xFF3A2412,
    'tubeRim': 0xFF8A5A2B,
    'accent': 0xFFE8A93D,
    'accentLight': 0xFFFFD58A,
    'accentDark': 0xFF9C6A1F,
    'text': 0xFFF7EBD7,
    'muted': 0xFFC4A67E,
    'tile0': 0xFFE5484D,
    'tile1': 0xFFF5A623,
    'tile2': 0xFFF2D13C,
    'tile3': 0xFF5FB760,
    'tile4': 0xFF4BA3A3,
    'tile5': 0xFF4A7FC9,
    'tile6': 0xFF9B6BC7,
    'tile7': 0xFFD9629B,
  };

  /// Builds the user-designed custom theme from stored colors.
  HexaThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return HexaThemeDef(
      id: 'custom',
      name: 'My Creation',
      bgDark: c('bgDark'),
      bgMid: c('bgMid'),
      surface: c('surface'),
      tube: c('tube'),
      tubeRim: c('tubeRim'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      text: c('text'),
      muted: c('muted'),
      tiles: [for (int i = 0; i < 8; i++) c('tile$i')],
    );
  }

  int unlockedLevel(HexaDifficulty d) => _unlocked[d] ?? 1;
  final Map<HexaDifficulty, int> _unlocked = {
    for (final d in HexaDifficulty.values) d: 1,
  };

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = HexaDifficulty
        .values[(p.getInt(_kDifficulty) ?? 1).clamp(0, 2)];
    // Player names: the ONE canonical key is `hexasort_player_names_json`
    // (order-preserving JSON via setString — never setStringList).
    // One-time migration from any legacy storage shape.
    playerNames = await _loadPlayerNames(p);
    themeId = p.getString(_kTheme) ?? 'honey';
    tileStyleId = p.getString(_kTileStyle) ?? 'gloss';
    boardAccent = (p.getInt(_kAccent) ?? 0).clamp(0, 2);
    isPro = p.getBool(_kIsPro) ?? false;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    levelsCompleted = p.getInt(_kLevelsDone) ?? 0;
    reviewPrompts = p.getInt(_kReviewCount) ?? 0;
    dailyDoneDate = p.getString(_kDailyDone) ?? '';
    dailyStreak = p.getInt(_kDailyStreak) ?? 0;
    dailyWins = p.getInt(_kDailyWins) ?? 0;
    bestMoves = _decodeBestMoves(p.getString(_kBestMovesJson));
    // Legacy migration: v1.x stored one int under 'hs_unlocked'. Migrate it
    // once into the per-difficulty keys, then drop the legacy key for good.
    final legacy = p.getInt(_kLegacyUnlocked);
    if (legacy != null) {
      final v = legacy.clamp(1, hexLevels);
      for (final d in HexaDifficulty.values) {
        _unlocked[d] = max(_unlocked[d]!, v);
      }
      await p.remove(_kLegacyUnlocked);
    }
    for (final d in HexaDifficulty.values) {
      _unlocked[d] = (p.getInt(_unlockKey(d)) ?? _unlocked[d]!)
          .clamp(1, hexLevels);
    }
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  /// Load player names from the canonical JSON key, migrating once from
  /// any legacy shape (dirty-tree `{'name': ...}` object, legacy
  /// StringList, or bare string) into the canonical key.
  static Future<List<String>> _loadPlayerNames(SharedPreferences p) async {
    var raw = p.getString(_kNamesJson);
    if (raw == null) {
      final legacyProfile = p.getString(_kLegacyProfile);
      if (legacyProfile != null) {
        raw = encodePlayerNames(decodePlayerNames(legacyProfile));
        await p.remove(_kLegacyProfile);
      } else {
        // Legacy StringList read (never written again): it may already be
        // order-scrambled by Android's StringSet, but a one-time read is
        // still better than dropping the name.
        final legacyList = p.getStringList(_kLegacyNamesList);
        if (legacyList != null) {
          raw = encodePlayerNames(decodePlayerNames(jsonEncode(legacyList)));
          await p.remove(_kLegacyNamesList);
        }
      }
      if (raw != null) {
        await p.setString(_kNamesJson, raw);
      }
    }
    return decodePlayerNames(raw);
  }

  Future<void> _persistPlayerNames() async {
    await _prefs?.setString(_kNamesJson, encodePlayerNames(playerNames));
  }

  static Map<String, int> _decodeBestMoves(String? raw) {
    final out = <String, int>{};
    if (raw == null) return out;
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        d.forEach((k, v) {
          if (k is String && v is int) out[k] = v;
        });
      }
    } catch (_) {}
    return out;
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty.index);
    await _persistPlayerNames();
    await p.setString(_kTheme, themeId);
    await p.setString(_kTileStyle, tileStyleId);
    await p.setInt(_kAccent, boardAccent);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kLevelsDone, levelsCompleted);
    await p.setInt(_kReviewCount, reviewPrompts);
    await p.setString(_kDailyDone, dailyDoneDate);
    await p.setInt(_kDailyStreak, dailyStreak);
    await p.setInt(_kDailyWins, dailyWins);
    await p.setString(_kBestMovesJson, jsonEncode(bestMoves));
    for (final d in HexaDifficulty.values) {
      await p.setInt(_unlockKey(d), _unlocked[d]!);
    }
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || HexaThemes.isProTheme(themeId)) {
      themeId = 'honey';
      changed = true;
    }
    if (TileStyles.isPro(tileStyleId)) {
      tileStyleId = 'gloss';
      changed = true;
    }
    if (BoardAccents.isPro(boardAccent)) {
      boardAccent = 0;
      changed = true;
    }
    if (difficulty == HexaDifficulty.hard) {
      difficulty = HexaDifficulty.medium;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(HexaDifficulty d) async {
    // Hard mode is a Pro feature.
    if (!isPro && d == HexaDifficulty.hard) return;
    difficulty = d;
    notifyListeners();
    await _save();
  }

  /// Live keystroke update: the raw value is kept in memory AND written
  /// to prefs on EVERY keystroke (no waiting for keyboard-done or a Save
  /// button). Cheap and safe to call per keystroke; skips notifyListeners
  /// so the typing field isn't rebuilt under the user's fingers.
  Future<void> updatePlayerNameLive(String raw) async {
    playerNames = [raw];
    await _persistPlayerNames();
  }

  /// Commit on focus loss / submit / dispose: trims, applies the 'Player'
  /// default when empty, persists, and notifies listeners.
  Future<void> commitPlayerName() async {
    final clean = playerName.trim();
    playerNames = [clean.isEmpty ? 'Player' : clean];
    await _persistPlayerNames();
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows a lock).
    if (!isPro && (id == 'custom' || HexaThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(String id) async {
    if (!isPro && TileStyles.isPro(id)) return;
    tileStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBoardAccent(int v) async {
    v = v.clamp(0, BoardAccents.names.length - 1);
    if (!isPro && BoardAccents.isPro(v)) return;
    boardAccent = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  /// Record a completed level. Returns true if it was a new best.
  Future<bool> recordLevelComplete(
      HexaDifficulty d, int level, int moves) async {
    gamesPlayed++;
    levelsCompleted++;
    final key = '${d.name}:$level';
    var newBest = false;
    final prev = bestMoves[key];
    if (prev == null || moves < prev) {
      bestMoves[key] = moves;
      newBest = true;
    }
    if (level == _unlocked[d]! && _unlocked[d]! < hexLevels) {
      _unlocked[d] = _unlocked[d]! + 1;
    }
    notifyListeners();
    await _save();
    return newBest;
  }

  int? bestMovesFor(HexaDifficulty d, int level) =>
      bestMoves['${d.name}:$level'];

  /// Record a daily-challenge win for today's date string (YYYY-MM-DD).
  Future<void> recordDailyWin(String date) async {
    dailyWins++;
    // Streak: consecutive calendar days.
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    dailyStreak = (dailyDoneDate == yesterday) ? dailyStreak + 1 : 1;
    dailyDoneDate = date;
    gamesPlayed++;
    notifyListeners();
    await _save();
  }

  Future<void> bumpReviewPrompts() async {
    reviewPrompts++;
    await _save();
  }

  Future<void> resetProgress() async {
    for (final d in HexaDifficulty.values) {
      _unlocked[d] = 1;
    }
    bestMoves.clear();
    gamesPlayed = 0;
    levelsCompleted = 0;
    notifyListeners();
    await _save();
  }
}
