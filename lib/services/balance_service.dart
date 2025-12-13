// lib/services/balance_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for managing user balances across the app
class BalanceService {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bubbleCoinKey = 'bubble_coin_balance';

  // Local cache for better performance
  double? _cachedBubbleCoinBalance;
  DateTime? _lastCacheUpdate;
  final Duration _cacheDuration = Duration(minutes: 1);

  /// Update Bubble Coin balance for a user
  Future<void> updateBubbleCoinBalance(String userId, double amount) async {
    try {
      // Get current balance from Supabase
      final currentBalance = await getBubbleCoinBalance(userId);
      final newBalance = currentBalance + amount;

      // Check if user already has a record in userBalances
      final existingRecord = await _supabase
          .from('userBalances')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        await _supabase.from('userBalances').update({
          'bubblecoin_balance': newBalance,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } else {
        // Create new record
        await _supabase.from('userBalances').insert({
          'user_id': userId,
          'bubblecoin_balance': newBalance,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Update local cache
      _cachedBubbleCoinBalance = newBalance;
      _lastCacheUpdate = DateTime.now();

      // Save locally for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_bubbleCoinKey}_$userId', newBalance);
    } catch (e) {
      print('Erro ao atualizar saldo: $e');
      rethrow;
    }
  }

  /// Get Bubble Coin balance (with caching)
  Future<double> getBubbleCoinBalance(String userId) async {
    try {
      // Check cache first
      if (_cachedBubbleCoinBalance != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        return _cachedBubbleCoinBalance!;
      }

      // Try to get from Supabase userBalances table
      final response = await _supabase
          .from('userBalances')
          .select('bubblecoin_balance')
          .eq('user_id', userId)
          .maybeSingle();

      double balance = 0.0;

      if (response != null && response['bubblecoin_balance'] != null) {
        balance = (response['bubblecoin_balance'] as num).toDouble();
      } else {
        // Check localStorage
        final prefs = await SharedPreferences.getInstance();
        balance = prefs.getDouble('${_bubbleCoinKey}_$userId') ?? 0.0;

        // If exists in localStorage but not in Supabase, sync
        if (balance > 0) {
          await _supabase.from('userBalances').insert({
            'user_id': userId,
            'bubblecoin_balance': balance,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // Update cache
      _cachedBubbleCoinBalance = balance;
      _lastCacheUpdate = DateTime.now();

      return balance;
    } catch (e) {
      print('Erro ao obter saldo: $e');

      // Fallback to localStorage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('${_bubbleCoinKey}_$userId') ?? 0.0;
    }
  }

  /// Synchronize balances with exchange (convert Bubble Coins to cryptocurrencies)
  Future<Map<String, double>> syncWithExchange(String userId,
      String fromCoin,
      double amount,
      String toCoin) async {
    try {
      // Conversion rates (example, you can fetch from a real API)
      final Map<String, double> conversionRates = {
        'BUBBLE': 0.000001, // 1 BUBBLE = 0.000001 BTC
        'USDT': 1.0,
        'BTC': 0.000001,
        'ETH': 0.00002,
        'TON': 0.01,
      };

      // Get current Bubble Coin balance
      final bubbleBalance = await getBubbleCoinBalance(userId);

      if (fromCoin == 'BUBBLE' && bubbleBalance < amount) {
        throw Exception('Saldo insuficiente de Bubble Coins');
      }

      // Calculate conversion
      double convertedAmount;
      if (fromCoin == 'BUBBLE') {
        convertedAmount = amount * (conversionRates[toCoin] ?? 1.0);
      } else {
        // If converting from another currency to Bubble Coin
        final rateToBubble = 1 / (conversionRates[fromCoin] ?? 1.0);
        convertedAmount = amount * rateToBubble;
      }

      // Register transaction
      await _supabase.from('exchange_transactions').insert({
        'user_id': userId,
        'type': 'conversion',
        'from_coin': fromCoin,
        'to_coin': toCoin,
        'amount': amount,
        'converted_amount': convertedAmount,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update balances
      if (fromCoin == 'BUBBLE') {
        // Debit Bubble Coins
        await updateBubbleCoinBalance(userId, -amount);

        // Credit in exchange (wallets table)
        final currentExchangeBalance = await _getExchangeBalance(userId, toCoin);
        await _updateExchangeBalance(userId, toCoin, currentExchangeBalance + convertedAmount);
      } else {
        // Debit from exchange
        final currentExchangeBalance = await _getExchangeBalance(userId, fromCoin);
        if (currentExchangeBalance < amount) {
          throw Exception('Saldo insuficiente na exchange');
        }
        await _updateExchangeBalance(userId, fromCoin, currentExchangeBalance - amount);

        // Credit Bubble Coins
        await updateBubbleCoinBalance(userId, convertedAmount);
      }

      // Return new balances
      final newBubbleBalance = await getBubbleCoinBalance(userId);
      final newExchangeBalances = await _getAllExchangeBalances(userId);

      return {
        'BUBBLE': newBubbleBalance,
        ...newExchangeBalances,
      };
    } catch (e) {
      print('Erro na sincronização: $e');
      rethrow;
    }
  }

  /// Get exchange balance for a specific coin
  Future<double> _getExchangeBalance(String userId, String coin) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .eq('coin', coin)
          .maybeSingle();

      if (response != null) {
        return (response['balance'] as num).toDouble();
      }

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get all exchange balances for a user
  Future<Map<String, double>> _getAllExchangeBalances(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select('coin, balance')
          .eq('user_id', userId);

      final Map<String, double> balances = {};
      for (final row in response) {
        balances[row['coin'] as String] = (row['balance'] as num).toDouble();
      }

      return balances;
    } catch (e) {
      return {};
    }
  }

  /// Update exchange balance for a specific coin
  Future<void> _updateExchangeBalance(String userId, String coin, double amount) async {
    try {
      // Check if record already exists
      final exists = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .eq('coin', coin)
          .maybeSingle();

      if (exists != null) {
        // Update
        await _supabase
            .from('wallets')
            .update({'balance': amount})
            .eq('user_id', userId)
            .eq('coin', coin);
      } else {
        // Create new
        await _supabase
            .from('wallets')
            .insert({
          'user_id': userId,
          'coin': coin,
          'balance': amount,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Erro ao atualizar saldo da exchange: $e');
      rethrow;
    }
  }

  /// Public method to update exchange balance (for external use)
  Future<void> updateExchangeBalance(String userId, String coin,
      double amount) async {
    await _updateExchangeBalance(userId, coin, amount);
  }

  /// Initialize user balances
  Future<void> initializeUserBalances(String userId) async {
    try {
      // Check if user already has Bubble Coin balance
      final currentBalance = await getBubbleCoinBalance(userId);
      if (currentBalance == 0) {
        // Initialize with zero balance
        await _supabase.from('userBalances').insert({
          'user_id': userId,
          'bubblecoin_balance': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        });

        _cachedBubbleCoinBalance = 0.0;
        _lastCacheUpdate = DateTime.now();
      }

      // Initialize exchange balances
      final coins = ['USDT', 'BTC', 'ETH', 'TON'];
      for (final coin in coins) {
        final existingBalance = await _getExchangeBalance(userId, coin);
        if (existingBalance == 0) {
          await _updateExchangeBalance(userId, coin, 0.0);
        }
      }
    } catch (e) {
      print('Erro ao inicializar saldos: $e');
    }
  }

  /// Give welcome bonus to new users or users with zero balance
  /// Returns true if bonus was given, false if user already had balance
  Future<bool> giveWelcomeBonus(String userId,
      {double bonusAmount = 1.0}) async {
    try {
      // Check if user already received welcome bonus
      final prefs = await SharedPreferences.getInstance();
      final bonusKey = 'welcome_bonus_given_$userId';
      final alreadyGiven = prefs.getBool(bonusKey) ?? false;

      if (alreadyGiven) {
        print('Bônus de boas-vindas já foi dado para este usuário');
        return false;
      }

      // Check current balance from userBalances table
      final currentBalance = await getBubbleCoinBalance(userId);

      // Only give bonus if balance is exactly zero (new users)
      // Don't give to existing users who already have balance
      if (currentBalance == 0.0) {
        await updateBubbleCoinBalance(userId, bonusAmount);

        // Mark bonus as given
        await prefs.setBool(bonusKey, true);

        // Register bonus transaction
        try {
          await _supabase.from('exchange_transactions').insert({
            'user_id': userId,
            'type': 'welcome_bonus',
            'from_coin': 'SYSTEM',
            'to_coin': 'BUBBLE',
            'amount': bonusAmount,
            'converted_amount': bonusAmount,
            'status': 'completed',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('Aviso: Não foi possível registrar transação de bônus: $e');
        }

        print(
            'Bônus de boas-vindas de $bonusAmount BUBBLE dado ao usuário $userId');
        return true;
      } else {
        print('Usuário já possui saldo de $currentBalance BUBBLE - sem bônus');
        return false;
      }

      return false;
    } catch (e) {
      print('Erro ao dar bônus de boas-vindas: $e');
      return false;
    }
  }

  /// Check and give welcome bonus if needed (call this on app startup)
  Future<void> checkAndGiveWelcomeBonus(String userId) async {
    try {
      final bonusGiven = await giveWelcomeBonus(userId, bonusAmount: 1.0);
      if (bonusGiven) {
        print('✅ Bônus de boas-vindas aplicado!');
      }
    } catch (e) {
      print('Erro ao verificar bônus de boas-vindas: $e');
    }
  }

  /// Get all balances for a user (Bubble Coins + Exchange)
  Future<Map<String, double>> getAllBalances(String userId) async {
    final bubbleBalance = await getBubbleCoinBalance(userId);
    final exchangeBalances = await _getAllExchangeBalances(userId);

    return {
      'BUBBLE': bubbleBalance,
      ...exchangeBalances,
    };
  }

  /// Clear cache
  void clearCache() {
    _cachedBubbleCoinBalance = null;
    _lastCacheUpdate = null;
  }
}