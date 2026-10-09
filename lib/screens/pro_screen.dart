import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/hexa_themes.dart';
import '../theme/hexa_ui.dart';

/// Hexa Sort PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final HexaAudio audio;
  final HexaSettings settings;
  final HexaStore store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  HexaThemeDef get _t => HexaThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.levelComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: HexaUi.body(15, theme: _t)),
          backgroundColor: _t.bgDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.levelComplete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: HexaUi.body(15, theme: _t)),
        backgroundColor: _t.bgDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
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
              Navigator.of(context).pop();
            },
          ),
          title: Text('Hexa Sort PRO', style: HexaUi.title(22, theme: t)),
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
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
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
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final HexaThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Hexa Sort game', true, true),
      ('Easy & Medium modes', true, true),
      ('Daily challenge', true, true),
      ('Renameable player', true, true),
      ('Music & sound effects', true, true),
      ('Workshop themes', '4', '14+'),
      ('Tile styles', '4', '9'),
      ('Rack finishes', '1', '3'),
      ('Hints per level', '3', 'Unlimited'),
      ('Hard mode', false, true),
      ('Custom theme creator', false, true),
      ('Exclusive rack finishes', false, true),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.withValues(alpha: 0.95),
            theme.bgDark.withValues(alpha: 0.7),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Free vs PRO', style: HexaUi.title(20, theme: theme)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: HexaUi.muted(13, theme: theme),
          ),
          const SizedBox(height: 12),
          _tableHeader(theme),
          const SizedBox(height: 6),
          for (final (label, free, pro) in rows) _row(theme, label, free, pro),
        ],
      ),
    );
  }

  Widget _tableHeader(HexaThemeDef theme) {
    return Row(
      children: [
        const Expanded(flex: 5, child: SizedBox()),
        Expanded(
          flex: 2,
          child: Text('Free',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
        Expanded(
          flex: 2,
          child: Text('PRO',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.accentLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ),
      ],
    );
  }

  Widget _row(HexaThemeDef theme, String label, Object free, Object pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: HexaUi.body(13, theme: theme)),
          ),
          Expanded(flex: 2, child: Center(child: _cell(theme, free, false))),
          Expanded(flex: 2, child: Center(child: _cell(theme, pro, true))),
        ],
      ),
    );
  }

  Widget _cell(HexaThemeDef theme, Object v, bool proCol) {
    if (v is bool) {
      return Icon(
        v ? Icons.check_circle : Icons.remove_circle_outline,
        size: 18,
        color: v
            ? (proCol ? theme.accentLight : theme.muted)
            : theme.muted.withValues(alpha: 0.4),
      );
    }
    return Text('$v',
        style: TextStyle(
            color: proCol ? theme.accentLight : theme.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13));
  }
}

// ---------------------------------------------------------------------------
/// The actual purchase card — real store products only.
class _BuyCard extends StatelessWidget {
  final HexaThemeDef theme;
  final HexaSettings settings;
  final HexaStore store;
  final HexaAudio audio;
  const _BuyCard(
      {required this.theme,
      required this.settings,
      required this.store,
      required this.audio});

  @override
  Widget build(BuildContext context) {
    return HexaCard(
      theme: theme,
      child: ValueListenableBuilder<bool>(
        valueListenable: store.purchaseInProgress,
        builder: (_, inProgress, _) =>
            ValueListenableBuilder<String?>(
          valueListenable: store.purchaseError,
          builder: (_, err, _) => Column(
            children: [
              Text('Unlock PRO', style: HexaUi.title(18, theme: theme)),
              const SizedBox(height: 6),
              if (settings.isPro)
                Text('PRO is active on this device. Enjoy! 🎉',
                    style: HexaUi.body(14, theme: theme)),
              if (!settings.isPro && !store.storeReady)
                Text(
                  'PRO unlock is ${store.error ?? 'not ready yet'} — '
                  'it appears here automatically once the store products are set up.',
                  style: HexaUi.muted(13, theme: theme),
                  textAlign: TextAlign.center,
                ),
              if (!settings.isPro && store.storeReady)
                ..._buyButton(store),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err,
                    style: TextStyle(
                        color: theme.tiles[0], fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: inProgress
                    ? null
                    : () {
                        audio.click();
                        store.restore();
                      },
                child: Text('Restore purchases',
                    style: TextStyle(
                        color: theme.accentLight, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buyButton(HexaStore store) {
    final p = store.proProduct;
    if (p == null) return [];
    return [
      Text(p.title,
          style: TextStyle(
              color: theme.accentLight,
              fontWeight: FontWeight.w700,
              fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(p.description,
          style: HexaUi.muted(12, theme: theme),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      HexaButton(
        label: 'Unlock PRO — ${p.price}',
        icon: Icons.workspace_premium,
        theme: theme,
        onTap: () {
          audio.click();
          store.buyPro();
        },
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
/// Tip jar — consumable coffee / chocolate, real store products only.
class _TipsCard extends StatelessWidget {
  final HexaThemeDef theme;
  final HexaStore store;
  final HexaAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    return HexaCard(
      theme: theme,
      child: Column(
        children: [
          Text('☕ Tip jar', style: HexaUi.title(18, theme: theme)),
          const SizedBox(height: 4),
          Text(
            'Hexa Sort is made by one indie maker. Tips keep the hexes coming!',
            style: HexaUi.muted(12, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              'Tips are ${store.error ?? 'not ready yet'} — they appear here automatically once the store products are set up.',
              style: HexaUi.muted(13, theme: theme),
              textAlign: TextAlign.center,
            ),
          if (store.storeReady) ...[
            _tipRow(store.coffeeProduct, '☕', 'Coffee'),
            const SizedBox(height: 8),
            _tipRow(store.chocolateProduct, '🍫', 'Chocolate'),
          ],
        ],
      ),
    );
  }

  Widget _tipRow(ProductDetails? p, String emoji, String label) {
    if (p == null) return const SizedBox.shrink();
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: HexaUi.body(14, theme: theme)),
              Text(p.price, style: HexaUi.muted(12, theme: theme)),
            ],
          ),
        ),
        HexaButton(
          label: 'Send',
          theme: theme,
          small: true,
          onTap: () {
            audio.click();
            store.buyTip(p);
          },
        ),
      ],
    );
  }
}
