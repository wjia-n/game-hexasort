import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';
import '../theme/hexa_ui.dart';
import '../widgets/player_name_field.dart';

/// Settings: music/SFX toggles, volume, profile rename, progress reset,
/// credits.
class SettingsScreen extends StatefulWidget {
  final HexaAudio audio;
  final HexaSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  HexaThemeDef get _t => HexaThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WorkshopBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.pop(context);
            },
          ),
          title: Text('Settings', style: HexaUi.title(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  HexaCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AUDIO', style: HexaUi.label(12, theme: t)),
                        const SizedBox(height: 12),
                        _switchRow(t, Icons.music_note, 'Music', s.musicOn,
                            (v) async {
                          await s.setMusic(v);
                          _applyAudio();
                          if (v) {
                            widget.audio.startMenuMusic();
                          } else {
                            widget.audio.stopMusic();
                          }
                        }),
                        _switchRow(t, Icons.volume_up, 'Sound effects',
                            s.sfxOn, (v) async {
                          await s.setSfx(v);
                          _applyAudio();
                          if (v) widget.audio.click();
                        }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.tune,
                                color: t.accentLight, size: 20),
                            Expanded(
                              child: Slider(
                                value: s.volume,
                                min: 0,
                                max: 1,
                                activeColor: t.accent,
                                inactiveColor: t.tubeRim,
                                onChanged: (v) {
                                  s.setVolume(v);
                                  _applyAudio();
                                },
                              ),
                            ),
                            Text('${(s.volume * 100).round()}%',
                                style: HexaUi.muted(12, theme: t)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  HexaCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYER', style: HexaUi.label(12, theme: t)),
                        const SizedBox(height: 12),
                        // Inline editable name: saves on every keystroke,
                        // commits on focus loss.
                        PlayerNameField(settings: s, theme: t),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  HexaCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROGRESS', style: HexaUi.label(12, theme: t)),
                        const SizedBox(height: 12),
                        Text(
                          '${s.levelsCompleted} levels sorted · ${s.dailyWins} daily wins',
                          style: HexaUi.body(14, theme: t),
                        ),
                        const SizedBox(height: 10),
                        HexaButton(
                          label: 'Reset all progress',
                          icon: Icons.delete_outline,
                          theme: t,
                          small: true,
                          primary: false,
                          onTap: () => _confirmReset(t, s),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 24, height: 24, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: HexaUi.muted(13, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchRow(HexaThemeDef t, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: t.accentLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: HexaUi.body(15, theme: t))),
          Switch(
            value: value,
            activeThumbColor: t.accent,
            onChanged: (v) {
              widget.audio.click();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  void _confirmReset(HexaThemeDef t, HexaSettings s) {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (ctx) => HexaDialog(
        theme: t,
        title: 'Reset everything?',
        icon: Icons.warning_amber,
        children: [
          Text(
            'Unlocked levels, best move counts and stats go back to zero. This cannot be undone.',
            style: HexaUi.body(14, theme: t),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HexaButton(
                label: 'Keep it',
                theme: t,
                small: true,
                primary: false,
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 12),
              HexaButton(
                label: 'Reset',
                theme: t,
                small: true,
                onTap: () {
                  widget.audio.click();
                  s.resetProgress();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
