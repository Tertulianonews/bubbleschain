import 'package:supabase_flutter/supabase_flutter.dart';
import 'balance_service.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  /// Pega o saldo atual do usuário no campo bubblecoin_balance
  Future<double> getBubbleCoinBalance(String userId) async {
    return await BalanceService().getBubbleCoinBalance(userId);
  }

  /// Garanta o registro inicial de saldo zero, se não existir
  Future<void> ensureUserBalanceExists(String userId) async {
    await BalanceService().initializeUserBalances(userId);
  }

  /// Soma um valor ao saldo do usuário (persistente/online)
  Future<void> addBubbleCoin(String userId, double amount) async {
    await BalanceService().updateBubbleCoinBalance(userId, amount);
  }

  /// Convert BubbleCoin to other cryptocurrencies
  Future<void> convertBubbleCoin(String userId, double amount,
      String toCoin) async {
    await BalanceService().syncWithExchange(userId, 'BUBBLE', amount, toCoin);
  }

  String getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? '';
  }
}