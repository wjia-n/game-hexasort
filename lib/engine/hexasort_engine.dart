import 'dart:async';
import 'dart:math';

/// Hexa Sort engine — owns ALL game state and phases. The UI only renders.
///
/// Turn/pour flow is a state machine: [HexaPhase] gates every input, and a
/// watchdog timer recovers any phase whose timer died, so stuck states are
/// impossible by construction.
///
/// Deal: each difficulty tier has its own level track (50 levels). A deal is
/// colors × 4 hexes shuffled into `colors + emptyTubes` tubes, round-robin.
/// A deal that is instantly won is re-dealt; the engine always starts with
/// at least one legal pour (guaranteed by the empty tubes).
library;

const hexCap = 4;
const hexLevels = 50;

/// Difficulty tiers. 0 = easy, 1 = medium, 2 = hard (RULES.md §11).
enum HexaDifficulty { easy, medium, hard }

/// Phases owned entirely by the engine. The UI only renders.
enum HexaPhase { idle, pouring, undoing, winning, over }

/// One pour in flight: [count] hexes moving from tube [from] to tube [to].
/// The engine moves them one hex at a time on its own timer so every move
/// animates visibly; the UI never pops results instantly.
class HexMove {
  final int from;
  final int to;
  final int count;
  const HexMove(this.from, this.to, this.count);
}

enum HexaEvent {
  lift, // selected a tube
  drop, // a single hex landed in the target tube
  invalid, // illegal tap / illegal pour
  pourDone, // a full pour finished
  undo, // undo replay finished
  hint, // a hint was shown
  stuck, // no legal pours left but not won
  win, // level completed
}

/// UI-facing messages from the engine.
class HexaEngine {
  final int level;
  final HexaDifficulty difficulty;
  final bool isPro;
  final Random _rand;

  HexaPhase phase = HexaPhase.idle;
  List<List<int>> tubes = [];
  int selected = -1;
  int moves = 0;
  bool over = false;
  bool stuckBoard = false;
  String banner = '';

  /// Hint highlight: tube indices, valid until the next state change.
  int hintFrom = -1;
  int hintTo = -1;

  /// Free tier: 3 hints per level. Pro: effectively unlimited.
  int hintsLeft = 3;

  /// Win info populated when [phase] reaches [HexaPhase.over].
  int? lastWinMoves;
  bool get won => over;

  final List<HexMove> _history = [];
  void Function(HexaEvent event)? onEvent;

  Timer? _timer;
  Timer? _watchdog;
  bool _disposed = false;
  bool paused = false;

  static const _pourStepMs = 140;
  static const _undoStepMs = 100;

  int get nColors => tubes.isEmpty
      ? 0
      : tubes.fold(0, (m, t) => max(m, t.isEmpty ? 0 : t.reduce(max) + 1));

  int get emptyTubes =>
      difficulty == HexaDifficulty.easy ? 3 : 2;

  int get maxColors =>
      switch (difficulty) { HexaDifficulty.easy => 5, HexaDifficulty.medium => 7, HexaDifficulty.hard => 8 };

  int colorCountForLevel(int lvl) {
    var c = 3 + (lvl - 1) ~/ 2;
    if (difficulty == HexaDifficulty.hard) c += 1;
    return c.clamp(3, maxColors);
  }

  /// Moves par: a loose benchmark for "clean" play.
  int movesParFor(int colors) => colors * hexCap + emptyTubes * 4;

