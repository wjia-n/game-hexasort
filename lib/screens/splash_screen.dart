import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';
import '../theme/hexa_ui.dart';
import 'menu_screen.dart';

/// Launch splash: SINGLE splash screen in two beats —
/// 1. a brief WAJIHA company moment (official logo, untouched), then
/// 2. the game splash (logo + name + animated loading line + credits).
class SplashScreen extends StatefulWidget {
  final HexaAudio audio;
  final HexaSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyMoment = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Beat 1: the company moment — WAJIHA logo, ~1.2s.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    // Beat 2: the game splash with its animated loading line.
    setState(() => _companyMoment = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HexaThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.bgDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _companyMoment
            ? _CompanyMoment(key: const ValueKey('company'), theme: theme)
            : _GameSplash(
                key: const ValueKey('game'), theme: theme, loader: _loader),
      ),
    );
  }
}

/// Beat 1: the WAJIHA company moment. The official winged-W logo is shown
/// untouched (copied verbatim into assets/), fading gently in.
class _CompanyMoment extends StatelessWidget {
  final HexaThemeDef theme;
  const _CompanyMoment({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text('WAJIHA', style: HexaUi.display(34, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'HANDMADE GAMES',
              style: HexaUi.label(12, theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final HexaThemeDef theme;
  final AnimationController loader;
  const _GameSplash(
      {super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return WorkshopBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/hexasort_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Hexa Sort', style: HexaUi.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'THE WOODEN HEX TRAY PUZZLE',
              style: HexaUi.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Polishing the hexes…' : 'Ready!',
                      style: HexaUi.body(13,
                          theme: theme,
                          color: theme.text.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: HexaUi.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
