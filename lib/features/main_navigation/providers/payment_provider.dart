import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class PaymentState {
  final bool isReady;
  final bool isLoading;
  final List<StoreProduct> products;
  final CustomerInfo? customerInfo;
  final String? error;

  PaymentState({
    this.isReady = false,
    this.isLoading = false,
    this.products = const [],
    this.customerInfo,
    this.error,
  });

  PaymentState copyWith({
    bool? isReady,
    bool? isLoading,
    List<StoreProduct>? products,
    CustomerInfo? customerInfo,
    String? error,
  }) {
    return PaymentState(
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      customerInfo: customerInfo ?? this.customerInfo,
      error: error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState()) {
    _initRevenueCat();
  }

  Future<void> _initRevenueCat() async {
    try {
      final isDesktopOrWeb =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux;

      if (isDesktopOrWeb) {
        // En plataformas de escritorio y web, usamos Stripe (gestionado en la UI).
        // Marcamos isReady en true para que la UI no se bloquee ni muestre errores.
        state = state.copyWith(isReady: true);
        return;
      }

      await Purchases.setLogLevel(LogLevel.debug);

      String? apiKey;
      if (Platform.isAndroid) {
        apiKey = dotenv.env['REVENUECAT_ANDROID_KEY'];
      } else if (Platform.isIOS) {
        apiKey = dotenv.env['REVENUECAT_IOS_KEY'];
      }

      if (apiKey == null || apiKey.isEmpty || apiKey == 'tu_clave_aqui') {
        state = state.copyWith(
          error: 'Faltan las claves de RevenueCat en .env',
        );
        return;
      }

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      final customerInfo = await Purchases.getCustomerInfo();
      final offerings = await Purchases.getOfferings();

      final products =
          offerings.current?.availablePackages
              .map((p) => p.storeProduct)
              .toList() ??
          [];

      state = state.copyWith(
        isReady: true,
        customerInfo: customerInfo,
        products: products,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> purchaseSpecificProduct(StoreProduct product) async {
    try {
      state = state.copyWith(isLoading: true);
      await Purchases.purchaseStoreProduct(product);
      final customerInfo = await Purchases.getCustomerInfo();
      state = state.copyWith(isLoading: false, customerInfo: customerInfo);
      return true; // Si no hay excepción, la pasarela completó con éxito
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> purchaseTicket() async {
    if (state.products.isEmpty) return false;

    try {
      state = state.copyWith(isLoading: true);

      // Asumimos que el primer producto es la "Entrada Digital"
      final product = state.products.first;
      final customerInfo = await Purchases.purchaseStoreProduct(product);

      state = state.copyWith(isLoading: false, customerInfo: customerInfo);

      // Verificamos si la compra otorgó el Entitlement
      if (customerInfo.entitlements.all['ticket_acceso']?.isActive == true) {
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  return PaymentNotifier();
});
