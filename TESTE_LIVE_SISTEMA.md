# 🧪 Como Testar o Sistema de Live

## 📋 Pré-requisitos

1. ✅ **Migration SQL executada** no Supabase
2. ✅ **Permissões configuradas** no Android/iOS
3. ✅ **2 dispositivos físicos** (ou 1 físico + 1 emulador)
4. ✅ **Mesma conta Supabase** configurada em ambos

## 🎯 Teste Básico - Passo a Passo

### **Dispositivo 1 (Host):**

1. **Abra o app** e faça login
2. **Clique na sua bolha** (foto de perfil no canto superior esquerdo)
3. **Toque "Iniciar Live Video"**
4. **Permita acesso** à câmera e microfone
5. **Aguarde** a câmera inicializar
6. **Toque "Iniciar Live"**
7. ✅ **Você deve ver** o feed da sua câmera
8. ✅ **Deve aparecer** "AO VIVO • 0" no topo

### **Dispositivo 2 (Viewer):**

1. **Abra o app** com usuário diferente
2. **Na tela de bolhas**, procure a bolha do usuário que está ao vivo
3. ✅ **Você deve ver** um círculo vermelho pulsante na bolha
4. ✅ **Deve aparecer** um preview em miniatura em cima da bolha
5. ✅ **Deve ter** o texto "LIVE" pequeno na bolha
6. **Clique na bolha** da pessoa que está ao vivo
7. ✅ **Deve abrir** a tela de live como viewer
8. ✅ **Deve mostrar** "Assistindo live de [nome_do_canal]"

## 🔧 Comandos SQL para Testar

### **Verificar Status de Live:**

```sql
SELECT id, nickname, is_live, live_channel, live_started_at 
FROM users 
WHERE is_live = true;
```

### **Marcar Usuário Como Live (Manual):**

```sql
UPDATE users 
SET is_live = true, 
    live_channel = 'teste_manual_123', 
    live_started_at = NOW() 
WHERE id = 'SEU_USER_ID';
```

### **Limpar Todas as Lives:**

```sql
UPDATE users 
SET is_live = false, 
    live_channel = null, 
    live_started_at = null;
```

## 🎨 O Que Esperar Visualmente

### **Bolha Normal:**

```
    ( 👤 )
    [Nome]
```

### **Bolha Live Ativa:**

```
   ┌─────────┐
   │📹 LIVE │  ← Preview pulsante
   └─────────┘
    ( 👤 🔴 )  ← Bolha + indicador vermelho
    [Nome]
```

### **Tela de Live (Host):**

```
┌─────────────────┐
│ AO VIVO • 5     │ ← Header
├─────────────────┤
│                 │
│   📹 CÂMERA     │ ← Feed real
│     REAL        │
│                 │
├─────────────────┤
│  📷     🎤      │ ← Controles
└─────────────────┘
```

### **Tela de Live (Viewer):**

```
┌─────────────────┐
│ Assistindo Live │ ← Header
├─────────────────┤
│                 │
│  ▶️ PLAY CIRCLE │ ← Simulação
│    "Assistindo  │
│   live de..."   │
├─────────────────┤
│      ❌         │ ← Sair
└─────────────────┘
```

## 🐛 Problemas Comuns e Soluções

### **❌ Bolha não mostra indicador LIVE:**

**Causa:** Migration não executada ou status não atualizado

**Solução:**

```sql
-- Verificar se colunas existem
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_live', 'live_channel', 'live_started_at');

-- Se não existirem, executar:
ALTER TABLE users ADD COLUMN is_live BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN live_channel TEXT DEFAULT NULL;
ALTER TABLE users ADD COLUMN live_started_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;
```

### **❌ Câmera não funciona:**

**Causa:** Permissões não configuradas

**Solução Android:**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Solução iOS:**

```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Câmera necessária para lives</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microfone necessário para lives</string>
```

### **❌ Preview não aparece na bolha:**

**Causa:** `LivePreviewWidget` não sendo renderizado

**Verificar:**

1. Status `isLive = true` no banco
2. `bubbles_home_screen.dart` tem o código dos previews
3. `live_preview_widget.dart` existe e funciona

### **❌ Erro "Target of URI doesn't exist":**

**Causa:** Imports incorretos após limpeza

**Solução:** Remover imports não utilizados:

```dart
// REMOVER estas linhas se existirem:
import '../services/webrtc_service.dart';
import '../widgets/live_discovery_widget.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
```

## 📱 Teste em Diferentes Cenários

### **Cenário 1: Live Básica**

- Host inicia live
- Viewer assiste
- Host para live

### **Cenário 2: Múltiplos Viewers**

- Host inicia live
- 2+ viewers assistem
- Contador deve aumentar

### **Cenário 3: Controles**

- Host liga/desliga câmera
- Host liga/desliga microfone
- Interface deve atualizar

### **Cenário 4: Reconexão**

- Host fecha app durante live
- Reabrir app deve limpar status
- Viewers devem parar de ver live

## ✅ Checklist de Teste Completo

### **Configuração:**

- [ ] Migration SQL executada
- [ ] Permissões Android configuradas
- [ ] Permissões iOS configuradas (se aplicável)
- [ ] 2 dispositivos disponíveis

### **Funcionalidade Host:**

- [ ] Clique na própria bolha funciona
- [ ] "Iniciar Live Video" aparece
- [ ] Câmera inicializa corretamente
- [ ] "Iniciar Live" funciona
- [ ] Feed de vídeo aparece
- [ ] Controles de câmera/mic funcionam
- [ ] Contador de viewers funciona
- [ ] "Encerrar Live" funciona

### **Funcionalidade Viewer:**

- [ ] Indicador LIVE aparece na bolha
- [ ] Preview aparece em cima da bolha
- [ ] Clique na bolha abre live
- [ ] Tela de viewer carrega
- [ ] Interface mostra "Assistindo live"
- [ ] Botão sair funciona

### **Sistema de Bolhas:**

- [ ] Status atualiza automaticamente
- [ ] Bolhas mantêm posição
- [ ] Animações funcionam corretamente
- [ ] Performance mantida

## 🚀 Dicas de Debug

### **Console Logs Úteis:**

```dart
print("[DEBUG] Status live: $isLive");
print("[DEBUG] Canal: $liveChannel");
print("[DEBUG] Usuário ID: $userId");
```

### **Verificação Supabase:**

```sql
-- Logs de atividade
SELECT * FROM users WHERE is_live = true;

-- Histórico de lives (se implementado)
SELECT * FROM live_sessions ORDER BY created_at DESC LIMIT 10;
```

### **Flutter Doctor:**

```bash
flutter doctor -v
flutter pub deps
flutter clean && flutter pub get
```

---

## 🎉 Sucesso!

Se todos os itens do checklist passaram, seu sistema de live integrado às bolhas está funcionando
perfeitamente!

O sistema oferece uma experiência única onde as lives são descobertas naturalmente através das
bolhas, sem necessidade de telas ou fluxos separados. 🎥✨