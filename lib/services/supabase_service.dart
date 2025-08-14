import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  /// Pega o saldo atual do usuário no campo bubblecoin_balance
  Future<double> getBubbleCoinBalance(String userId) async {
    final res = await _client
        .from('userBalances')
        .select('bubblecoin_balance')
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null || res['bubblecoin_balance'] == null) {
      return 0.0;
    }
    return double.tryParse(res['bubblecoin_balance'].toString()) ?? 0.0;
  }

  /// Garanta o registro inicial de saldo zero, se não existir
  Future<void> ensureUserBalanceExists(String userId) async {
    final exists = await _client
        .from('userBalances')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    if (exists == null) {
      await _client.from('userBalances').insert({
        'user_id': userId,
        'bubblecoin_balance': '0',
        'updated_at': DateTime.now().toIso8601String()
      });
    }
  }

  /// Soma um valor ao saldo do usuário (persistente/online)
  Future<void> addBubbleCoin(String userId, double amount) async {
    await ensureUserBalanceExists(userId);
    await _client.rpc('increment_bubblecoin', params: {
      'uid': userId,
      'value': amount,
    });
  }

  Future<void> convertBubbleCoin(String userId) async {
    // TODO: lógica de conversão/sacar moedas
  }

  String getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? '';
  }
}