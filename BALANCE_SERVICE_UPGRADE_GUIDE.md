# Balance Service Upgrade Guide

Este guia explica como atualizar o projeto BubblesChain para usar o novo sistema centralizado de
gerenciamento de saldos.

## 📋 Visão Geral

As melhorias implementam:

1. ✅ Serviço centralizado de saldos (`BalanceService`)
2. ✅ Cache local para melhor performance
3. ✅ Suporte offline com `shared_preferences`
4. ✅ Sistema de conversão Bubble Coin ↔ Criptomoedas
5. ✅ Exchange screen atualizada
6. ✅ Tela de histórico de transações unificado

## 🗂️ Arquivos Criados/Atualizados

### Novos Arquivos

- `lib/services/balance_service.dart` - Serviço centralizado ✅
- `lib/screens/transaction_history_screen.dart` - Histórico unificado ✅
- `supabase_schema.sql` - Schema do banco de dados ✅
- `BALANCE_SERVICE_UPGRADE_GUIDE.md` - Este guia ✅

### Arquivos Atualizados

- `lib/screens/exchange_screen.dart` - Integração com BalanceService ✅

### Arquivos Para Atualizar Manualmente

- `lib/screens/terlinet_word_screen.dart` - Aplicar mudanças abaixo
- `lib/screens/bubble_game_screen.dart` - Aplicar mudanças abaixo
- `lib/services/supabase_service.dart` - Aplicar mudanças abaixo

## 🔧 Passo 1: Aplicar Schema do Supabase

Execute o arquivo `supabase_schema.sql` no seu projeto Supabase:

1. Acesse o Supabase Dashboard
2. Vá em SQL Editor
3. Cole o conteúdo de `supabase_schema.sql`
4. Execute o script

Isso criará:

- Coluna `bubble_coin_balance` na tabela `users`
- Tabela `exchange_transactions` para conversões
- Tabela `wallets` para saldos da exchange
- Políticas RLS apropriadas

## 🎮 Passo 2: Atualizar Terlinet Word Screen

No arquivo `lib/screens/terlinet_word_screen.dart`:

### 2.1 Adicionar Import

```dart
import '../services/balance_service.dart';
```

### 2.2 Atualizar State Class

Substitua as variáveis de saldo existentes:

```dart
// ANTES:
double balance = 0.0;

// DEPOIS:
final BalanceService _balanceService = BalanceService();
double _bubbleCoinBalance = 0.0;
```

### 2.3 Atualizar _loadUserBalance

```dart
void _loadUserBalance() {
  userId = SupabaseService().getCurrentUserId();
  if (userId.isNotEmpty) {
    _balanceService.getBubbleCoinBalance(userId).then((b) {
      if (mounted) setState(() {
        _bubbleCoinBalance = b;
        lastSolTriggerBalance = b;
      });
    });
  }
}
```

### 2.4 Atualizar _collectCoin

```dart
void _collectCoin(int index) async {
  collectedCoins.add(index);
  coinsCollected++;
  score += 100;

  // Tocar som
  _coinPlayer.stop();
  _coinPlayer.play(AssetSource('assets/coletando.mp3'), volume: 0.7);

  // Adicionar partículas
  _particleSystem.addCoinBurst(coins[index].dx, coins[index].dy);

  // Atualizar saldo usando o serviço
  await _updateBalance();
}
```

### 2.5 Atualizar _updateBalance

```dart
Future<void> _updateBalance() async {
  double added = 0.00000001;
  
  try {
    await _balanceService.updateBubbleCoinBalance(userId, added);
    // Atualizar localmente após sucesso
    setState(() {
      _bubbleCoinBalance += added;
    });
    
    // Verificar bonus
    _checkBonus();
  } catch (e) {
    print('Erro ao atualizar saldo: $e');
  }
}
```

### 2.6 Atualizar _checkBonus

Use `_bubbleCoinBalance` em vez de `balance`:

```dart
void _checkBonus() {
  normalCollectCount++;

  // Bonus de emoji a cada 5 moedas
  if (normalCollectCount % 5 == 0) {
    final emojis = ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '😊', '😇'];
    lastEmojiAwarded = emojis[Random().nextInt(emojis.length)];
    showEmojiBadge = true;
    emojiBadgeOpacity = 1.0;

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => showEmojiBadge = false);
    });
  }

  // Bonus de Solana
  if (_bubbleCoinBalance - lastSolTriggerBalance >= SOL_TRIGGER_THRESHOLD) {
    showSolBadge = true;
    solBadgeOpacity = 1.0;
    lastSolTriggerBalance = _bubbleCoinBalance;

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => showSolBadge = false);
    });
  }
}
```

### 2.7 Atualizar UI do Saldo

No método `build`, atualize o display do saldo:

```dart
Row(
  children: [
    Image.asset('assets/icon_bolhas.png', width: 24, height: 24),
    const SizedBox(width: 8),
    Text(
      _bubbleCoinBalance.toStringAsFixed(8), // Usar a nova variável
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
```

## 🫧 Passo 3: Atualizar Bubble Game Screen

No arquivo `lib/screens/bubble_game_screen.dart`:

### 3.1 Adicionar Import

```dart
import '../services/balance_service.dart';
```

### 3.2 Atualizar State Class

```dart
// ANTES:
double balance = 0.0;

// DEPOIS:
final BalanceService _balanceService = BalanceService();
double _bubbleCoinBalance = 0.0;
```

### 3.3 Atualizar _loadUserIdAndBalance

