# 🔗 Integração Educacional Skydoge Blockchain

## 📋 Visão Geral

Esta é uma integração **educacional/demonstrativa** da blockchain **Skydoge** no aplicativo
BubblesChain. A tela apresenta conceitos de blockchain, simulações de mineração e informações sobre
a tecnologia Drivechain.

## ✅ O Que Foi Implementado

### 1. **Arquivos Criados**

- ✅ `lib/screens/skydoge_blockchain_screen.dart` - Tela principal educacional
- ✅ `SKYDOGE_BLOCKCHAIN_CHANNEL_SETUP.sql` - Script SQL para criar o canal

### 2. **Arquivos Modificados**

- ✅ `lib/screens/channels_screen.dart` - Adicionado import e navegação

## 🚀 Como Usar

### Passo 1: Executar o SQL no Supabase

1. Abra o **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Abra o arquivo `SKYDOGE_BLOCKCHAIN_CHANNEL_SETUP.sql`
4. **Copie TODO o conteúdo** do arquivo
5. Cole no SQL Editor do Supabase
6. Clique em **RUN** ou pressione `Ctrl+Enter`

O script irá:

- ✅ Buscar o primeiro usuário do sistema para ser dono do canal
- ✅ Criar o canal "Skydoge Blockchain" com um UUID fixo
- ✅ Verificar se foi criado corretamente

### Passo 2: Reiniciar o Aplicativo

```bash
# Parar o app se estiver rodando
# Depois executar novamente:
flutter run
```

### Passo 3: Acessar o Canal

1. Abra o app
2. Vá para a aba **CANAIS**
3. Procure por **"Skydoge Blockchain"**
4. Clique no canal para abrir a tela educacional

## 🎨 Recursos da Tela

### ⛏️ Mineração Simulada

- Novos blocos são "minerados" a cada 15 segundos
- Altura do bloco incrementa automaticamente
- Hash gerado aleatoriamente para demonstração

### 📊 Estatísticas da Rede

- **Altura do Bloco**: Número atual do bloco
- **Hashrate**: Taxa de processamento da rede (simulado)
- **Nós Ativos**: Quantidade de nós na rede
- **Último Bloco**: Tempo desde o último bloco minerado

### 📦 Blocos Recentes

- Lista dos últimos 10 blocos "minerados"
- Hash do bloco (clique para copiar)
- Número de transações
- Minerador que encontrou o bloco
- Recompensa em SKYDOGE

### 🔗 Tecnologia Drivechain

Explicação sobre:

- Sidechains funcionais
- Transferência bidirecional de moedas
- Segurança preservada
- Experimentação sem riscos

### 🌌 Sidechains Disponíveis

- **EthSide**: Compatibilidade EVM
- **Thunder**: Escalabilidade
- **BitAssets**: NFTs e ativos
- **BitDNS**: Domínios descentralizados
- **Hivemind**: Oráculos descentralizados

### 🔗 Links Úteis

- Website oficial
- Whitepaper
- GitHub
- Block Explorer
- Drivechain Info

## 🎯 Detalhes Técnicos

### Identificação do Canal

O código verifica o canal Skydoge de duas formas:

```dart
// Por UUID fixo
if (channel.id == 'a0a0a0a0-b0b0-c0c0-d0d0-e0e0e0e0e0e0')

// Ou por nome (fallback)
if (channel.name.toLowerCase().contains('skydoge blockchain'))
```

### Animações

```dart
// Rotação do ícone (8 segundos)
_rotationController = AnimationController(
  duration: const Duration(seconds: 8),
  vsync: this,
)..repeat();

// Pulso do indicador online (1.5 segundos)
_pulseController = AnimationController(
  duration: const Duration(milliseconds: 1500),
  vsync: this,
)..repeat(reverse: true);
```

### Mineração de Blocos

```dart
// Simular novo bloco a cada 15 segundos
_blockTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
  // Incrementar altura
  _currentBlockHeight++;
  
  // Adicionar novo bloco
  _recentBlocks.insert(0, BlockInfo(...));
  
  // Manter apenas últimos 10 blocos
  if (_recentBlocks.length > 10) {
    _recentBlocks.removeLast();
  }
});
```

## ⚠️ Importante

### Isso É Uma Demonstração Educacional

Esta tela **NÃO está conectada** à blockchain real Skydoge. É uma **simulação educativa** que
mostra:

- ✅ Como funciona uma blockchain
- ✅ Conceitos de mineração
- ✅ Estrutura de blocos
- ✅ Informações sobre a rede Skydoge
- ❌ NÃO faz transações reais
- ❌ NÃO conecta a nós reais
- ❌ NÃO gerencia chaves privadas

### Para Integração Real

Para conectar à blockchain real Skydoge, seria necessário:

1. **Cliente RPC** ou SDK oficial
2. **Sistema de Carteiras**
    - Gerenciamento de chaves privadas
    - Derivação HD
    - Armazenamento seguro

3. **Assinatura de Transações**
    - Validação de transações
    - Broadcast para a rede
    - Confirmação de blocos

4. **Sincronização com Nós**
    - Conexão com nós da rede
    - Verificação de blocos
    - Atualização em tempo real

## 🐛 Troubleshooting

### Erro: "Canal não aparece na lista"

- ✅ Verifique se o SQL foi executado corretamente no Supabase
- ✅ Recarregue a lista de canais (pull-to-refresh)
- ✅ Verifique se há usuários cadastrados no sistema

### Erro: "Target of URI doesn't exist"

- ✅ Certifique-se que o arquivo `skydoge_blockchain_screen.dart` foi criado
- ✅ Rode `flutter pub get` para atualizar dependências
- ✅ Reinicie o servidor de desenvolvimento

### Erro: "The name 'SkyDogeBlockchainScreen' isn't a class"

- ✅ Verifique se o import está correto no `channels_screen.dart`:
  ```dart
  import 'skydoge_blockchain_screen.dart';
  ```
- ✅ Salve todos os arquivos e recompile o app

## 📚 Recursos Adicionais

### Sobre Skydoge

- 🌐 **Website**: https://skydoge.net
- 📄 **Whitepaper**: https://skydoge.net/whitepaper.pdf
- 💻 **GitHub**: https://github.com/skydogenet
- 🔍 **Explorer**: http://explorer.skydoge.net

### Sobre Drivechain

- 🔗 **Drivechain.info**: https://www.drivechain.info/
- 📖 **BIP 300**: Transferências bidirecionais
- 📖 **BIP 301**: Mineração de merge para sidechains

## 🎓 Aprendizado

Esta integração demonstra:

1. **Conceitos de Blockchain**
    - Estrutura de blocos
    - Hash criptográfico
    - Mineração
    - Consenso

2. **Sidechains**
    - Escalabilidade
    - Funcionalidades específicas
    - Transferência entre chains

3. **Flutter/Dart**
    - Animações com AnimationController
    - Timers periódicos
    - Estados e ciclo de vida
    - Navegação entre telas

## 📝 Licença

Este é um projeto educacional open-source.

## 👨‍💻 Suporte

Se tiver dúvidas ou problemas:

1. Verifique a seção de Troubleshooting
2. Revise os arquivos criados
3. Confira se todos os passos foram seguidos

---

**Desenvolvido com ❤️ para fins educacionais**
