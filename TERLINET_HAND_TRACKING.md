# 🤚 TerlineT Hand Tracking - Experiência Interativa Futurista

## 📖 Visão Geral

A bolha **TerlineT** agora possui rastreamento de mãos em tempo real usando a câmera do dispositivo
e Google ML Kit!

Quando o usuário abre a tela de login (ou home após login), a bolha TerlineT:

- ✨ **Detecta a mão do usuário** em tempo real via câmera frontal
- 🎯 **Segue o movimento da mão** com suavidade e precisão
- 🌟 **Partículas orbitam** ao redor da posição da mão
- 🔄 **Fallback elegante**: se não houver câmera/permissão, a bolha apenas anima normalmente no
  centro

---

## 🛠️ Tecnologias Utilizadas

- **Flutter Camera**: Acesso à câmera do dispositivo
- **Google ML Kit Pose Detection**: Detecção de pontos corporais (pulso da mão direita)
- **Custom Painting**: Renderização das partículas e efeitos visuais
- **Permission Handler**: Gerenciamento de permissões de câmera

---

## 🚀 Como Funciona

### 1. Inicialização

Quando o widget `TerlineTParticlesDisplay` é criado:

- Solicita permissão de câmera automaticamente
- Inicializa a câmera frontal (se disponível)
- Configura o detector de pose do ML Kit

### 2. Detecção em Tempo Real

- Processa frames da câmera em baixa resolução (performance)
- Detecta o pulso direito usando ML Kit
- Normaliza as coordenadas (0-1) para qualquer tamanho de tela

### 3. Animação Responsiva

- A bolha TerlineT se move suavemente para seguir a mão
- Partículas orbitam em volta da posição detectada
- Transição suave com `AnimatedPositioned`

### 4. Fallback Inteligente

Se não houver câmera ou permissão:

- A bolha permanece centralizada
- Animação normal das partículas
- Nenhum erro ou crash

---

## 📱 Permissões Necessárias

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Usamos sua câmera para criar experiências interativas com a bolha TerlineT</string>
```

---

## 🎨 Personalização

### Ajustar Sensibilidade

No arquivo `lib/widgets/terline_t_bubble.dart`:

```dart
// Suavidade do movimento (mais alto = mais suave, mas lento)
duration: const Duration(milliseconds: 200),

// Raio das partículas orbitantes
final r = 80 * (0.98 + 0.09 * sin(progress * 2 * pi + p.offsetSeed));
```

### Usar Mão Esquerda

Altere a linha:

```dart
final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
```

Para:

```dart
final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
```

---

## ⚡ Performance

- **Resolução baixa**: Usa `ResolutionPreset.low` para economia de bateria
- **Detecção otimizada**: Processa apenas quando o frame anterior terminou
- **Leve**: Não impacta a performance geral do app

---

## 🐛 Troubleshooting

### A bolha não segue a mão

1. Verifique se a permissão de câmera foi concedida
2. Certifique-se de que há boa iluminação
3. Mantenha a mão visível no quadro da câmera

### Erro de dependência

Execute:

```bash
flutter pub get
flutter clean
flutter run
```

---

## 🎯 Próximos Passos (Futuro)

- [ ] Adicionar glow na mão detectada
- [ ] Efeitos sonoros ao mover a bolha
- [ ] Detecção de gestos (swipe, pinça, etc)
- [ ] Modo multiplayer (2 mãos)

---

**Desenvolvido com ❤️ para criar experiências futuristas e impactantes!**