  HexaEngine({
    required this.level,
    required this.difficulty,
    required this.isPro,
    int? seed,
    this.onEvent,
  })  : _rand = seed == null ? Random() : Random(seed),
        hintsLeft = isPro ? 999 : 3 {
    _deal();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  // ------------------------------------------------------------- internals
  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  void _notify() {
    // ChangeNotifier-free: the UI registers [onChanged] via this callback.
    onChanged?.call();
  }

  void Function()? onChanged;

  void _setPhase(HexaPhase p) {
    phase = p;
    _notify();
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    _notify();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// Respects [paused]. Stuck states impossible by construction.
  void _recover() {
    if (_disposed || paused || _timer != null) return;
    switch (phase) {
      case HexaPhase.pouring:
        _pourStep(); // resume an interrupted pour with remaining hexes
      case HexaPhase.undoing:
        _undoStep(); // resume an interrupted undo replay
      case HexaPhase.winning:
        _finishWin(); // winning with no timer: settle immediately
      case HexaPhase.idle:
      case HexaPhase.over:
        break;
    }
  }

  void _deal() {
    final colors = colorCountForLevel(level);
    final nTubes = colors + emptyTubes;
    final pool = <int>[];
    for (int c = 0; c < colors; c++) {
      pool.addAll(List.filled(hexCap, c));
    }
    pool.shuffle(_rand);
    tubes = List.generate(nTubes, (_) => <int>[]);
    for (int i = 0; i < pool.length; i++) {
      tubes[i % colors].add(pool[i]);
    }
    if (_isWon() || !_anyLegalPour()) {
      _deal(); // never start solved or stuck
      return;
    }
    selected = -1;
    moves = 0;
    over = false;
    stuckBoard = false;
    hintsLeft = isPro ? 999 : 3;
    hintFrom = -1;
    hintTo = -1;
    _history.clear();
    banner = 'Tap a tube to lift it 👆';
    _setPhase(HexaPhase.idle);
  }

  bool _isWon() {
    for (final t in tubes) {
      if (t.isEmpty) continue;
      if (t.length != hexCap) return false;
      if (t.any((c) => c != t.first)) return false;
    }
    return true;
  }

  /// A pour is legal when the dest has room and takes the color (or is
  /// empty), and the move is not a no-op (a full single-color tube poured
  /// into an empty tube changes nothing).
  bool canPour(int from, int to) {
    if (from == to || from < 0 || to < 0) return false;
    if (from >= tubes.length || to >= tubes.length) return false;
    final src = tubes[from];
    final dst = tubes[to];
    if (src.isEmpty) return false;
    if (dst.length >= hexCap) return false;
    if (dst.isEmpty) {
      // No-op pours are illegal (RULES §5): a full tube of one color into
      // an empty tube changes nothing and would be a wasted "move".
      if (src.length == hexCap && src.every((c) => c == src.first)) {
        return false;
      }
      return true;
    }
    return dst.last == src.last;
  }

  /// How many hexes a pour would move (the contiguous top run).
  int pourCount(int from, int to) {
    if (!canPour(from, to)) return 0;
    final src = tubes[from];
    final dst = tubes[to];
    final color = src.last;
    var run = 0;
    for (int i = src.length - 1; i >= 0 && src[i] == color; i--) {
      run++;
    }
    return min(run, hexCap - dst.length);
  }

  /// Any legal pour exists on the board?
  bool _anyLegalPour() {
    for (int f = 0; f < tubes.length; f++) {
      for (int t = 0; t < tubes.length; t++) {
        if (canPour(f, t)) return true;
      }
    }
    return false;
  }

  // -------------------------------------------------------------- input
  /// Player taps a tube. Everything is gated on [phase]: input only lands
  /// in [HexaPhase.idle].
  void tapTube(int i) {
    if (phase != HexaPhase.idle || over) {
      if (phase == HexaPhase.idle && !over) onEvent?.call(HexaEvent.invalid);
      return;
    }
    if (selected == -1) {
      if (tubes[i].isEmpty) {
        onEvent?.call(HexaEvent.invalid);
        return;
      }
      selected = i;
      banner = 'Now tap where it should pour 🫗';
      onEvent?.call(HexaEvent.lift);
      _notify();
    } else if (selected == i) {
      selected = -1;
      banner = 'Tap a tube to lift it 👆';
      onEvent?.call(HexaEvent.lift);
      _notify();
    } else {
      final from = selected;
      if (!canPour(from, i)) {
        onEvent?.call(HexaEvent.invalid);
        return;
      }
      _beginPour(from, i);
    }
  }

  void _beginPour(int from, int to) {
    final count = pourCount(from, to);
    if (count <= 0) {
      onEvent?.call(HexaEvent.invalid);
      return;
    }
    selected = -1;
    _history.add(HexMove(from, to, count));
    _setPhase(HexaPhase.pouring);
    _pourStep();
  }

  /// Engine-owned pour: moves ONE hex per timer tick so every move animates
  /// visibly. Never driven by UI timers.
  void _pourStep() {
    if (_disposed || paused) return;
    if (phase != HexaPhase.pouring) return;
    final mv = _history.last;
    final src = tubes[mv.from];
    final dst = tubes[mv.to];
    void doStep() {
      if (_disposed || paused) return;
      if (phase != HexaPhase.pouring) return;
      if (src.isEmpty || dst.length >= hexCap) {
        _finishPour();
        return;
      }
      final color = src.removeLast();
      dst.add(color);
      onEvent?.call(HexaEvent.drop);
      _notify();
      if (dst.length < hexCap) {
        // Only keep pouring the same contiguous run.
        final rest = _pourRemaining(src, color);
        if (rest > 0) {
          _arm(const Duration(milliseconds: _pourStepMs), doStep);
          return;
        }
      }
      _finishPour();
    }

    doStep();
  }

  /// How many more hexes of [color] can still pour from [src] contiguously.
  int _pourRemaining(List<int> src, int color) {
    var run = 0;
    for (int i = src.length - 1; i >= 0 && src[i] == color; i--) {
      run++;
    }
    return run;
  }

  void _finishPour() {
    moves++;
    hintFrom = -1;
    hintTo = -1;
    onEvent?.call(HexaEvent.pourDone);
    if (_isWon()) {
      _beginWin();
      return;
    }
    if (!_anyLegalPour()) {
      // Not won, no legal moves: guide the player to undo/restart.
      // Undo and restart are ALWAYS available, so the game can never
      // truly get stuck — this state always has a legal forward action.
      stuckBoard = true;
      banner = 'No moves left — Undo or Restart 🔄';
      onEvent?.call(HexaEvent.stuck);
    } else {
      stuckBoard = false;
      banner = 'Tap a tube to lift it 👆';
    }
    _setPhase(HexaPhase.idle);
  }

  // ----------------------------------------------------------------- undo
  /// Undo the last pour with a visible reverse replay (one hex at a time),
  /// never an instant pop.
  void undo() {
    if (phase != HexaPhase.idle || over || _history.isEmpty) {
      onEvent?.call(HexaEvent.invalid);
      return;
    }
    _setPhase(HexaPhase.undoing);
    _undoStep();
  }

  void _undoStep() {
    if (_disposed || paused) return;
    if (phase != HexaPhase.undoing) return;
    final mv = _history.last;
    final src = tubes[mv.to]; // hexes currently sit in the pour's dest
    final dst = tubes[mv.from];
    if (src.isEmpty) {
      _finishUndo();
      return;
    }
    // Move back ONE hex of this pour.
    final color = src.removeLast();
    dst.add(color);
    onEvent?.call(HexaEvent.drop);
    _notify();
    final stillOwed = _pourBackRemaining(mv);
    if (stillOwed > 0) {
      _arm(const Duration(milliseconds: _undoStepMs), _undoStep);
    } else {
      _finishUndo();
    }
  }

  /// How many hexes of the last pour still need to move back.
  int _pourBackRemaining(HexMove mv) {
    final src = tubes[mv.to];
    final dst = tubes[mv.from];
    // Hexes that belong to this pour: count matching top-run in dst that
    // came from the pour. Simpler robust rule: the pour moved mv.count
    // hexes from `from` to `to`; remaining = count - (hexes already back).
    final color = dst.isEmpty ? -1 : dst.last;
    var backRun = 0;
    for (int i = dst.length - 1; i >= 0 && dst[i] == color; i--) {
      backRun++;
      if (backRun >= mv.count) break;
    }
    return mv.count - backRun;
  }

  void _finishUndo() {
    _history.removeLast();
    moves = max(0, moves - 1);
    selected = -1;
    stuckBoard = false;
    hintFrom = -1;
    hintTo = -1;
    banner = 'Tap a tube to lift it 👆';
    onEvent?.call(HexaEvent.undo);
    _setPhase(HexaPhase.idle);
  }

  bool get canUndo => phase == HexaPhase.idle && !over && _history.isNotEmpty;

  /// The most recent pour (or undo replay), for the UI's fresh-hex pop-in.
  HexMove? get historyLast => _history.isEmpty ? null : _history.last;

  // ----------------------------------------------------------------- hint
  /// Show one useful legal pour, pulsing the two tubes. Consumes one hint
  /// from the free budget (3 per level); Pro is unlimited.
  void hint() {
    if (phase != HexaPhase.idle || over) return;
    if (hintsLeft <= 0) {
      onEvent?.call(HexaEvent.invalid);
      return;
    }
    final pick = _bestHint();
    if (pick == null) {
      onEvent?.call(HexaEvent.invalid);
      return;
    }
    hintsLeft--;
    hintFrom = pick.from;
    hintTo = pick.to;
    banner = 'Try pouring tube ${pick.from + 1} → tube ${pick.to + 1} 💡';
    onEvent?.call(HexaEvent.hint);
    _notify();
  }

  HexMove? _bestHint() {
    // Prefer moves that complete a color or land on a matching dest.
    HexMove? fallback;
    for (int f = 0; f < tubes.length; f++) {
      for (int t = 0; t < tubes.length; t++) {
        final count = pourCount(f, t);
        if (count <= 0) continue;
        final dst = tubes[t];
        if (dst.isEmpty) {
          fallback ??= HexMove(f, t, count);
          continue;
        }
        if (dst.length + count == hexCap) {
          return HexMove(f, t, count); // completes a tube — best move
        }
        return HexMove(f, t, count); // lands on matching color
      }
    }
    return fallback;
  }

  // ------------------------------------------------------------------ win
  void _beginWin() {
    over = true;
    lastWinMoves = moves;
    _setPhase(HexaPhase.winning);
    onEvent?.call(HexaEvent.win);
    _notify();
    _arm(const Duration(milliseconds: 900), _finishWin);
  }

  void _finishWin() {
    if (phase != HexaPhase.winning) return;
    banner = 'Sparkling clean! ✨';
    _setPhase(HexaPhase.over);
  }

  /// Start over: same level, fresh deal.
  void restart() {
    if (phase == HexaPhase.pouring || phase == HexaPhase.undoing) return;
    _timer?.cancel();
    _timer = null;
    _deal();
  }

  /// Next level: increments caller-side (level is immutable), so this
  /// rebuilds the deal for a new engine instead. Kept for symmetry.
  int get par => movesParFor(colorCountForLevel(level));

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
  }
}
