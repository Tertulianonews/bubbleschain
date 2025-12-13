// dart
// File: lib/screens/exchange_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/balance_service.dart';

class ExchangeScreen extends StatefulWidget {
  final String userId;
  const ExchangeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final BalanceService _balanceService = BalanceService();

  Map<String, double> balances = {};
  bool loading = true;
  String error = '';

  // Valores mínimos para transações
  static const double minSwapAmount = 200.0; // Mínimo para troca: 200 BubblesCoins
  static const double minWithdrawAmount = 500.0; // Mínimo para saque: 500 unidades

  // Exchange controls
  final TextEditingController _swapAmountCtrl = TextEditingController();
  String _swapFrom = 'BUBBLE';
  String _swapTo = 'USDT';
  final List<String> _coins = ['BUBBLE', 'USDT', 'BTC', 'ETH', 'TON'];

  // Withdraw / Deposit controls
  final TextEditingController _withdrawAmountCtrl = TextEditingController();
  final TextEditingController _withdrawAddressCtrl = TextEditingController();
  String _withdrawCoin = 'USDT';

  @override
  void initState() {
    super.initState();
    _loadAllBalances();
    _initializeUserBalances();
  }

  Future<void> _initializeUserBalances() async {
    await _balanceService.initializeUserBalances(widget.userId);
  }

  Future<void> _loadAllBalances() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final allBalances = await _balanceService.getAllBalances(widget.userId);

