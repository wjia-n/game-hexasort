import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/hexasort_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';
import '../theme/hexa_ui.dart';

/// Hexa Sort game screen — renders the engine, owns no game logic.
/// Every move animates visibly: the engine pours one hex at a time on its
/// own timer; the UI just paints. Undo replays backwards the same way.
class GameScreen extends StatefulWidget {
  final HexaAudio audio;
  final HexaSettings settings;
  final HexaDifficulty difficulty;
  final int level;
  final bool daily;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.difficulty,
    required this.level,
    this.daily = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  late HexaEngine _engine;
  bool _paused = false;
  bool _winHandled = false;
  int _freshTube = -1;
  int _freshIndex = -1;
  String? _snackKey; // avoid duplicate snackbars

  HexaThemeDef get _t => HexaThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final seed = widget.daily ? _dailySeed() : null;
    _engine = HexaEngine(
      level: widget.level,
      difficulty: widget.difficulty,
      isPro: widget.settings.isPro,
      seed: seed,
    );
    _engine.onEvent = _onEvent;
    _engine.onChanged = () {
      if (!mounted) return;
      setState(() {
        if (_engine.phase == HexaPhase.over && !_winHandled) {
          _winHandled = true;
          _onWin();
        }
      });
    };
    widget.audio.startGameMusic();
  }

  int _dailySeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  String _dailyKeyStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _onEvent(HexaEvent e) {
    switch (e) {
      case HexaEvent.lift:
        widget.audio.lift();
      case HexaEvent.drop:
        widget.audio.drop();
        _markFresh();
      case HexaEvent.invalid:
        widget.audio.invalid();
      case HexaEvent.pourDone:
        break; // drops already made their sounds
      case HexaEvent.undo:
        widget.audio.undo();
      case HexaEvent.hint:
        widget.audio.hint();
      case HexaEvent.stuck:
        widget.audio.stuck();
        _snack('No moves left — Undo or Restart 🔄');
      case HexaEvent.win:
        widget.audio.levelComplete();
    }
  }

  /// Track the most recently landed hex so the UI can pop it in.
  void _markFresh() {
    // The landing tube is the last pour's destination (or undo source).
    final h = _engine;
    if (h.tubes.isEmpty) return;
    // Find the tube whose top hex changed most recently: the freshest
    // landing is the top hex of the pour dest — engine just notified after
    // adding it. We approximate by scanning for the single deepest change
    // is overkill; instead the engine's last move tells us.
    final last = h.historyLast;
    if (last == null) return;
    final tubeIdx = h.phase == HexaPhase.undoing ? last.from : last.to;
    if (tubeIdx < 0 || tubeIdx >= h.tubes.length) return;
    _freshTube = tubeIdx;
    _freshIndex = h.tubes[tubeIdx].length - 1;
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted && _freshTube == tubeIdx) {
        setState(() {
          _freshTube = -1;
          _freshIndex = -1;
        });
      }
    });
  }

  void _snack(String msg) {
    if (_snackKey == msg || !mounted) return;
    _snackKey = msg;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: HexaUi.body(14, theme: _t)),
        backgroundColor: _t.bgDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () => _snackKey = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      if (!_paused) _engine.setPaused(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    super.dispose();
  }

  Future<void> _onWin() async {
    final moves = _engine.lastWinMoves ?? 0;
    final par = _engine.par;
    bool newBest = false;
    if (widget.daily) {
      await widget.settings.recordDailyWin(_dailyKeyStr());
    } else {
      newBest = await widget.settings.recordLevelComplete(
          widget.difficulty, widget.level, moves);
    }
    if (!mounted) return;
    // Sensible review moment: every 4th completed level, graceful when
    // the review sheet is unavailable (e.g. not installed from Play).
    if (!widget.daily &&
        widget.settings.levelsCompleted % 4 == 0 &&
        widget.settings.levelsCompleted > 0) {
      await widget.settings.bumpReviewPrompts();
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    _showWinDialog(moves, par, newBest);
  }

  void _showWinDialog(int moves, int par, bool newBest) {
    final t = _t;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HexaDialog(
        theme: t,
        title: widget.daily ? 'Daily sorted! 🔥' : 'Level ${widget.level} sorted!',
        icon: Icons.celebration,
        children: [
          Text(
            '$moves moves${newBest ? ' — new best! 🏆' : ''}',
            style: HexaUi.title(18, theme: t),
          ),
          const SizedBox(height: 4),
          Text(
            moves <= par
                ? 'Cleaner than par ($par). Chef\'s kiss. 👌'
                : 'Par is $par — you\'ll beat it next time!',
            style: HexaUi.muted(13, theme: t),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!widget.daily && widget.level < hexLevels)
            HexaButton(
              label: 'Next level',
              icon: Icons.arrow_forward,
              theme: t,
              onTap: () {
                widget.audio.click();
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      audio: widget.audio,
                      settings: widget.settings,
                      difficulty: widget.difficulty,
                      level: widget.level + 1,
                    ),
                  ),
                );
              },
            ),
          if (!widget.daily && widget.level < hexLevels)
            const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HexaButton(
                label: 'Replay',
                icon: Icons.replay,
                theme: t,
                small: true,
                primary: false,
                onTap: () {
                  widget.audio.click();
                  Navigator.pop(ctx);
                  setState(() {
                    _winHandled = false;
                    _engine.restart();
                  });
                },
              ),
              const SizedBox(width: 10),
              HexaButton(
                label: 'Menu',
                icon: Icons.home,
                theme: t,
                small: true,
                onTap: () {
                  widget.audio.click();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      _engine.setPaused(_paused);
    });
    widget.audio.click();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WorkshopBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(t),
                  _infoBar(t),
                  Expanded(child: _board(t)),
                  _bannerBar(t),
                ],
              ),
              if (_paused) _pauseOverlay(t),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- top bar
  Widget _topBar(HexaThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.daily
                      ? 'Daily Challenge'
                      : 'Level ${widget.level} · ${_diffName(widget.difficulty)}',
                  style: HexaUi.title(17, theme: t),
                ),
                Text('${_engine.moves} moves · par ${_engine.par}',
                    style: HexaUi.muted(12, theme: t)),
              ],
            ),
          ),
          _iconBtn(t, Icons.lightbulb_outline, () {
            if (_engine.hintsLeft <= 0 && !widget.settings.isPro) {
              widget.audio.invalid();
              _snack('Out of hints — PRO gets unlimited 💡');
              return;
            }
            _engine.hint();
          }, badge: _hintBadge(t)),
          _iconBtn(t, Icons.undo,
              _engine.canUndo ? _engine.undo : null),
          _iconBtn(t, Icons.refresh, () {
            widget.audio.click();
            _engine.restart();
          }),
          _iconBtn(t, Icons.pause, _togglePause),
        ],
      ),
    );
  }

  String _diffName(HexaDifficulty d) => switch (d) {
        HexaDifficulty.easy => 'Easy',
        HexaDifficulty.medium => 'Medium',
        HexaDifficulty.hard => 'Hard',
      };

  String? _hintBadge(HexaThemeDef t) {
    if (widget.settings.isPro) return null;
    return '${_engine.hintsLeft}';
  }

  Widget _iconBtn(HexaThemeDef t, IconData icon, VoidCallback? onTap,
      {String? badge}) {
    final enabled = onTap != null;
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon,
              color: enabled ? t.accentLight : t.muted.withValues(alpha: 0.4)),
          onPressed: onTap == null
              ? null
              : () {
                  onTap();
                },
        ),
        if (badge != null)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: t.bgDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- info bar
  Widget _infoBar(HexaThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 14, color: t.muted),
          const SizedBox(width: 4),
          Text(widget.settings.playerName,
              style: HexaUi.muted(12, theme: t)),
          const SizedBox(width: 14),
          if (widget.settings.isPro)
            Text('⬡ PRO',
                style: TextStyle(
                    color: t.accentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ board
  Widget _board(HexaThemeDef t) {
    const tubeW = 76.0;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 16,
            children: [
              for (int i = 0; i < _engine.tubes.length; i++)
                _Tube(
                  key: ValueKey('tube_$i'),
                  index: i,
                  tube: _engine.tubes[i],
                  theme: t,
                  tileColors: t.tiles,
                  tileStyleId: widget.settings.tileStyleId,
                  accentIndex: widget.settings.boardAccent,
                  selected: _engine.selected == i,
                  hinted: _engine.hintFrom == i || _engine.hintTo == i,
                  hintTarget: _engine.hintTo == i,
                  tubeWidth: tubeW,
                  freshIndex:
                      _freshTube == i ? _freshIndex : -1,
                  onTap: () => _engine.tapTube(i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- banner
  Widget _bannerBar(HexaThemeDef t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(
          _engine.banner,
          key: ValueKey(_engine.banner),
          style: TextStyle(
              color: _engine.stuckBoard ? t.accentLight : t.muted,
              fontSize: 13,
              fontWeight:
                  _engine.stuckBoard ? FontWeight.w700 : FontWeight.w400),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ----------------------------------------------------------- pause overlay
  Widget _pauseOverlay(HexaThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: HexaDialog(
          theme: t,
          title: 'Paused',
          icon: Icons.pause,
          children: [
            HexaButton(
              label: 'Resume',
              icon: Icons.play_arrow,
              theme: t,
              onTap: _togglePause,
            ),
            const SizedBox(height: 10),
            HexaButton(
              label: 'Restart level',
              icon: Icons.refresh,
              theme: t,
              primary: false,
              onTap: () {
                widget.audio.click();
                setState(() {
                  _paused = false;
                  _engine.setPaused(false);
                  _engine.restart();
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _toggleChip(t, Icons.music_note, 'Music',
                    widget.settings.musicOn, (v) {
                  widget.settings.setMusic(v);
                  widget.audio.configure(
                      musicOn: v,
                      sfxOn: widget.settings.sfxOn,
                      volume: widget.settings.volume);
                  if (v) {
                    widget.audio.startGameMusic();
                  } else {
                    widget.audio.stopMusic();
                  }
                }),
                const SizedBox(width: 10),
                _toggleChip(t, Icons.volume_up, 'SFX', widget.settings.sfxOn,
                    (v) {
                  widget.settings.setSfx(v);
                  widget.audio.configure(
                      musicOn: widget.settings.musicOn,
                      sfxOn: v,
                      volume: widget.settings.volume);
                }),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                widget.audio.click();
                Navigator.pop(context);
              },
              child: Text('Quit to menu',
                  style: TextStyle(color: t.accentLight)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(HexaThemeDef t, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        onChanged(!value);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? t.accent.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: value ? t.accent : t.tubeRim),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: value ? t.accentLight : t.muted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: value ? t.accentLight : t.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// One tube rack with a column of hex tiles.
class _Tube extends StatelessWidget {
  final int index;
  final List<int> tube;
  final HexaThemeDef theme;
  final List<Color> tileColors;
  final String tileStyleId;
  final int accentIndex;
  final bool selected;
  final bool hinted;
  final bool hintTarget;
  final double tubeWidth;
  final int freshIndex;
  final VoidCallback onTap;

  const _Tube({
    super.key,
    required this.index,
    required this.tube,
    required this.theme,
    required this.tileColors,
    required this.tileStyleId,
    required this.accentIndex,
    required this.selected,
    required this.hinted,
    required this.hintTarget,
    required this.tubeWidth,
    required this.freshIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const hexW = 52.0;
    const hexH = 47.0;
    final won = tube.length == hexCap &&
        tube.isNotEmpty &&
        tube.every((c) => c == tube.first);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, selected ? -14 : 0, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? theme.accent.withValues(alpha: 0.16)
              : hinted
                  ? (hintTarget
                      ? theme.accent.withValues(alpha: 0.28)
                      : theme.accentLight.withValues(alpha: 0.14))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected || hinted
                ? theme.accent
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CustomPaint(
                  size: Size(tubeWidth - 16, hexH * hexCap + 26),
                  painter: TubeRackPainter(
                    fill: theme.tube,
                    rim: theme.tubeRim,
                    accentIndex: accentIndex,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Empty slots (dimmed) sit above the real tiles.
                        for (int i = hexCap - 1; i >= 0; i--)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 1.5),
                            child: i < tube.length
                                ? TweenAnimationBuilder<double>(
                                    tween: Tween(
                                        begin: (i == freshIndex ||
                                                (won && i == 0))
                                            ? 0.3
                                            : 1.0,
                                        end: 1.0),
                                    duration: const Duration(
                                        milliseconds: 220),
                                    builder: (_, scale, child) =>
                                        Transform.scale(
                                      scale: scale,
                                      child: CustomPaint(
                                        size: const Size(hexW, hexH),
                                        painter: HexTilePainter(
                                          fill: tileColors[
                                              tube[i] % tileColors.length],
                                          shadowEdge: theme.bgDark,
                                          styleId: tileStyleId,
                                        ),
                                      ),
                                    ),
                                  )
                                : CustomPaint(
                                    size: const Size(hexW, hexH),
                                    painter: HexTilePainter(
                                      fill: theme.tube,
                                      shadowEdge: theme.tubeRim,
                                      styleId: tileStyleId,
                                      dimmed: true,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (won)
                  Positioned(
                    top: 2,
                    right: 4,
                    child: Icon(Icons.check_circle,
                        color: theme.accentLight, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${index + 1}',
              style: TextStyle(
                  color: theme.muted.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
