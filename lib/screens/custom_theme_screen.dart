import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';
import '../theme/hexa_ui.dart';

/// PRO-only custom theme creator: pick your own workshop colors.
/// Preview updates live as you pick.
class CustomThemeScreen extends StatefulWidget {
  final HexaAudio audio;
  final HexaSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  static const List<Color> _swatches = [
    Color(0xFF2A1A10),
    Color(0xFF4A2F1B),
    Color(0xFF5C3A21),
    Color(0xFF16241A),
    Color(0xFF2C4433),
    Color(0xFF0F2230),
    Color(0xFF1F3E55),
    Color(0xFF2B1710),
    Color(0xFF55222D),
    Color(0xFF201A2E),
    Color(0xFF3A2F55),
    Color(0xFF414D22),
    Color(0xFFE8A93D),
    Color(0xFF9DBE8C),
    Color(0xFF6FB3D8),
    Color(0xFFEB8F4B),
    Color(0xFFE87D92),
    Color(0xFFC9A86A),
    Color(0xFFB49BE8),
    Color(0xFFD8C94B),
    Color(0xFFF7EBD7),
    Color(0xFFF0F5E9),
    Color(0xFFEAF4FB),
    Color(0xFFE5484D),
    Color(0xFFF5A623),
    Color(0xFF5FB760),
    Color(0xFF4A7FC9),
    Color(0xFF9B6BC7),
    Color(0xFFD9629B),
    Color(0xFF4BA3A3),
  ];

  static const List<(String, String)> _fields = [
    ('bgDark', 'Deep background'),
    ('bgMid', 'Mid background'),
    ('surface', 'Panels'),
    ('tube', 'Tube fill'),
    ('tubeRim', 'Tube rim'),
    ('accent', 'Accent'),
    ('accentLight', 'Accent light'),
    ('accentDark', 'Accent dark'),
    ('text', 'Text'),
    ('muted', 'Muted text'),
    ('tile0', 'Tile 1'),
    ('tile1', 'Tile 2'),
    ('tile2', 'Tile 3'),
    ('tile3', 'Tile 4'),
    ('tile4', 'Tile 5'),
    ('tile5', 'Tile 6'),
    ('tile6', 'Tile 7'),
    ('tile7', 'Tile 8'),
  ];

  String? _editing;

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.customTheme;
    final s = widget.settings;
    return WorkshopBackdrop(
      theme: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.pop(context);
            },
          ),
          title: Text('My Creation', style: HexaUi.title(22, theme: theme)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                widget.audio.click();
                s.resetCustomColors();
              },
              child: Text('Reset',
                  style: TextStyle(color: theme.accentLight)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => Column(
              children: [
                _preview(theme),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 8),
                    child: Column(
                      children: [
                        for (final (key, label) in _fields)
                          _fieldRow(theme, s, key, label),
                        const SizedBox(height: 16),
                        HexaButton(
                          label: 'Use my theme',
                          icon: Icons.check,
                          theme: theme,
                          onTap: () {
                            widget.audio.click();
                            s.setTheme('custom');
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(HexaThemeDef theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.bgMid, theme.bgDark],
        ),
        border: Border.all(color: theme.tubeRim),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < 8; i++)
                CustomPaint(
                  size: const Size(34, 31),
                  painter: HexTilePainter(
                    fill: theme.tiles[i],
                    shadowEdge: theme.bgDark,
                    styleId: 'gloss',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Preview', style: HexaUi.muted(11, theme: theme)),
        ],
      ),
    );
  }

  Widget _fieldRow(
      HexaThemeDef theme, HexaSettings s, String key, String label) {
    final current = Color(s.customColors[key] ?? 0xFF000000);
    final open = _editing == key;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            widget.audio.click();
            setState(() => _editing = open ? null : key);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.25),
              border: Border.all(
                  color: open ? theme.accent : theme.tubeRim),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: current,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: HexaUi.body(14, theme: theme))),
                Icon(
                    open
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: theme.muted),
              ],
            ),
          ),
        ),
        if (open)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: theme.tubeRim),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sw in _swatches)
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      s.setCustomColor(key, sw.toARGB32());
                      setState(() {});
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: sw,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: current.toARGB32() == sw.toARGB32()
                              ? theme.accentLight
                              : Colors.black26,
                          width: current.toARGB32() == sw.toARGB32()
                              ? 2.5
                              : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
