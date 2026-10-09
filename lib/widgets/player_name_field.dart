import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';

/// Inline renameable player-name field, shared by the menu and settings
/// screens.
///
/// Persistence contract (MASTER_RULES.md):
/// - The name is written to prefs on EVERY keystroke (not just
///   keyboard-done) via [HexaSettings.updatePlayerNameLive].
/// - It is committed (trimmed, defaulted) on focus loss, submit, or dispose
///   via [HexaSettings.commitPlayerName].
/// - Storage is ONE order-preserving JSON string under
///   `hexasort_player_names_json` via setString — never setStringList.
class PlayerNameField extends StatefulWidget {
  final HexaSettings settings;
  final HexaThemeDef theme;
  const PlayerNameField(
      {super.key, required this.settings, required this.theme});

  @override
  State<PlayerNameField> createState() => _PlayerNameFieldState();
}

class _PlayerNameFieldState extends State<PlayerNameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.settings.playerName);
    _focus = FocusNode();
    // Commit on focus loss.
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        widget.settings.commitPlayerName();
      }
    });
    // Stay in sync if the name changes from elsewhere (e.g. a restore).
    widget.settings.addListener(_syncFromSettings);
  }

  void _syncFromSettings() {
    if (!_focus.hasFocus && _c.text != widget.settings.playerName) {
      _c.text = widget.settings.playerName;
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_syncFromSettings);
    // Commit whatever is in the field even if focus never moved.
    widget.settings.commitPlayerName();
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.accent.withValues(alpha: 0.25),
            border: Border.all(color: t.accent, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.settings.playerName.isEmpty
                ? '?'
                : widget.settings.playerName[0].toUpperCase(),
            style: TextStyle(
                color: t.accentLight,
                fontSize: 20,
                fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                  color: t.accent.withValues(alpha: 0.55)),
            ),
            child: TextField(
              controller: _c,
              focusNode: _focus,
              style: TextStyle(color: t.text, fontSize: 17),
              maxLength: 16,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Your name',
                hintStyle: TextStyle(color: t.muted),
              ),
              // Save on EVERY keystroke — never wait for keyboard-done.
              onChanged: (v) => widget.settings.updatePlayerNameLive(v),
              onSubmitted: (_) {
                widget.settings.commitPlayerName();
                _focus.unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }
}
