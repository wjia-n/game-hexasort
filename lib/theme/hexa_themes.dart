import 'package:flutter/material.dart';

/// Theme, tile-style and board-accent catalogs for Hexa Sort.
///
/// Everything stays inside the warm physical-material world of a wooden
/// workshop desk toy: real woods, honey, clay, stone, brass. No neon,
/// no cyberpunk, no glowing synthetic looks.
class HexaThemeDef {
  final String id;
  final String name;
  final Color bgDark; // page background (deep)
  final Color bgMid; // page background (mid)
  final Color surface; // cards, panels
  final Color tube; // empty hex slot fill
  final Color tubeRim; // tube outline
  final Color accent; // buttons, borders
  final Color accentLight;
  final Color accentDark;
  final Color text;
  final Color muted;
  final List<Color> tiles; // 8 piece colors

  const HexaThemeDef({
    required this.id,
    required this.name,
    required this.bgDark,
    required this.bgMid,
    required this.surface,
    required this.tube,
    required this.tubeRim,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.text,
    required this.muted,
    required this.tiles,
  });
}

class HexaThemes {
  /// The 4 FREE starter themes. Everything else is PRO.
  static const List<String> freeThemeIds = [
    'honey',
    'sage',
    'ocean',
    'terracotta',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static const List<HexaThemeDef> all = [
    HexaThemeDef(
      id: 'honey',
      name: 'Honey Workshop',
      bgDark: Color(0xFF2A1A10),
      bgMid: Color(0xFF4A2F1B),
      surface: Color(0xFF5C3A21),
      tube: Color(0xFF3A2412),
      tubeRim: Color(0xFF8A5A2B),
      accent: Color(0xFFE8A93D),
      accentLight: Color(0xFFFFD58A),
      accentDark: Color(0xFF9C6A1F),
      text: Color(0xFFF7EBD7),
      muted: Color(0xFFC4A67E),
      tiles: [
        Color(0xFFE5484D),
        Color(0xFFF5A623),
        Color(0xFFF2D13C),
        Color(0xFF5FB760),
        Color(0xFF4BA3A3),
        Color(0xFF4A7FC9),
        Color(0xFF9B6BC7),
        Color(0xFFD9629B),
      ],
    ),
    HexaThemeDef(
      id: 'sage',
      name: 'Sage Garden',
      bgDark: Color(0xFF16241A),
      bgMid: Color(0xFF2C4433),
      surface: Color(0xFF3A5540),
      tube: Color(0xFF203227),
      tubeRim: Color(0xFF5F7A5E),
      accent: Color(0xFF9DBE8C),
      accentLight: Color(0xFFD7EDC8),
      accentDark: Color(0xFF5E7F52),
      text: Color(0xFFF0F5E9),
      muted: Color(0xFFA8BFA0),
      tiles: [
        Color(0xFFC75B4A),
        Color(0xFFE0A458),
        Color(0xFFE8D27A),
        Color(0xFF7CB342),
        Color(0xFF4DB6AC),
        Color(0xFF5C9BD5),
        Color(0xFF9575CD),
        Color(0xFFD97B9E),
      ],
    ),
    HexaThemeDef(
      id: 'ocean',
      name: 'Ocean Drift',
      bgDark: Color(0xFF0F2230),
      bgMid: Color(0xFF1F3E55),
      surface: Color(0xFF2C4F6B),
      tube: Color(0xFF162C40),
      tubeRim: Color(0xFF4E7A99),
      accent: Color(0xFF6FB3D8),
      accentLight: Color(0xFFBFE3F5),
      accentDark: Color(0xFF3E748F),
      text: Color(0xFFEAF4FB),
      muted: Color(0xFF9DBCCE),
      tiles: [
        Color(0xFFE0655F),
        Color(0xFFECA14E),
        Color(0xFFF0D060),
        Color(0xFF66BB6A),
        Color(0xFF26A69A),
        Color(0xFF42A5F5),
        Color(0xFF7E7BDB),
        Color(0xFFEC6FA0),
      ],
    ),
    HexaThemeDef(
      id: 'terracotta',
      name: 'Terracotta Sun',
      bgDark: Color(0xFF2B1710),
      bgMid: Color(0xFF54291A),
      surface: Color(0xFF6B3620),
      tube: Color(0xFF3A1E12),
      tubeRim: Color(0xFF96552F),
      accent: Color(0xFFEB8F4B),
      accentLight: Color(0xFFFFC48F),
      accentDark: Color(0xFFA25726),
      text: Color(0xFFFBEBDC),
      muted: Color(0xFFD2A583),
      tiles: [
        Color(0xFFD94F3D),
        Color(0xFFF0A24A),
        Color(0xFFF5D547),
        Color(0xFF8AB661),
        Color(0xFF58A89B),
        Color(0xFF5B8FD6),
        Color(0xFFA87BD1),
        Color(0xFFE0769E),
      ],
    ),
    HexaThemeDef(
      id: 'cherry',
      name: 'Cherry Orchard',
      bgDark: Color(0xFF2A1218),
      bgMid: Color(0xFF55222D),
      surface: Color(0xFF682E3B),
      tube: Color(0xFF3A1820),
      tubeRim: Color(0xFF94505F),
      accent: Color(0xFFE87D92),
      accentLight: Color(0xFFFFB3C2),
      accentDark: Color(0xFFA04A5E),
      text: Color(0xFFFBEDEf),
      muted: Color(0xFFD3A4AE),
      tiles: [
        Color(0xFFE14B5A),
        Color(0xFFF2994A),
        Color(0xFFF2CE5F),
        Color(0xFF7FB069),
        Color(0xFF4FB0A5),
        Color(0xFF6B8FDB),
        Color(0xFFB07FD6),
        Color(0xFFF06FA5),
      ],
    ),
    HexaThemeDef(
      id: 'walnut',
      name: 'Midnight Walnut',
      bgDark: Color(0xFF120E0A),
      bgMid: Color(0xFF2B2118),
      surface: Color(0xFF3A2D1F),
      tube: Color(0xFF1D1610),
      tubeRim: Color(0xFF6B543A),
      accent: Color(0xFFC9A86A),
      accentLight: Color(0xFFEED9A8),
      accentDark: Color(0xFF7E6238),
      text: Color(0xFFF5EAD6),
      muted: Color(0xFFB9A181),
      tiles: [
        Color(0xFFC94F4F),
        Color(0xFFD9A05B),
        Color(0xFFE8D26B),
        Color(0xFF7BAF6B),
        Color(0xFF5FA8A0),
        Color(0xFF6B93D1),
        Color(0xFF9D7FD1),
        Color(0xFFD97B9E),
      ],
    ),
    HexaThemeDef(
      id: 'lavender',
      name: 'Lavender Study',
      bgDark: Color(0xFF201A2E),
      bgMid: Color(0xFF3A2F55),
      surface: Color(0xFF4A3D6B),
      tube: Color(0xFF2A2340),
      tubeRim: Color(0xFF6F5F99),
      accent: Color(0xFFB49BE8),
      accentLight: Color(0xFFE0D0FA),
      accentDark: Color(0xFF7A63A8),
      text: Color(0xFFF1EAFB),
      muted: Color(0xFFB6A8D4),
      tiles: [
        Color(0xFFD85A6B),
        Color(0xFFEE9F55),
        Color(0xFFF5D76E),
        Color(0xFF8BC34A),
        Color(0xFF4DB6AC),
        Color(0xFF64B5F6),
        Color(0xFF9575CD),
        Color(0xFFF06292),
      ],
    ),
    HexaThemeDef(
      id: 'citrus',
      name: 'Citrus Grove',
      bgDark: Color(0xFF1E2410),
      bgMid: Color(0xFF414D22),
      surface: Color(0xFF55632E),
      tube: Color(0xFF2A3218),
      tubeRim: Color(0xFF7A8548),
      accent: Color(0xFFD8C94B),
      accentLight: Color(0xFFF2E896),
      accentDark: Color(0xFF8F7F26),
      text: Color(0xFFF7F3DE),
      muted: Color(0xFFC2B98C),
      tiles: [
        Color(0xFFDD5A45),
        Color(0xFFF0A83E),
        Color(0xFFF7DE4B),
        Color(0xFF9DBE4B),
        Color(0xFF55B38A),
        Color(0xFF5FA8D8),
        Color(0xFFA283D6),
        Color(0xFFE87FA0),
      ],
    ),
    HexaThemeDef(
      id: 'rosewood',
      name: 'Rosewood Parlor',
      bgDark: Color(0xFF241012),
      bgMid: Color(0xFF4E2124),
      surface: Color(0xFF612C2E),
      tube: Color(0xFF33171A),
      tubeRim: Color(0xFF8C4A4E),
      accent: Color(0xFFD98C6B),
      accentLight: Color(0xFFF2BE9E),
      accentDark: Color(0xFF94522F),
      text: Color(0xFFF9EADB),
      muted: Color(0xFFCCA18E),
      tiles: [
        Color(0xFFC7484F),
        Color(0xFFDA8F4E),
        Color(0xFFE8C85F),
        Color(0xFF86AC62),
        Color(0xFF5EA393),
        Color(0xFF6B8DCB),
        Color(0xFF9C7BC9),
        Color(0xFFD9738F),
      ],
    ),
    HexaThemeDef(
      id: 'frost',
      name: 'Frost Cabin',
      bgDark: Color(0xFF14202B),
      bgMid: Color(0xFF2B4257),
      surface: Color(0xFF39536B),
      tube: Color(0xFF1C2C3D),
      tubeRim: Color(0xFF5B7C96),
      accent: Color(0xFFA8CCE8),
      accentLight: Color(0xFFDDF0FD),
      accentDark: Color(0xFF6488A4),
      text: Color(0xFFEAF3FA),
      muted: Color(0xFFA9C2D6),
      tiles: [
        Color(0xFFD65F5F),
        Color(0xFFE8A15C),
        Color(0xFFF2D878),
        Color(0xFF7FBE72),
        Color(0xFF5ABDB2),
        Color(0xFF6FA8E8),
        Color(0xFF9E86DB),
        Color(0xFFEA86AC),
      ],
    ),
    HexaThemeDef(
      id: 'cocoa',
      name: 'Cocoa Nook',
      bgDark: Color(0xFF1E120A),
      bgMid: Color(0xFF3E2413),
      surface: Color(0xFF523019),
      tube: Color(0xFF2A190D),
      tubeRim: Color(0xFF7A4E28),
      accent: Color(0xFFD9A05F),
      accentLight: Color(0xFFF2CC95),
      accentDark: Color(0xFF8F6230),
      text: Color(0xFFF7EBD8),
      muted: Color(0xFFC6A380),
      tiles: [
        Color(0xFFC2514A),
        Color(0xFFDB9A55),
        Color(0xFFEACD62),
        Color(0xFF82A966),
        Color(0xFF5CA096),
        Color(0xFF6B8BC4),
        Color(0xFF9879C2),
        Color(0xFFD27494),
      ],
    ),
    HexaThemeDef(
      id: 'dune',
      name: 'Desert Dune',
      bgDark: Color(0xFF261B0D),
      bgMid: Color(0xFF4F3A1C),
      surface: Color(0xFF624A24),
      tube: Color(0xFF342512),
      tubeRim: Color(0xFF8C6A35),
      accent: Color(0xFFE4B85C),
      accentLight: Color(0xFFF8DC9A),
      accentDark: Color(0xFF9C7430),
      text: Color(0xFFF9EEDB),
      muted: Color(0xFFD0B385),
      tiles: [
        Color(0xFFCE5546),
        Color(0xFFE8A254),
        Color(0xFFF5D867),
        Color(0xFF8CB465),
        Color(0xFF5BA894),
        Color(0xFF6B93CC),
        Color(0xFFA181CC),
        Color(0xFFDE7F99),
      ],
    ),
    HexaThemeDef(
      id: 'moss',
      name: 'Moss & Stone',
      bgDark: Color(0xFF141A12),
      bgMid: Color(0xFF2C3628),
      surface: Color(0xFF3A4634),
      tube: Color(0xFF1E251C),
      tubeRim: Color(0xFF5F6E54),
      accent: Color(0xFFB3C48A),
      accentLight: Color(0xFFE2EDC4),
      accentDark: Color(0xFF6F7F4E),
      text: Color(0xFFF0F3E4),
      muted: Color(0xFFACB894),
      tiles: [
        Color(0xFFC95F52),
        Color(0xFFDE9E58),
        Color(0xFFE9D270),
        Color(0xFF8FBC5E),
        Color(0xFF5CB3A0),
        Color(0xFF6B9ED6),
        Color(0xFF9B84D1),
        Color(0xFFD9819E),
      ],
    ),
    HexaThemeDef(
      id: 'denim',
      name: 'Indigo Denim',
      bgDark: Color(0xFF141A2E),
      bgMid: Color(0xFF2A3355),
      surface: Color(0xFF38436B),
      tube: Color(0xFF1E2440),
      tubeRim: Color(0xFF5A6699),
      accent: Color(0xFF9FB2E8),
      accentLight: Color(0xFFD6DEFB),
      accentDark: Color(0xFF5F6CA4),
      text: Color(0xFFECEFFB),
      muted: Color(0xFFABB3D4),
      tiles: [
        Color(0xFFD2605F),
        Color(0xFFEBA45E),
        Color(0xFFF4DA70),
        Color(0xFF84C06E),
        Color(0xFF5DC0B4),
        Color(0xFF72ABE8),
        Color(0xFFA088DB),
        Color(0xFFEC88AE),
      ],
    ),
  ];

  static HexaThemeDef byId(String id, {HexaThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Tile styles: how each physical hex tile is rendered. The first 4 are
/// FREE; the rest are PRO.
class TileStyleDef {
  final String id;
  final String name;
  final String blurb;
  const TileStyleDef(
      {required this.id, required this.name, required this.blurb});
}

class TileStyles {
  static const List<String> freeIds = ['gloss', 'matte', 'stone', 'oak'];

  static bool isPro(String id) => !freeIds.contains(id);

  static const List<TileStyleDef> all = [
    TileStyleDef(
        id: 'gloss', name: 'Classic Gloss', blurb: 'Glossy top sheen'),
    TileStyleDef(
        id: 'matte', name: 'Honeycomb Matte', blurb: 'Soft flat finish'),
    TileStyleDef(
        id: 'stone', name: 'Polished Stone', blurb: 'Dark carved edge'),
    TileStyleDef(id: 'oak', name: 'Oak Inlay', blurb: 'Warm wooden ring'),
    TileStyleDef(
        id: 'candy', name: 'Candy Shell', blurb: 'Thick sugary rim'),
    TileStyleDef(
        id: 'brass', name: 'Brushed Brass', blurb: 'Metallic gold edge'),
    TileStyleDef(
        id: 'ceramic', name: 'Ceramic Glaze', blurb: 'Cool glazed ring'),
    TileStyleDef(id: 'gem', name: 'Gem Cut', blurb: 'Faceted sparkle lines'),
    TileStyleDef(
        id: 'paper', name: 'Paper Craft', blurb: 'Flat craft-paper tile'),
  ];

  static int indexOf(String id) {
    final i = all.indexWhere((s) => s.id == id);
    return i < 0 ? 0 : i;
  }
}

/// Board accents: the tube rack finish. First is FREE, rest PRO.
class BoardAccents {
  static const List<String> names = [
    'Walnut Rack',
    'Brass Trim',
    'Midnight Steel',
  ];
  static bool isPro(int i) => i > 0;
}
