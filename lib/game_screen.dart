import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

const _cap = 4;
const _levels = 12;
const _sortColors = <Color>[
  Color(0xFFE5484D),
  Color(0xFFFF9F2E),
  Color(0xFFFFD60A),
  Color(0xFF30D158),
  Color(0xFF40C4AA),
  Color(0xFF0A84FF),
  Color(0xFFBF5AF2),
  Color(0xFFFF5AA0),
];

class HexaSortScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const HexaSortScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<HexaSortScreen> createState() => _HexaSortScreenState();
}

class _HexaSortScreenState extends State<HexaSortScreen> {
  final _rnd = Random();
  int _level = 1;
  int _unlocked = 1;
  List<List<int>> _tubes = [];
  int _selected = -1;
  bool _busy = false;
  bool _over = false;
  final List<List<List<int>>> _undo = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _unlocked = p.getInt('hs_unlocked') ?? 1;
        _level = min(_unlocked, _levels);
      });
      _deal();
    });
    _deal();
  }

  int _colorCount(int level) => min(3 + (level - 1) ~/ 2, 8);

  void _deal() {
    final nColors = _colorCount(_level);
    final nTubes = nColors + 2;
    final pool = <int>[];
    for (int c = 0; c < nColors; c++) {
      pool.addAll(List.filled(_cap, c));
    }
    pool.shuffle(_rnd);
    _tubes = List.generate(nTubes, (_) => <int>[]);
    for (int i = 0; i < pool.length; i++) {
      _tubes[i % nColors].add(pool[i]);
    }
    // avoid instantly-solved deals
    if (_isWon()) {
      _deal();
      return;
    }
    _selected = -1;
    _busy = false;
    _over = false;
    _undo.clear();
    setState(() {});
  }

  bool _isWon() {
    for (final t in _tubes) {
      if (t.isEmpty) continue;
      if (t.length != _cap) return false;
      if (t.any((c) => c != t.first)) return false;
    }
    return true;
  }

  bool _canPour(int from, int to) {
    if (from == to || _tubes[from].isEmpty) return false;
    if (_tubes[to].length >= _cap) return false;
    if (_tubes[to].isEmpty) return true;
    return _tubes[to].last == _tubes[from].last;
  }

  Future<void> _pour(int from, int to) async {
    if (!_canPour(from, to) || _busy || _over) return;
    _undo.add([for (final t in _tubes) [...t]]);
    setState(() => _busy = true);
    // pour the contiguous top run one hex at a time for a juicy animation
    final color = _tubes[from].last;
    while (_tubes[from].isNotEmpty &&
        _tubes[from].last == color &&
        _tubes[to].length < _cap) {
      _tubes[from].removeLast();
      _tubes[to].add(color);
      setState(() {});
      Sfx.tap();
      await Future.delayed(const Duration(milliseconds: 130));
      if (!mounted) return;
    }
    setState(() {
      _busy = false;
      _selected = -1;
    });
    if (_isWon()) _winLevel();
  }

  void _tapTube(int i) {
    if (_busy || _over) return;
    if (_selected == -1) {
      if (_tubes[i].isEmpty) return;
      setState(() => _selected = i);
      Sfx.tap();
    } else if (_selected == i) {
      setState(() => _selected = -1);
      Sfx.tap();
    } else {
      _pour(_selected, i);
    }
  }

  void _undoMove() {
    if (_busy || _over || _undo.isEmpty) return;
    setState(() {
      _tubes = _undo.removeLast();
      _selected = -1;
    });
    Sfx.click();
  }

  Future<void> _winLevel() async {
    setState(() => _over = true);
    Sfx.win();
    widget.players.first.score += _level * 100;
    widget.callbacks.refreshHud();
    if (_level == _unlocked && _unlocked < _levels) {
      _unlocked++;
      final p = await SharedPreferences.getInstance();
      await p.setInt('hs_unlocked', _unlocked);
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (_level >= _levels) {
      widget.callbacks.finish(
        headline: '⬡ All 12 levels sorted!',
        subline: 'Certified color wizard. The rainbow bows to you.',
      );
    } else {
      setState(() => _level++);
      _deal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WajihaButton(
                  label: 'Level $_level',
                  emoji: '⬡',
                  primary: false,
                  onTap: _showLevels),
              const SizedBox(width: 10),
              WajihaButton(
                  label: 'Undo',
                  emoji: '↩️',
                  primary: false,
                  onTap: _undoMove),
              const SizedBox(width: 10),
              WajihaButton(
                  label: 'Restart',
                  emoji: '🔄',
                  primary: false,
                  onTap: _deal),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 18,
              children: [
                for (int i = 0; i < _tubes.length; i++)
                  _HexTube(
                    tube: _tubes[i],
                    selected: _selected == i,
                    pouring: _busy && _selected == i,
                    theme: theme,
                    onTap: () => _tapTube(i),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _over
                ? 'Sparkling clean! ✨'
                : _selected == -1
                    ? 'Tap a tube to lift it 👆'
                    : 'Now tap where it should pour 🫗',
            style: TextStyle(color: theme.muted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _showLevels() {
    final theme = ThemeController.of(context).theme;
    showDialog(
      context: context,
      builder: (ctx) => WajihaDialog(
        title: 'Pick a level',
        emoji: '⬡',
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int l = 1; l <= _levels; l++)
                GestureDetector(
                  onTap: l <= _unlocked
                      ? () {
                          Navigator.pop(ctx);
                          setState(() => _level = l);
                          _deal();
                          Sfx.click();
                        }
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: l == _level
                          ? theme.primary
                          : (l <= _unlocked ? theme.surface : theme.background),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: l <= _unlocked ? theme.primary : theme.muted),
                    ),
                    child: Text(l <= _unlocked ? '$l' : '🔒',
                        style: TextStyle(
                            color: l == _level ? Colors.white : theme.text,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HexTube extends StatelessWidget {
  final List<int> tube;
  final bool selected;
  final bool pouring;
  final GameTheme theme;
  final VoidCallback onTap;
  const _HexTube(
      {required this.tube,
      required this.selected,
      required this.pouring,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, selected ? -14 : 0, 0)
          ..rotateZ(pouring ? 0.5 : 0.0),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? theme.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: theme.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = _cap - 1; i >= 0; i--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: CustomPaint(
                  size: const Size(40, 36),
                  painter: _HexPainter(
                    fill: i < tube.length
                        ? _sortColors[tube[i]]
                        : theme.surface,
                    border: theme.muted,
                    empty: i >= tube.length,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            CustomPaint(
              size: const Size(46, 10),
              painter: _BasePainter(color: theme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color fill;
  final Color border;
  final bool empty;
  _HexPainter({required this.fill, required this.border, required this.empty});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w * 0.75, h)
      ..lineTo(w * 0.25, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = empty ? fill.withValues(alpha: 0.45) : fill
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = border.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    if (!empty) {
      // glossy highlight
      final hi = Path()
        ..moveTo(w * 0.3, h * 0.18)
        ..lineTo(w * 0.55, h * 0.18)
        ..lineTo(w * 0.68, h * 0.5)
        ..lineTo(w * 0.43, h * 0.5)
        ..close();
      canvas.drawPath(
          hi, Paint()..color = Colors.white.withValues(alpha: 0.28));
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.fill != fill || old.empty != empty;
}

class _BasePainter extends CustomPainter {
  final Color color;
  _BasePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromLTRBR(0, 0, size.width, size.height,
        const Radius.circular(5));
    canvas.drawRRect(r, Paint()..color = color.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _BasePainter old) => false;
}
