import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config.dart';
import '../../data/api.dart';
import '../../data/providers.dart';

enum IapEventType { success, error, pending }

class IapEvent {
  final IapEventType type;
  final String message;
  const IapEvent(this.type, this.message);
}

final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Wraps Play Billing / StoreKit. Every completed purchase is sent to the
/// server (verify-purchase), which checks it with the store and grants
/// Premium to the signed-in account. The purchase is only finished with the
/// store after the server accepts it, so nothing is lost if the network drops.
class IapService {
  IapService(this._ref);
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _events = StreamController<IapEvent>.broadcast();
  bool _initialised = false;

  Stream<IapEvent> get events => _events.stream;

  void init() {
    if (_initialised) return;
    _initialised = true;
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      debugPrint('Purchase stream error: $e');
    });
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (!await _iap.isAvailable()) return const [];
    final res = await _iap.queryProductDetails(AppConfig.productIds);
    final list = [...res.productDetails];
    // Day pass first, then monthly.
    list.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    return list;
  }

  Future<void> buy(ProductDetails product) async {
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    final param = PurchaseParam(productDetails: product, applicationUserName: userId);
    // Both products are bought again each time (time-limited access).
    await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _events.add(const IapEvent(IapEventType.pending, 'Waiting for the store to confirm your payment...'));
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        case PurchaseStatus.error:
          _events.add(IapEvent(IapEventType.error, p.error?.message ?? 'The purchase did not go through.'));
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(p);
      }
    }
  }

  Future<void> _deliver(PurchaseDetails p) async {
    final api = _ref.read(apiProvider);
    if (_ref.read(supabaseProvider).auth.currentSession == null) return; // retried after sign-in
    try {
      if (Platform.isAndroid) {
        await api.verifyPurchase(
          platform: 'android',
          productId: p.productID,
          purchaseToken: p.verificationData.serverVerificationData,
        );
      } else {
        await api.verifyPurchase(platform: 'ios', productId: p.productID, transactionId: p.purchaseID);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      _ref.invalidate(meProvider);
      _events.add(const IapEvent(IapEventType.success, "You're Premium! Enjoy unlimited practice."));
    } on ApiException catch (e) {
      if (e.code == 'purchase_other_account' && p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
      _events.add(IapEvent(IapEventType.error, e.message));
    } catch (e) {
      _events.add(const IapEvent(IapEventType.error, "We couldn't confirm your purchase yet. We'll try again next time you open the app."));
    }
  }

  void dispose() {
    _sub?.cancel();
    _events.close();
  }
}