```dart
void _loadUserIdAndBalance() async {
  final currentUser = SupabaseService().getCurrentUserId();
  if (currentUser.isNotEmpty) {
    final bal = await _balanceService.getBubbleCoinBalance(currentUser);
    setState(() {
      userId = currentUser;
      _bubbleCoinBalance = bal;
      loading = false;
    });
  }
}
```

### 3.4 Atualizar _onBubblePop

```dart
void _onBubblePop(int id, {TapDownDetails? tapDetails}) async {
  final bubble = bubbles.firstWhere((b) => b.id == id,
      orElse: () => _GameBubble.fallback());
  setState(() {
    bubbles.removeWhere((b) => b.id == id);
  });
  
  if (bubble.emoji != null) {
    // Emoji Bubble bonus!
    final picked = random.nextBool() ? 'grito.mp3' : 'grito2.mp3';
    await _emojiPlayer.play(AssetSource(picked), volume: 0.85);
    
    try {
      await _balanceService.updateBubbleCoinBalance(userId, 0.000000025);
      setState(() {
        _bubbleCoinBalance += 0.000000025;
        showEmojiBadge = true;
        emojiBadgeOpacity = 1.0;
      });
    } catch (e) {
      print('Erro ao adicionar saldo: $e');
    }
    
    // ... resto do código de badge ...
  } else {
    playPopSound();
    setState(() {
      poppedCount += 1;
      normalPopCount += 1;
    });
    
    // ... lógica de combo ...
    
    double added = 0.00000001 + comboBonus;
    
    try {
      await _balanceService.updateBubbleCoinBalance(userId, added);
      setState(() {
        _bubbleCoinBalance += added;
      });
    } catch (e) {
      print('Erro ao adicionar saldo: $e');
    }
    
    // Solana check usando _bubbleCoinBalance
    if ((_bubbleCoinBalance / solTriggerThreshold).floor() >
        (lastSolTriggerBalance / solTriggerThreshold).floor()) {
      if (!hasPendingSolana) {
        _addSolanaBubble();
        hasPendingSolana = true;
      }
      lastSolTriggerBalance = _bubbleCoinBalance;
    }
  }
  
  // Repor bolha
  Future.delayed(const Duration(milliseconds: 550), () {
    if (mounted && bubbles.length < 8) {
      _addBubble();
    }
  });
}
```

### 3.5 Atualizar _onSolanaPop

```dart
void _onSolanaPop(int id) async {
  // ... código de animação existente ...
  
  try {
    await _balanceService.updateBubbleCoinBalance(userId, 0.000000100);
    setState(() {
      _bubbleCoinBalance += 0.000000100;
      showSolBadge = true;
      solBadgeOpacity = 1.0;
      animateGain = true;
    });
  } catch (e) {
    print('Erro ao adicionar saldo Solana: $e');
  }
  
  // ... resto do código ...
}
```

### 3.6 Atualizar UI do Saldo

No método `build`:

```dart
loading
    ? const CircularProgressIndicator(strokeWidth: 2)
    : AnimatedScale(
        scale: animateGain ? 1.55 : 1.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        child: Text(
          _bubbleCoinBalance.toStringAsFixed(8), // Usar a nova variável
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff21537f),
            fontSize: 19,
            letterSpacing: 1,
          ),
        ),
      ),
```

### 3.7 Atualizar Progresso Solana

```dart
double progressToSol = (_bubbleCoinBalance % solTriggerThreshold) /
    solTriggerThreshold;
```

## 🔌 Passo 4: Atualizar SupabaseService

No arquivo `lib/services/supabase_service.dart`:

### 4.1 Adicionar Import

```dart
import 'balance_service.dart';
```

### 4.2 Atualizar ou Adicionar Métodos

```dart
// Remova os métodos antigos de gerenciamento de saldo e use o BalanceService
Future<double> getBubbleCoinBalance(String userId) async {
  return await BalanceService().getBubbleCoinBalance(userId);
}

Future<void> addBubbleCoin(String userId, double amount) async {
  await BalanceService().updateBubbleCoinBalance(userId, amount);
}
```

## 🎯 Passo 5: Adicionar Navegação para Histórico

Em qualquer tela onde você queira adicionar o botão de histórico de transações:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionHistoryScreen(
          userId: userId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.history),
  label: const Text('Histórico'),
)
```

## ✅ Passo 6: Testar

1. Execute o app
2. Jogue e colete moedas
3. Verifique que o saldo é atualizado corretamente
4. Acesse a Exchange screen
5. Teste conversões entre BUBBLE e outras moedas
6. Verifique o histórico de transações

## 🐛 Troubleshooting

### Erro: `shared_preferences` não encontrado

Verifique se está no `pubspec.yaml`:

```yaml
dependencies:
  shared_preferences: ^2.2.3
```

### Saldo não persiste após fechar o app

- Verifique se o schema do Supabase foi aplicado corretamente
- Confirme que a coluna `bubble_coin_balance` existe na tabela `users`

### Conversão não funciona

- Verifique se as tabelas `exchange_transactions` e `wallets` foram criadas
- Confirme as políticas RLS no Supabase

## 📚 Recursos Adicionais

- **BalanceService**: Gerencia cache local e sincronização com Supabase
- **Exchange Screen**: Interface para conversão de moedas
- **Transaction History**: Visualização unificada de todas as transações

## 🎉 Conclusão

Após seguir todos os passos:

- ✅ Sistema de saldos centralizado e eficiente
- ✅ Cache local para performance
- ✅ Suporte offline
- ✅ Exchange funcional com conversões
- ✅ Histórico completo de transações

**Boa sorte com o desenvolvimento do BubblesChain! 🫧⛓️**
