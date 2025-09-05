# 📹 Configuração de Live Video - BubblesChain

## 🎯 Visão Geral

Implementamos funcionalidade de **vídeo ao vivo simulado** que permite:
- ✅ Lives efêmeras (não armazenadas)
- ✅ Interface moderna e responsiva
- ✅ Compatível com Web e Mobile
- ✅ Contador de viewers em tempo real
- ✅ Descoberta de lives ativas
- ✅ Controles de câmera e microfone

## 🚀 Como Configurar

### 1. **Executar Migration no Supabase**

No seu Dashboard do Supabase:

1. Vá em **SQL Editor**
2. Execute o script SQL abaixo para criar as tabelas necessárias:

```sql
-- Adicionar colunas para status de live video
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_live BOOLEAN DEFAULT FALSE;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS live_channel TEXT DEFAULT NULL;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS live_started_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_users_is_live ON users(is_live);
```

### 2. **Instalar Dependências**
```bash
flutter pub get
```

### 3. **Configurar Permissões (Opcional)**

Para futuras implementações com câmera real:

#### **Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
```

#### **iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera for live video streaming</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for live video streaming</string>
```

## 🎮 Como Usar

### **Para Fazer Live:**
1. No perfil do usuário, toque em **"Iniciar Live Video"**
2. Toque em **"Iniciar Live"**
3. Use os controles para ligar/desligar câmera e microfone
4. Sua live aparecerá na lista de descoberta para outros usuários

### **Para Assistir Lives:**
1. No perfil do usuário, toque em **"Descobrir Lives"**
2. Veja lista de usuários ao vivo
3. Toque em **"Assistir"** em qualquer live

## 💾 O que é Armazenado no Supabase

**Apenas metadados, NÃO os vídeos:**
- ✅ Status se usuário está ao vivo (`is_live`)
- ✅ Nome do canal (`live_channel`)
- ✅ Horário de início (`live_started_at`)

**Os vídeos NÃO são gravados ou transmitidos de verdade - esta é uma implementação de demonstração.
**

## 🎨 Funcionalidades Implementadas

### **LiveVideoWidget**

- Interface de live streaming simulada
- Controle de host vs viewer
- Contador de viewers (simulado)
- Indicador "AO VIVO"
- Controles de câmera e microfone
- Interface responsiva (Web + Mobile)

### **LiveDiscoveryWidget**
- Lista de lives ativas
- Atualização automática a cada 10s
- Interface para descobrir e assistir lives

### **Integração no Perfil**
- Botão para iniciar live
- Botão para descobrir lives
- Gestão de status no Supabase

## 🔧 Versão Atual: Demonstração

**Esta implementação é uma DEMONSTRAÇÃO/PROTOTYPE que:**

- ✅ Simula interface de live streaming
- ✅ Gerencia status no banco de dados
- ✅ Funciona em Web e Mobile
- ✅ Demonstra o fluxo completo de UX

**Para vídeo real, você precisaria integrar:**

- 📹 WebRTC para streaming P2P
- 🌟 Agora.io para streaming profissional
- 📡 Stream server próprio
- 🔐 Sistema de tokens e autenticação

## 🛠 Próximos Passos para Vídeo Real

### **Opção 1: WebRTC (Gratuito)**

```yaml
dependencies:
  flutter_webrtc: ^0.9.36
```

### **Opção 2: Agora.io (Profissional)**

```yaml  
dependencies:
  agora_rtc_engine: ^6.3.2
```

### **Opção 3: Stream Server Próprio**

- Node.js + Socket.io
- FFmpeg para encoding
- RTMP/WebRTC

## ⚡ Performance Atual

- **Latência**: Instantânea (simulado)
- **Compatibilidade**: 100% Web + Mobile
- **Recursos**: Interface completa sem vídeo real
- **Custo**: Gratuito (apenas Supabase)

## 🐛 Troubleshooting

**Live não aparece na descoberta:**
- Verifique se executou a migration no Supabase
- Confirme que `is_live` está sendo atualizado corretamente
- Teste a descoberta após iniciar uma live

**Interface não responsiva:**

- Recarregue o app após mudanças
- Verifique se está na versão mais recente

---

## 🎉 Pronto!

Agora você tem um **sistema completo de live video simulado** integrado ao seu app!

Esta implementação demonstra todo o fluxo de UX e pode ser facilmente expandida com streaming real
quando necessário. 📱✨

## 🚀 Para Implementar Vídeo Real

Quando quiser adicionar streaming real:

1. **Escolha uma tecnologia** (WebRTC, Agora.io, etc.)
2. **Substitua os métodos simulados** em `LiveVideoWidget`
3. **Adicione permissões reais** de câmera/microfone
4. **Configure servidor de streaming** (se necessário)

A estrutura de UI e banco de dados já está pronta! 🎯