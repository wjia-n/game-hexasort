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
    widget.store.lastThanks.addListener(_onThanks);
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
