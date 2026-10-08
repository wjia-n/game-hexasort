import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const HexaSortApp());

class HexaSortApp extends StatelessWidget {
  const HexaSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.comicBurst,
      title: 'Hexa Sort',
      tagline: 'Pour the colors into their own hex tubes — oddly satisfying',
      emoji: '⬡',
      slug: 'hexasort',
      howToPlay:
          '• Tap a hex tube to pick it up, then tap another tube to pour.\n• You can only pour onto the same color (or an empty tube).\n• Tubes hold 4 hexes. Undo is your best friend.\n• Win when every tube holds one color. 12 levels of zen!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          HexaSortScreen(players: players, callbacks: cb),
    );
  }
}
