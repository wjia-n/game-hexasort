import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/hexasort_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';
import '../theme/hexa_ui.dart';
import '../widgets/player_name_field.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Hexa Sort workshop edition.
/// Logo, PLAY, difficulty tiers, level picker, daily challenge, theme/tile/
 /// accent pickers, profile renaming, stats, settings, PRO, share, rate.
class MenuScreen extends StatefulWidget {
  final HexaAudio audio;
  final HexaSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final HexaStore _store = HexaStore();

  HexaSettings get _s => widget.settings;
  HexaThemeDef get _t =>
      HexaThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.levelComplete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: HexaUi.body(15, theme: _t)),
        backgroundColor: _t.bgDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  static const _shareUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.hexasort';

  Future<void> _share() async {
    widget.audio.click();
    try {
      await SharePlus.instance.share(ShareParams(
        text:
            'Hexa Sort — the oddly satisfying wooden hex-tray puzzle! 🍯⬡\n$_shareUrl',
        subject: 'Hexa Sort by WAJIHA',
      ));
    } catch (_) {}
  }

  void _play({int? level, bool daily = false}) {
    widget.audio.gameStart();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        audio: widget.audio,
        settings: _s,
        difficulty: _s.difficulty,
        level: level ?? _s.unlockedLevel(_s.difficulty),
        daily: daily,
      ),
    ))
        .then((_) {
      if (mounted) {
        widget.audio.startMenuMusic();
        setState(() {});
      }
    });
  }

  String _dailyKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = _s;
    return WorkshopBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _header(t, s),
                  const SizedBox(height: 14),
                  _playCard(t, s),
                  const SizedBox(height: 14),
                  _difficultyCard(t, s),
                  const SizedBox(height: 14),
                  _levelsCard(t, s),
                  const SizedBox(height: 14),
                  _dailyCard(t, s),
                  const SizedBox(height: 14),
                  _themesCard(t, s),
                  const SizedBox(height: 14),
                  _tilesCard(t, s),
                  const SizedBox(height: 14),
                  _profileCard(t, s),
                  const SizedBox(height: 14),
                  _statsRow(t, s),
                  const SizedBox(height: 14),
                  _actionsRow(t, s),
                  const SizedBox(height: 20),
                  _credits(t),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(HexaThemeDef t, HexaSettings s) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.accent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                offset: const Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/hexasort_logo.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 10),
        Text('Hexa Sort', style: HexaUi.display(38, theme: t)),
        const SizedBox(height: 2),
        Text(
          'Pour the colors into their own tubes — oddly satisfying',
          style: HexaUi.muted(13, theme: t),
          textAlign: TextAlign.center,
        ),
        if (s.isPro)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.accent),
            ),
            child: Text('⬡ PRO',
                style: TextStyle(
                    color: t.accentLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ play
  Widget _playCard(HexaThemeDef t, HexaSettings s) {
    final diffName = _diffName(s.difficulty);
    return HexaCard(
      theme: t,
      child: Column(
        children: [
          Text('Ready when you are, ${s.playerName}!',
              style: HexaUi.title(17, theme: t)),
          const SizedBox(height: 4),
          Text(
            'Level ${s.unlockedLevel(s.difficulty)} · $diffName',
            style: HexaUi.muted(13, theme: t),
          ),
          const SizedBox(height: 12),
          HexaButton(
            label: 'PLAY',
            icon: Icons.play_arrow,
            theme: t,
            onTap: () => _play(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              widget.audio.click();
              showDialog(
                context: context,
                builder: (_) => HexaDialog(
                  theme: t,
                  title: 'How to play',
                  icon: Icons.lightbulb_outline,
                  children: [
                    Text(
                      '• Tap a tube to lift it, then tap another tube to pour.\n'
                      '• You can only pour onto the same color (or an empty tube).\n'
                      '• Tubes hold 4 hexes. Pouring a full tube of one color into an empty tube is a wasted move — not allowed.\n'
                      '• Undo replays your last pour backwards. Hints are limited unless you are PRO.\n'
                      '• Win when every tube holds a single color. 50 levels per difficulty!',
                      style: HexaUi.body(14, theme: t),
                    ),
                    const SizedBox(height: 12),
                    HexaButton(
                      label: 'Got it',
                      theme: t,
                      small: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
            child: Text('How to play',
                style: TextStyle(color: t.accentLight, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _diffName(HexaDifficulty d) => switch (d) {
        HexaDifficulty.easy => 'Easy',
        HexaDifficulty.medium => 'Medium',
        HexaDifficulty.hard => 'Hard',
      };

  // ------------------------------------------------------------ difficulty
  Widget _difficultyCard(HexaThemeDef t, HexaSettings s) {
    return HexaCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIFFICULTY', style: HexaUi.label(12, theme: t)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in HexaDifficulty.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _diffChip(t, s, d),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            switch (s.difficulty) {
              HexaDifficulty.easy => 'Fewer colors, 3 spare tubes. Gentle.',
              HexaDifficulty.medium => 'The classic balance. 2 spare tubes.',
              HexaDifficulty.hard =>
                'Up to 8 colors, 2 spare tubes. PRO only.',
            },
            style: HexaUi.muted(12, theme: t),
          ),
        ],
      ),
    );
  }

  Widget _diffChip(HexaThemeDef t, HexaSettings s, HexaDifficulty d) {
    final locked = !s.isPro && d == HexaDifficulty.hard;
    final active = s.difficulty == d;
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          _openPro();
          return;
        }
        widget.audio.click();
        s.setDifficulty(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? t.accent.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
              color: active ? t.accent : t.tubeRim, width: active ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(_diffName(d),
                style: TextStyle(
                    color: active ? t.accentLight : t.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            if (locked)
              const Text('🔒 PRO', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- levels
  Widget _levelsCard(HexaThemeDef t, HexaSettings s) {
    final unlocked = s.unlockedLevel(s.difficulty);
    return HexaCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEVELS · ${_diffName(s.difficulty).toUpperCase()}',
                  style: HexaUi.label(12, theme: t)),
              Text('$unlocked / $hexLevels unlocked',
                  style: HexaUi.muted(12, theme: t)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int l = 1; l <= hexLevels; l++)
                GestureDetector(
                  onTap: l <= unlocked
                      ? () {
                          widget.audio.click();
                          _play(level: l);
                        }
                      : null,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: l == unlocked
                          ? t.accent.withValues(alpha: 0.3)
                          : (l < unlocked
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: l <= unlocked ? t.accent : t.tubeRim),
                    ),
                    child: l <= unlocked
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$l',
                                  style: TextStyle(
                                      color: l == unlocked
                                          ? t.accentLight
                                          : t.text,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              if (s.bestMovesFor(s.difficulty, l) != null)
                                Text('⬡',
                                    style: TextStyle(
                                        color: t.accentLight, fontSize: 8)),
                            ],
                          )
                        : Icon(Icons.lock,
                            size: 14, color: t.muted.withValues(alpha: 0.6)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- daily
  Widget _dailyCard(HexaThemeDef t, HexaSettings s) {
    final key = _dailyKey();
    final done = s.dailyDoneDate == key;
    return HexaCard(
      theme: t,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: t.accent.withValues(alpha: 0.2),
              border: Border.all(color: t.accent),
            ),
            child: Icon(Icons.calendar_today,
                color: t.accentLight, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Challenge',
                    style: HexaUi.title(16, theme: t)),
                Text(
                  done
                      ? 'Done today! Streak: ${s.dailyStreak} 🔥'
                      : 'Same puzzle for everyone today. Can you sort it?',
                  style: HexaUi.muted(12, theme: t),
                ),
              ],
            ),
          ),
          HexaButton(
            label: done ? 'Replay' : 'Play',
            theme: t,
            small: true,
            onTap: () => _play(daily: true),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- themes
  Widget _themesCard(HexaThemeDef t, HexaSettings s) {
    return HexaCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('THEMES', style: HexaUi.label(12, theme: t)),
              GestureDetector(
                onTap: () {
                  if (!s.isPro) {
                    _openPro();
                    return;
                  }
                  widget.audio.click();
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (_) => CustomThemeScreen(
                          audio: widget.audio,
                          settings: s,
                        ),
                      ))
                      .then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.accent),
                    color: t.accent.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    s.isPro ? '🎨 My Creation' : '🎨 Custom 🔒',
                    style: TextStyle(
                        color: t.accentLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.92,
            ),
            itemCount: HexaThemes.all.length,
            itemBuilder: (_, i) {
              final th = HexaThemes.all[i];
              final locked = !s.isPro && HexaThemes.isProTheme(th.id);
              final active = s.themeId == th.id;
              return GestureDetector(
                onTap: () {
                  if (locked) {
                    widget.audio.invalid();
                    _openPro();
                    return;
                  }
                  widget.audio.click();
                  s.setTheme(th.id);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: active ? t.accent : t.tubeRim,
                        width: active ? 2.5 : 1),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [th.bgMid, th.bgDark],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int k = 0; k < 4; k++)
                            Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: th.tiles[k],
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.black26, width: 1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          locked ? '🔒' : th.name,
                          style: TextStyle(
                              color: th.text,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ tiles
  Widget _tilesCard(HexaThemeDef t, HexaSettings s) {
    return HexaCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TILE STYLES', style: HexaUi.label(12, theme: t)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final st in TileStyles.all)
                GestureDetector(
                  onTap: () {
                    final locked = !s.isPro && TileStyles.isPro(st.id);
                    if (locked) {
                      widget.audio.invalid();
                      _openPro();
                      return;
                    }
                    widget.audio.click();
                    s.setTileStyle(st.id);
                  },
                  child: _tileChip(t, s, st),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('RACK FINISH', style: HexaUi.label(12, theme: t)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < BoardAccents.names.length; i++)
                GestureDetector(
                  onTap: () {
                    final locked = !s.isPro && BoardAccents.isPro(i);
                    if (locked) {
                      widget.audio.invalid();
                      _openPro();
                      return;
                    }
                    widget.audio.click();
                    s.setBoardAccent(i);
                  },
                  child: _accentChip(t, s, i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tileChip(HexaThemeDef t, HexaSettings s, TileStyleDef st) {
    final locked = !s.isPro && TileStyles.isPro(st.id);
    final active = s.tileStyleId == st.id;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active
            ? t.accent.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.25),
        border: Border.all(
            color: active ? t.accent : t.tubeRim, width: active ? 2 : 1),
      ),
      child: Text(
        locked ? '${st.name} 🔒' : st.name,
        style: TextStyle(
            color: active ? t.accentLight : t.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5),
      ),
    );
  }

  Widget _accentChip(HexaThemeDef t, HexaSettings s, int i) {
    final locked = !s.isPro && BoardAccents.isPro(i);
    final active = s.boardAccent == i;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active
            ? t.accent.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.25),
        border: Border.all(
            color: active ? t.accent : t.tubeRim, width: active ? 2 : 1),
      ),
      child: Text(
        locked ? '${BoardAccents.names[i]} 🔒' : BoardAccents.names[i],
        style: TextStyle(
            color: active ? t.accentLight : t.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5),
      ),
    );
  }

  // ---------------------------------------------------------------- profile
  // Inline editable name: saves on every keystroke, commits on focus loss.
  Widget _profileCard(HexaThemeDef t, HexaSettings s) {
    return HexaCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLAYER', style: HexaUi.label(12, theme: t)),
          const SizedBox(height: 8),
          PlayerNameField(settings: s, theme: t),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ stats
  Widget _statsRow(HexaThemeDef t, HexaSettings s) {
    return Row(
      children: [
        _statBox(t, '${s.levelsCompleted}', 'levels sorted'),
        const SizedBox(width: 10),
        _statBox(t, '${s.dailyWins}', 'daily wins'),
        const SizedBox(width: 10),
        _statBox(t, '${s.dailyStreak}🔥', 'day streak'),
      ],
    );
  }

  Widget _statBox(HexaThemeDef t, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.28),
          border: Border.all(color: t.tubeRim),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: t.accentLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(label, style: HexaUi.muted(11, theme: t)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- actions
  Widget _actionsRow(HexaThemeDef t, HexaSettings s) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        HexaButton(
          label: 'Settings',
          icon: Icons.settings,
          theme: t,
          small: true,
          primary: false,
          onTap: () {
            widget.audio.click();
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (_) => SettingsScreen(
                audio: widget.audio,
                settings: s,
              ),
            ))
                .then((_) {
              if (mounted) setState(() {});
            });
          },
        ),
        HexaButton(
          label: s.isPro ? 'PRO ✓' : 'Go PRO',
          icon: Icons.workspace_premium,
          theme: t,
          small: true,
          onTap: _openPro,
        ),
        HexaButton(
          label: 'Share',
          icon: Icons.share,
          theme: t,
          small: true,
          primary: false,
          onTap: _share,
        ),
        HexaButton(
          label: 'Rate us',
          icon: Icons.star,
          theme: t,
          small: true,
          primary: false,
          onTap: () {
            widget.audio.click();
            _requestReview();
          },
        ),
      ],
    );
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ProScreen(
            audio: widget.audio,
            settings: _s,
            store: _store,
          ),
        ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _credits(HexaThemeDef t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/wajiha_logo.png',
            width: 22, height: 22, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Text('Made with ♥ by WAJIHA',
            style: HexaUi.muted(12, theme: t)),
      ],
    );
  }
}
