// File: lib/screens/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Unified transaction history screen showing all user transactions
class TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  const TransactionHistoryScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: Future.wait([
          Supabase.instance.client
              .from('exchange_transactions')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false),
          Supabase.instance.client
              .from('transactions')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final exchangeTxs = snapshot.data![0] as List;
          final otherTxs = snapshot.data![1] as List;

          // Combine all transactions
          final allTransactions = [
            ...exchangeTxs.map((tx) => _TransactionItem.fromExchange(tx)),
            ...otherTxs.map((tx) => _TransactionItem.fromOther(tx)),
          ];

          // Sort by date (most recent first)
          allTransactions.sort((a, b) => b.date.compareTo(a.date));

          if (allTransactions.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma transação encontrada',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: allTransactions.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final tx = allTransactions[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: _getTransactionIcon(tx.type),
                  title: Text(
                    tx.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        tx.amountInfo,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(tx.date),
                        style: const TextStyle(fontSize: 12,
                            color: Colors.white54),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tx.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tx.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Get icon based on transaction type
  Icon _getTransactionIcon(String type) {
    switch (type) {
      case 'swap':
      case 'conversion':
        return const Icon(Icons.swap_horiz, color: Colors.blue);
      case 'withdraw':
        return const Icon(Icons.arrow_upward, color: Colors.red);
      case 'deposit':
        return const Icon(Icons.arrow_downward, color: Colors.green);
      case 'game_earn':
        return const Icon(Icons.videogame_asset, color: Colors.purple);
      default:
        return const Icon(Icons.receipt, color: Colors.grey);
    }
  }

  /// Get color based on transaction status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Internal class to represent a unified transaction item
class _TransactionItem {
  final String type;
  final String description;
  final String amountInfo;
  final DateTime date;
  final String status;

  _TransactionItem({
    required this.type,
    required this.description,
    required this.amountInfo,
    required this.date,
    required this.status,
  });

  /// Create from exchange transaction
  factory _TransactionItem.fromExchange(Map<String, dynamic> tx) {
    return _TransactionItem(
      type: tx['type'],
      description: '${tx['type']}: ${tx['from_coin']} → ${tx['to_coin']}',
      amountInfo: '${tx['amount']} ${tx['from_coin']} → ${tx['converted_amount']} ${tx['to_coin']}',
      date: DateTime.parse(tx['created_at']),
      status: tx['status'],
    );
  }

  /// Create from other transaction types
  factory _TransactionItem.fromOther(Map<String, dynamic> tx) {
    return _TransactionItem(
      type: tx['type'],
      description: '${tx['type']}: ${tx['coin'] ?? ''}',
      amountInfo: '${tx['amount']} ${tx['coin'] ?? ''}',
      date: DateTime.parse(tx['created_at']),
      status: tx['status'],
    );
  }
}
