# 🎥 Sistema de Live Integrado às Bolhas

## 🎯 Como Funciona

O sistema de live streaming está **totalmente integrado** ao sistema de bolhas existente:

1. **Usuário inicia live** → Aparece um preview na própria bolha dele
2. **Outros usuários veem** → Indicador "LIVE" na bolha + preview pulsante
3. **Para assistir** → Clicam na bolha da pessoa que está ao vivo
4. **Descoberta automática** → Lives aparecem automaticamente nas bolhas

## 🚀 Configuração Rápida

### 1. **Execute a Migration no Supabase**

No seu Dashboard do Supabase → **SQL Editor**:

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

### 2. **Configure Permissões (Android)**

Em `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
```

### 3. **Configure Permissões (iOS)**

Em `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Este app precisa acessar a câmera para transmissões ao vivo</string>
<key>NSMicrophoneUsageDescription</key>
<string>Este app precisa acessar o microfone para transmissões ao vivo</string>
```

## 🎮 Como Usar

### **Para Iniciar uma Live:**

1. **Clique na sua bolha** (canto superior esquerdo)
2. **Toque em "Iniciar Live Video"**
3. **Permita acesso** à câmera e microfone
4. **Toque "Iniciar Live"** quando estiver pronto
5. **Sua bolha mostrará um preview** da live para outros usuários

### **Para Assistir Lives:**

1. **Procure bolhas com indicador "LIVE"** (círculo vermelho pulsante)
2. **Você verá um preview** da live em cima da bolha
3. **Clique na bolha** para assistir em tela cheia
4. **As lives são descobertas automaticamente** - não precisa de tela separada

## 🎨 O que Você Verá

### **Sua Própria Bolha (quando em live):**

- ✅ Preview real da sua câmera
- ✅ Indicador "LIVE" vermelho pulsante
- ✅ Contador de viewers

### **Bolhas de Outros (quando estão ao vivo):**

- ✅ Indicador "LIVE" vermelho pulsante
- ✅ Preview da live em miniatura
- ✅ Clique para assistir em tela cheia

### **Tela de Live (quando assistindo ou transmitindo):**

- ✅ Feed de vídeo real da câmera
- ✅ Controles de câmera/microfone (só para host)
- ✅ Contador de viewers
- ✅ Botão para encerrar live

## 🔧 Funcionalidades Implementadas

### **Para Hosts (quem transmite):**

- ✅ **Câmera real** usando o plugin Camera
- ✅ **Ligar/desligar câmera** durante a live
- ✅ **Ligar/desligar microfone** durante a live
- ✅ **Preview na bolha** para outros usuários verem
- ✅ **Contador de viewers** simulado
- ✅ **Status automático** no Supabase

### **Para Viewers (quem assiste):**

- ✅ **Descoberta automática** de lives nas bolhas
- ✅ **Preview visual** nas bolhas
- ✅ **Clique para assistir** diretamente
- ✅ **Interface de visualização** completa

### **Sistema de Bolhas:**

- ✅ **Indicador visual** para lives ativas
- ✅ **Preview pulsante** em cima da bolha
- ✅ **Integração seamless** com navegação existente
- ✅ **Atualização automática** de status

## 💡 Fluxo Completo

```
1. Usuário clica na própria bolha
2. Tela de perfil abre
3. Clica "Iniciar Live Video"
4. Câmera é inicializada
5. Status is_live = true no Supabase
6. Outros usuários veem indicador na bolha dele
7. Preview aparece em cima da bolha
8. Outros clicam na bolha para assistir
9. LiveVideoWidget abre como viewer
10. Quando encerra: is_live = false
```

## 📱 Compatibilidade

- ✅ **Android** - Câmera nativa funcional
- ✅ **iOS** - Câmera nativa funcional
- ✅ **Web** - Interface funciona, câmera pode ter limitações
- ✅ **Todas as resoluções** - Interface responsiva

## 🐛 Troubleshooting

### **Live não aparece na bolha:**

- Verifique se executou a migration SQL
- Confirme que `is_live` está sendo atualizado no banco
- Reabra o app para atualizar status

### **Câmera não funciona:**

- Verifique permissões de câmera/microfone
- Teste em dispositivo físico (não simulador)
- Confirme que as permissões estão no manifest

### **Preview não aparece:**

- Verifique se `LivePreviewWidget` está sendo renderizado
- Confirme que a bolha tem status `isLive = true`
- Teste com conexão de internet estável

## 🎉 Vantagens desta Abordagem

### **Integração Perfeita:**

- ✅ Usa o sistema de bolhas existente
- ✅ Não precisa de telas separadas
- ✅ Descoberta visual imediata
- ✅ UX intuitiva e familiar

### **Performance:**

- ✅ Uso eficiente de recursos
- ✅ Preview leve em miniatura
- ✅ Atualização automática otimizada
- ✅ Navegação fluida

### **Simplicidade:**

- ✅ Fácil de usar
- ✅ Fácil de entender
- ✅ Fácil de manter
- ✅ Código limpo e organizador

## 🚀 Próximos Passos Opcionais

Se quiser expandir futuramente:

1. **Chat durante live** - Mensagens em tempo real
2. **Reações** - Emojis e likes na tela
3. **Gravação** - Salva no Supabase Storage
4. **Notificações** - Avisa quando amigos fazem live
5. **Múltiplas câmeras** - Troca entre frontal/traseira
6. **Filtros** - Efeitos visuais na câmera

---

## ✨ Conclusão

Agora você tem um **sistema de live streaming completamente integrado** ao seu app de bolhas!

- **Fácil de usar** - Click na bolha, inicia live, outros clicam para assistir
- **Visual atrativo** - Previews pulsantes e indicadores claros
- **Performance otimizada** - Usa recursos de forma eficiente
- **Código limpo** - Integrado à arquitetura existente

**O sistema está pronto para uso imediato!** 🎥✨