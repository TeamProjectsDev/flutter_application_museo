import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentState {
  final bool isReady;
  final bool isLoading;
  final String? error;

  PaymentState({
    this.isReady = true,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    bool? isReady,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState());

  // Ahora todo el flujo de pago se gestiona vía StripeService en la UI
  // Este notifier solo mantiene el estado global de carga si fuera necesario.
  
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(error: error);
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});
