import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import 'iap_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  List<ProductDetails>? _products;
  String? _loadError;
  bool _buying = false;
  StreamSubscription<IapEvent>? _sub;

  @override
  void initState() {
    super.initState();
    final iap = ref.read(iapServiceProvider);
    _sub = iap.events.listen((e) {
      if (!mounted) return;
      if (e.type != IapEventType.pending) setState(() => _buying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _products = null;
      _loadError = null;
    });
    try {
      final products = await ref.read(iapServiceProvider).loadProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        if (products.isEmpty) _loadError = "The store isn't available right now. Please try again later.";
      });
    } catch (_) {
      if (mounted) setState(() => _loadError = "Couldn't reach the store. Check your connection.");
    }
  }

  Future<void> _buy(ProductDetails p) async {
    setState(() => _buying = true);
    try {
      await ref.read(iapServiceProvider).buy(p);
    } catch (_) {
      if (mounted) {
        setState(() => _buying = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start the purchase.')));
      }
    }
  }

  String _label(ProductDetails p) => p.id == AppConfig.productDayPass ? '24 hours of Premium' : '30 days of Premium';

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('ExamsAi Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.workspace_premium, size: 56, color: AppTheme.primary),
          const SizedBox(height: 8),
          Text('Unlimited exam prep', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (me?.premium.active == true && me?.premium.expiresAt != null)
            Text(
              "You're Premium until ${DateFormat.yMMMMd().format(me!.premium.expiresAt!)}. Buying again adds more time.",
              textAlign: TextAlign.center,
            )
          else
            const Text('One payment, no auto-renewal. Premium works on this app and the ExamsAi website.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          for (final f in const [
            'Unlimited AI tutor questions in every subject',
            'Unlimited practice with marking and explanations',
            'Unlimited timed CBT mock exams',
            'Progress tracking and weak-topic tips',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(f)),
              ]),
            ),
          const SizedBox(height: 16),
          if (_products == null && _loadError == null) const Center(child: CircularProgressIndicator()),
          if (_loadError != null) ...[
            Text(_loadError!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
          for (final p in _products ?? <ProductDetails>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                shape: p.id == AppConfig.productMonthly
                    ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.primary, width: 2))
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (p.id == AppConfig.productMonthly)
                          const Text('Most popular', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(_label(p), style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(p.price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    FilledButton(onPressed: _buying ? null : () => _buy(p), child: const Text('Buy')),
                  ]),
                ),
              ),
            ),
          if (_buying) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(meProvider),
            child: const Text('Already paid? Refresh my Premium status'),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment is charged to your ${Theme.of(context).platform == TargetPlatform.iOS ? 'Apple ID' : 'Google Play account'}. '
            'Premium is not renewed automatically.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.externalApplication),
            child: const Text('Privacy Policy', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