      setState(() {
        balances = allBalances;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        error = 'Erro ao carregar saldos: $e';
        loading = false;
      });
    }
  }

  Future<void> _performSwap() async {
    final amount = double.tryParse(_swapAmountCtrl.text.replaceAll(',', '.')) ?? 0.0;

    // Validação de valor mínimo
    if (amount <= 0) {
      _showMessage('Informe um valor válido');
      return;
    }

    if (amount < minSwapAmount) {
      _showMessage(
          '❌ Valor abaixo do mínimo!\n\n'
              'Valor mínimo para troca: $minSwapAmount $_swapFrom\n'
              'Valor informado: ${amount.toStringAsFixed(2)} $_swapFrom\n\n'
              '💡 Informe um valor maior ou igual a $minSwapAmount'
      );
      return;
    }

    if (_swapFrom == _swapTo) {
      _showMessage('Selecione moedas diferentes');
      return;
    }

    final fromBalance = balances[_swapFrom] ?? 0.0;
    if (fromBalance < amount) {
      // Mensagem de erro mais informativa com saldo disponível
      _showMessage(
          '❌ Saldo insuficiente!\n\n'
              'Disponível: ${fromBalance.toStringAsFixed(8)} $_swapFrom\n'
              'Solicitado: ${amount.toStringAsFixed(8)} $_swapFrom\n'
              'Faltam: ${(amount - fromBalance).toStringAsFixed(8)} $_swapFrom'
      );
      return;
    }

    setState(() => loading = true);

    try {
      final newBalances = await _balanceService.syncWithExchange(
        widget.userId,
        _swapFrom,
        amount,
        _swapTo,
      );

      setState(() {
        balances = newBalances;
        _swapAmountCtrl.clear();
      });

      _showMessage('✅ Troca realizada com sucesso!');
    } catch (e) {
      _showMessage('❌ Erro na troca: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _generateDepositAddress(String coin) async {
    if (coin == 'BUBBLE') {
      _showMessage('Para depositar Bubble Coins, jogue nos games disponíveis!');
      return;
    }

    final address = 'DEP-${coin.substring(0,3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    await Clipboard.setData(ClipboardData(text: address));
    _showMessage('Endereço copiado: $address');
  }

  Future<void> _requestWithdraw() async {
    final amount = double.tryParse(_withdrawAmountCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final addr = _withdrawAddressCtrl.text.trim();

    // Validação de endereço
    if (addr.isEmpty) {
      _showMessage('❌ Informe um endereço válido');
      return;
    }

    // Validação de valor
    if (amount <= 0) {
      _showMessage('❌ Informe um valor válido');
      return;
    }

    // Validação de valor mínimo para saque
    if (amount < minWithdrawAmount) {
      _showMessage(
          '❌ Valor abaixo do mínimo para saque!\n\n'
              'Valor mínimo para saque: $minWithdrawAmount $_withdrawCoin\n'
              'Valor informado: ${amount.toStringAsFixed(2)} $_withdrawCoin\n\n'
              '💡 Informe um valor maior ou igual a $minWithdrawAmount'
      );
      return;
    }

    if (_withdrawCoin == 'BUBBLE') {
      _showMessage(
          '❌ Para sacar Bubble Coins, converta para outra moeda primeiro');
      return;
    }

    final available = balances[_withdrawCoin] ?? 0.0;
    if (available < amount) {
      _showMessage(
          '❌ Saldo insuficiente para saque!\n\n'
              'Disponível: ${available.toStringAsFixed(8)} $_withdrawCoin\n'
              'Solicitado: ${amount.toStringAsFixed(8)} $_withdrawCoin\n'
              'Faltam: ${(amount - available).toStringAsFixed(
              8)} $_withdrawCoin'
      );
      return;
    }

    setState(() => loading = true);

    try {
      await _client.from('transactions').insert({
        'user_id': widget.userId,
        'type': 'withdraw',
        'coin': _withdrawCoin,
        'amount': amount,
        'address': addr,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        balances[_withdrawCoin] = available - amount;
      });

      await _balanceService.updateExchangeBalance(
          widget.userId, _withdrawCoin, available - amount);

      _withdrawAmountCtrl.clear();
      _withdrawAddressCtrl.clear();

      _showMessage('✅ Retirada solicitada com sucesso! Verifique o histórico.');
    } catch (e) {
      _showMessage('❌ Erro ao solicitar retirada: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;

    // Determinar se é mensagem de sucesso ou erro
    final isSuccess = msg.contains('✅') || msg.contains('sucesso');
    final isError = msg.contains('❌');

    // Duração baseada no tipo de mensagem
    Duration duration;
    if (msg.contains('Valor abaixo do mínimo') ||
        msg.contains('Saldo insuficiente')) {
      duration =
      const Duration(seconds: 6); // Mensagens detalhadas precisam de mais tempo
    } else if (isError) {
      duration = const Duration(seconds: 4);
    } else {
      duration = const Duration(seconds: 3);
    }

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        )
    );
  }

  @override
  void dispose() {
    _swapAmountCtrl.dispose();
    _withdrawAmountCtrl.dispose();
    _withdrawAddressCtrl.dispose();
    super.dispose();
  }

  Widget _buildBalanceRow(String coin) {
    final bal = balances[coin] ?? 0.0;
    final isBubble = coin == 'BUBBLE';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isBubble ? Colors.blueAccent : Colors.deepPurple,
        child: Text(
            coin.substring(0, 1),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)
        ),
      ),
      title: Text(
          coin,
          style: GoogleFonts.orbitron(
              color: isBubble ? Colors.blueAccent : Colors.white,
              fontWeight: isBubble ? FontWeight.bold : FontWeight.normal
          )
      ),
      subtitle: isBubble ? const Text(
          'Ganhe jogando!', style: TextStyle(color: Colors.white54)) : null,
      trailing: Text(
          bal.toStringAsFixed(8),
          style: TextStyle(
              color: isBubble ? Colors.blueAccent : Colors.white70,
              fontWeight: FontWeight.bold
          )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '💰',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'Exchange',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
              onPressed: _loadAllBalances,
              icon: const Icon(Icons.refresh)
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Material(
              color: Colors.grey[900],
              child: const TabBar(
                tabs: [
                  Tab(text: 'Saldos'),
                  Tab(text: 'Converter'),
                  Tab(text: 'Transações'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Todos os Saldos',
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      ..._coins.map(_buildBalanceRow).toList(),
                      const SizedBox(height: 20),
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Troca Rápida',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          const Text(
                                            'De',
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                          DropdownButton<String>(
                                            value: _swapFrom,
                                            isExpanded: true,
                                            dropdownColor: Colors.grey[900],
                                            items: _coins
                                                .map((c) =>
                                                DropdownMenuItem(
                                                  value: c,
                                                  child: Text(c,
                                                      style: const TextStyle(
                                                          color: Colors.white)),
                                                ))
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) setState(() =>
                                              _swapFrom = v);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    const Icon(Icons.arrow_forward,
                                        color: Colors.white70),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          const Text(
                                            'Para',
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                          DropdownButton<String>(
                                            value: _swapTo,
                                            isExpanded: true,
                                            dropdownColor: Colors.grey[900],
                                            items: _coins
                                                .where((c) => c != _swapFrom)
                                                .map((c) =>
                                                DropdownMenuItem(
                                                  value: c,
                                                  child: Text(c,
                                                      style: const TextStyle(
                                                          color: Colors.white)),
                                                ))
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) setState(() =>
                                              _swapTo = v);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _swapAmountCtrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Valor',
                                          labelStyle: const TextStyle(
                                              color: Colors.white70),
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                8),
                                          ),
                                        ),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        final maxBalance = balances[_swapFrom] ??
                                            0.0;
                                        setState(() {
                                          _swapAmountCtrl.text =
                                              maxBalance.toStringAsFixed(8);
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                        ),
                                      ),
                                      child: Text(
                                        'MAX',
                                        style: GoogleFonts.orbitron(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _performSwap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    minimumSize: const Size(
                                        double.infinity, 50),
                                  ),
                                  child: loading
                                      ? const CircularProgressIndicator(
                                      color: Colors.white)
                                      : const Text('Solicitar Troca'),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Saldo disponível em $_swapFrom: ${balances[_swapFrom]
                                      ?.toStringAsFixed(8) ??
                                      '0.00000000'}\nMínimo para troca: $minSwapAmount',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  FutureBuilder(
                    future: _client
                        .from('transactions')
                        .select()
                        .eq('user_id', widget.userId)
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(
                          child: Text(
                            'Erro ao carregar transações',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      final transactions = snapshot.data as List;

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma transação encontrada',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return Card(
                            color: Colors.grey[900],
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tx['status'] == 'completed'
                                    ? Colors.green
                                    : tx['status'] == 'pending'
                                    ? Colors.orange
                                    : Colors.red,
                                child: Icon(
                                  tx['type'] == 'swap'
                                      ? Icons.swap_horiz
                                      : Icons.attach_money,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${tx['type']} - ${tx['from_coin'] ??
                                    tx['coin']} → ${tx['to_coin'] ?? ''}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${tx['amount']} • ${tx['status']}',
                                style: TextStyle(
                                  color: tx['status'] == 'completed'
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                ),
                              ),
                              trailing: Text(
                                '${DateTime
                                    .parse(tx['created_at'])
                                    .toString()
                                    .split(' ')[0]}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
