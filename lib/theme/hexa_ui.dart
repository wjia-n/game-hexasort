import 'package:flutter/material.dart';
import 'hexa_themes.dart';

/// Shared UI kit for Hexa Sort: typography, buttons, dialogs, backdrop and
/// the physical hex-tile painter. Warm workshop materials throughout —
/// wood, brass, clay — never neon, never generic.
class HexaUi {
  static TextStyle display(double size, {required HexaThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.text,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle title(double size, {required HexaThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: theme.text,
      );

  static TextStyle body(double size,
          {required HexaThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        color: color ?? theme.text.withValues(alpha: 0.9),
        height: 1.35,
      );

  static TextStyle label(double size, {required HexaThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: theme.accentLight,
      );

  static TextStyle muted(double size, {required HexaThemeDef theme}) =>
      TextStyle(fontSize: size, color: theme.muted);
}

/// Warm workshop backdrop: deep gradient + soft vignette.
class WorkshopBackdrop extends StatelessWidget {
  final HexaThemeDef theme;
  final Widget child;
  const WorkshopBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.bgMid, theme.bgDark],
        ),
      ),
      child: child,
    );
  }
}

/// Physical wooden-style button.
class HexaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool primary;
  final bool small;
  final VoidCallback? onTap;
  final HexaThemeDef theme;
  const HexaButton({
    super.key,
    required this.label,
    required this.theme,
    this.icon,
    this.primary = true,
    this.small = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 14 : 22, vertical: small ? 8 : 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(small ? 12 : 16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: primary
                  ? [theme.accentLight, theme.accent, theme.accentDark]
                  : [
                      theme.surface.withValues(alpha: 0.95),
                      theme.surface.withValues(alpha: 0.75)
                    ],
            ),
            border: Border.all(
              color: primary
                  ? theme.accentLight.withValues(alpha: 0.7)
                  : theme.tubeRim,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
              if (primary)
                BoxShadow(
                  color: theme.accent.withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: small ? 16 : 20,
                    color: primary ? theme.bgDark : theme.text),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 13 : 16,
                  fontWeight: FontWeight.w800,
                  color: primary ? theme.bgDark : theme.text,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded panel card with a soft shadow.
class HexaCard extends StatelessWidget {
  final HexaThemeDef theme;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const HexaCard(
      {super.key,
      required this.theme,
      required this.child,
      this.padding =
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.withValues(alpha: 0.95),
            theme.bgDark.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: theme.tubeRim, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Dialog sheet in the workshop style.
class HexaDialog extends StatelessWidget {
  final HexaThemeDef theme;
  final String title;
  final IconData? icon;
  final List<Widget> children;
  const HexaDialog(
      {super.key,
      required this.theme,
      required this.title,
      this.icon,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.surface, theme.bgDark],
          ),
          border: Border.all(color: theme.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(0, 12),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: theme.accentLight, size: 22),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(title,
                      style: HexaUi.title(20, theme: theme),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A single physical hex tile, rendered by [CustomPainter] per the active
/// [TileStyles] choice. Weight comes from edge shading + gloss + shadow.
class HexTilePainter extends CustomPainter {
  final Color fill;
  final Color shadowEdge;
  final String styleId;
  final bool dimmed; // empty slot look

  HexTilePainter({
    required this.fill,
    required this.shadowEdge,
    required this.styleId,
    this.dimmed = false,
  });

  Path _hexPath(double w, double h) => Path()
    ..moveTo(w * 0.25, 0)
    ..lineTo(w * 0.75, 0)
    ..lineTo(w, h / 2)
    ..lineTo(w * 0.75, h)
    ..lineTo(w * 0.25, h)
    ..lineTo(0, h / 2)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = _hexPath(w, h);

    if (dimmed) {
      canvas.drawPath(
          path,
          Paint()
            ..color = fill.withValues(alpha: 0.5)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = shadowEdge.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      return;
    }

    // Drop shadow for weight.
    canvas.drawPath(
        path.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Base tile body.
    canvas.drawPath(path, Paint()..color = fill);

    // Bottom-edge depth (tile thickness feel).
    final depth = Path()
      ..moveTo(0, h / 2)
      ..lineTo(w * 0.25, h)
      ..lineTo(w * 0.75, h)
      ..lineTo(w, h / 2)
      ..lineTo(w * 0.92, h * 0.42)
      ..lineTo(w * 0.75, h * 0.82)
      ..lineTo(w * 0.25, h * 0.82)
      ..lineTo(w * 0.08, h * 0.42)
      ..close();
    canvas.drawPath(
        depth, Paint()..color = Colors.black.withValues(alpha: 0.22));

    // Style-specific treatment.
    switch (styleId) {
      case 'matte':
        canvas.drawPath(
            path,
            Paint()
              ..color = shadowEdge.withValues(alpha: 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
      case 'stone':
        canvas.drawPath(
            path,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
        canvas.drawPath(
            _hexPath(w * 0.94, h * 0.94).shift(Offset(w * 0.03, h * 0.03)),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.12)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      case 'oak':
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFF8A5A2B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5);
        canvas.drawPath(
            _hexPath(w * 0.9, h * 0.9).shift(Offset(w * 0.05, h * 0.05)),
            Paint()
              ..color = const Color(0xFF8A5A2B).withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
      case 'candy':
        canvas.drawPath(
            path,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5);
        canvas.drawPath(
            path,
            Paint()
              ..color = shadowEdge.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      case 'brass':
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFD4AF37)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFF3DC8E).withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
      case 'ceramic':
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFBFD9E8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5);
      case 'gem':
        canvas.drawPath(
            path,
            Paint()
              ..color = shadowEdge.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        // Facet lines from center to corners.
        final cx = w / 2, cy = h / 2;
        final facet = Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = 1.4;
        canvas.drawLine(Offset(cx, cy), Offset(w * 0.25, 0), facet);
        canvas.drawLine(Offset(cx, cy), Offset(w * 0.75, 0), facet);
        canvas.drawLine(Offset(cx, cy), Offset(w, h / 2), facet);
        canvas.drawLine(Offset(cx, cy), Offset(w * 0.75, h), facet);
        canvas.drawLine(Offset(cx, cy), Offset(w * 0.25, h), facet);
        canvas.drawLine(Offset(cx, cy), Offset(0, h / 2), facet);
      case 'paper':
        canvas.drawPath(
            path,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case 'gloss':
      default:
        canvas.drawPath(
            path,
            Paint()
              ..color = shadowEdge.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
    }

    // Gloss highlight (all styles except matte/paper keep a sheen).
    if (styleId != 'matte' && styleId != 'paper') {
      final hi = Path()
        ..moveTo(w * 0.3, h * 0.14)
        ..lineTo(w * 0.58, h * 0.14)
        ..lineTo(w * 0.72, h * 0.46)
        ..lineTo(w * 0.44, h * 0.46)
        ..close();
      canvas.drawPath(
          hi, Paint()..color = Colors.white.withValues(alpha: 0.30));
    }
  }

  @override
  bool shouldRepaint(covariant HexTilePainter old) =>
      old.fill != fill ||
      old.styleId != styleId ||
      old.dimmed != dimmed ||
      old.shadowEdge != shadowEdge;
}

/// The tube rack behind a column of hexes.
class TubeRackPainter extends CustomPainter {
  final Color fill;
  final Color rim;
  final int accentIndex; // 0 walnut, 1 brass trim, 2 midnight steel
  TubeRackPainter(
      {required this.fill, required this.rim, this.accentIndex = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = RRect.fromLTRBR(
        0, 0, w, h, const Radius.circular(14));
    // Shadow.
    canvas.drawRRect(
        RRect.fromLTRBR(2, 4, w + 2, h + 4, const Radius.circular(14)),
        Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawRRect(r, Paint()..color = fill);
    // Inner groove.
    canvas.drawRRect(
        RRect.fromLTRBR(4, 4, w - 4, h - 4, const Radius.circular(11)),
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    // Rim.
    final rimColor = switch (accentIndex) {
      1 => const Color(0xFFD4AF37),
      2 => const Color(0xFF6B7688),
      _ => rim,
    };
    canvas.drawRRect(
        r,
        Paint()
          ..color = rimColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant TubeRackPainter old) =>
      old.fill != fill || old.rim != rim || old.accentIndex != accentIndex;
}
