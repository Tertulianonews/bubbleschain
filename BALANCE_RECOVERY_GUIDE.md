# 💰 Guia de Integração com Saldos Existentes

## ✅ Situação Atual: Seus Dados Já Existem!

Você **já tem uma tabela `userBalances`** no Supabase com os saldos reais dos usuários na coluna
`bubblecoin_balance`. O app foi atualizado para buscar os dados da tabela correta!

### 📊 Estrutura da Tabela `userBalances`:

```
- user_id (uuid) - ID do usuário
- bubblecoin_balance (numeric) - Saldo em BUBBLE coins
- updated_at (timestamp) - Data da última atualização
```

---

## ✅ O Que Foi Feito

### 1. **Atualização do BalanceService** ✅

- Agora busca saldos de `userBalances.bubblecoin_balance` (correto)
- Antes buscava de `users.bubble_coin_balance` (errado)
- Sistema de cache mantido para performance

### 2. **Sistema de Atualização** ✅

- Quando usuário coleta moedas nos jogos, atualiza `userBalances.bubblecoin_balance`
- Quando usuário coleta moedas nos jogos, atualiza `userBalances.updated_at`
- Mantém sincronização com SharedPreferences (offline)

### 3. **Bônus de Boas-Vindas** ✅

- **NÃO** será dado para usuários que já têm saldo
- Apenas usuários novos com saldo = 0 recebem bônus
- Seus usuários existentes mantêm seus saldos reais!

---

## 🎮 Teste Agora!

1. **Execute o app:**
   ```bash
   flutter run
   ```

2. **Entre em qualquer jogo** (Terlinet ou Bubble Game)

3. **Observe o console:**
   ```
   Usuário já possui saldo de 0.000001550000000000010 BUBBLE - sem bônus
   ```
   OU para novos usuários:
   ```
   ✅ Bônus de boas-vindas aplicado!
   ```

4. **Verifique o saldo no jogo:**
   - Deve mostrar o saldo real do Supabase
   - Exemplo: `0.00000155` BUBBLE

---

## 🔄 Como Funciona Agora

### Fluxo de Leitura de Saldo:

1. App tenta ler do **cache local** (válido por 1 minuto)
2. Se não houver cache, busca de **userBalances** no Supabase
3. Se falhar, busca de **SharedPreferences** (offline)
4. Atualiza cache para próximas leituras

### Fluxo de Atualização de Saldo:

1. Usuário coleta moeda no jogo (+0.00000001 BUBBLE)
2. App busca saldo atual de **userBalances**
3. Calcula novo saldo (atual + ganho)
4. Atualiza **userBalances.bubblecoin_balance** no Supabase
5. Atualiza **userBalances.updated_at** com timestamp atual
6. Atualiza cache local
7. Salva em SharedPreferences (backup offline)

---

## 📊 Verificar Seus Dados (OPCIONAL)

Se quiser ver estatísticas dos seus saldos, execute no **Supabase SQL Editor**:

```sql
-- Estatísticas gerais
SELECT 
  COUNT(*) as total_users,
  SUM(CASE WHEN bubblecoin_balance > 0 THEN 1 ELSE 0 END) as users_with_balance,
  SUM(bubblecoin_balance) as total_bubble_coins,
  AVG(bubblecoin_balance) as average_balance,
  MAX(bubblecoin_balance) as highest_balance
FROM userBalances;

-- Top 10 usuários com mais BUBBLE
SELECT 
  user_id,
  bubblecoin_balance,
  updated_at
FROM userBalances
ORDER BY bubblecoin_balance DESC
LIMIT 10;
```

---

## 🏦 Inicializar Wallets da Exchange (OPCIONAL)

Se você ainda não tem a tabela `wallets` criada, execute este SQL:

```sql
-- Criar wallets para todos os usuários existentes
INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'USDT', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'BTC', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'ETH', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'TON', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;
```

---

## ✅ Checklist Final

- ✅ App atualizado para ler de `userBalances`
- ✅ App atualizado para escrever em `userBalances`
- ✅ Sistema de cache funcionando
- ✅ Suporte offline implementado
- ✅ Bônus apenas para usuários novos (saldo = 0)
- ✅ Usuários existentes mantêm seus saldos reais
- ✅ Exchange configurada para conversões

---

## 🎯 Resultado Final

### Para Usuários Existentes:

- ✅ Saldos preservados (ex: 0.00000155 BUBBLE)
- ✅ Podem continuar jogando e acumulando
- ✅ Podem converter para USDT/BTC/ETH/TON na Exchange

### Para Novos Usuários:

- ✅ Recebem 1.0 BUBBLE de bônus ao primeiro jogo
- ✅ Registro automático em `userBalances`
- ✅ Mesmas funcionalidades dos usuários antigos

---

## 📱 Testando Funcionalidades

### 1. Teste de Coleta de Moedas:

- Entre no jogo
- Colete moedas
- Saldo deve aumentar (ex: de 0.00000155 para 0.00000156)

### 2. Teste de Sincronização:

- Jogue e colete moedas
- Feche o app
- Abra novamente
- Saldo deve estar correto (sincronizado)

### 3. Teste de Exchange:

- Vá para Exchange Screen
- Veja seu saldo de BUBBLE
- Tente converter para USDT (se tiver saldo suficiente)

### 4. Teste de Histórico:

- Vá para Exchange → Transações
- Veja suas conversões e atividades

---

## 🚀 Está Tudo Pronto!

**Não precisa fazer mais nada!** O app já está configurado corretamente para:

- ✅ Ler saldos existentes do Supabase
- ✅ Atualizar saldos quando usuários jogam
- ✅ Preservar dados dos usuários antigos
- ✅ Dar bônus apenas para novos usuários

Execute o app e aproveite! 🎉

---

## 🆘 Problemas Comuns

### "Saldo aparece 0.00000000"

**Solução:**

- Verifique se o user_id está correto
- Execute a query de verificação no Supabase
- Limpe o cache: `_balanceService.clearCache()`

### "Erro ao atualizar saldo"

**Solução:**

- Verifique permissões RLS da tabela `userBalances`
- Confirme que o usuário está autenticado
- Veja os logs do console para mais detalhes

### "Bônus dado para usuário com saldo"

**Solução:**

- Limpe SharedPreferences: desinstale e reinstale o app
- O bônus só deve ser dado uma vez e apenas se saldo = 0

---

**Tudo funcionando?** Os usuários agora veem seus saldos reais do Supabase! 🎊