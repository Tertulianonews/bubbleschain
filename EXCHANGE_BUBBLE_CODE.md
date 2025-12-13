# Código para Adicionar à Bolha Exchange

## 1. Método _drawExchangeMoneyEffect

Adicione este método na classe `BubblesPainter`, logo antes do método `_drawStar`:

```dart
  // Especial: Efeitos de cifrões orbitando para a bolha EXCHANGE
  void _drawExchangeMoneyEffect(Canvas canvas, UserBubble bubble, double left,
      double top, double drawSize, double opacity) {
    if (opacity < 0.1) return;

    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final double centerX = left + drawSize / 2;
    final double centerY = top + drawSize / 2;

    // Cor dourada para dinheiro
    final Color goldColor = Color(0xFFFFD700);

    // Cifrão grande no centro
    final TextPainter bigDollarPainter = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          fontSize: drawSize * 0.5,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(opacity),
          shadows: [
            Shadow(
              blurRadius: 8,
              color: goldColor.withOpacity(0.8 * opacity),
            ),
            Shadow(
              blurRadius: 16,
              color: goldColor.withOpacity(0.5 * opacity),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    bigDollarPainter.layout();
    bigDollarPainter.paint(
      canvas,
      Offset(
        centerX - bigDollarPainter.width / 2,
        centerY - bigDollarPainter.height / 2 - drawSize * 0.1,
      ),
    );

    // Texto "EXCHANGE" abaixo do cifrão grande
    final TextPainter exchangeTextPainter = TextPainter(
      text: TextSpan(
        text: 'EXCHANGE',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontWeight: FontWeight.w900,
          fontSize: drawSize * 0.16,
          color: Colors.white.withOpacity(opacity),
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              blurRadius: 6,
              color: goldColor.withOpacity(0.6 * opacity),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    exchangeTextPainter.layout();
    exchangeTextPainter.paint(
      canvas,
      Offset(
        centerX - exchangeTextPainter.width / 2,
        centerY + drawSize * 0.22,
      ),
    );

    // Cifrões pequenos orbitando ao redor
    final int dollarCount = 8;
    final double orbitRadius = drawSize * 0.55;

    for (int i = 0; i < dollarCount; i++) {
      final double baseAngle = (i * 2 * pi / dollarCount);
      final double speed = 0.4 + 0.1 * sin(i * 0.5);
      final double angle = (time * speed + baseAngle) % (2 * pi);

      // Variação sutil no raio orbital
      final double radiusVariation = orbitRadius + (5 * sin(time * 1.3 + i * 0.7));

      // Posição do cifrão pequeno
      final double dollarX = centerX + radiusVariation * cos(angle);
      final double dollarY = centerY + radiusVariation * sin(angle);

      // Tamanho do cifrão pequeno com animação
      final double dollarSize = drawSize * (0.12 + 0.03 * sin(time * 2.0 + i * 0.6));

      // Opacidade variável para efeito de cintilação
      final double dollarOpacity = 0.7 + 0.3 * sin(time * 2.5 + i * 0.9);

      // Desenhar cifrão pequeno
      final TextPainter smallDollarPainter = TextPainter(
        text: TextSpan(
          text: '\$',
          style: TextStyle(
            fontSize: dollarSize,
            fontWeight: FontWeight.w900,
            color: goldColor.withOpacity(dollarOpacity * opacity),
            shadows: [
              Shadow(
                blurRadius: 4,
                color: goldColor.withOpacity(0.6 * dollarOpacity * opacity),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      smallDollarPainter.layout();
      smallDollarPainter.paint(
        canvas,
        Offset(
          dollarX - smallDollarPainter.width / 2,
          dollarY - smallDollarPainter.height / 2,
        ),
      );

      // Brilho sutil ao redor do cifrão pequeno
      final Paint dollarGlowPaint = Paint()
        ..color = goldColor.withOpacity(0.15 * dollarOpacity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(
        Offset(dollarX, dollarY),
        dollarSize * 0.6,
        dollarGlowPaint,
      );
    }

    // Efeito de brilho dourado ao redor da bolha
    final Paint glowPaint = Paint()
      ..color = goldColor.withOpacity(0.15 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(centerX, centerY),
      drawSize / 2 + 8,
      glowPaint,
    );
  }
```

## 2. Chamada ao Método no paint()

No método `paint()` da classe `BubblesPainter`, adicione esta verificação logo após a verificação de
`isCryptoBubble`:

```dart
      // EXCHANGE bubble: draw gold dollar signs special effect
      final bool isExchangeBubble = bubble.id == 'exchange_bubble';

      if (isExchangeBubble && opacity > 0.3) {
        _drawExchangeMoneyEffect(canvas, bubble, left, top, drawSize, opacity);
      }
```

## 3. Remover Efeitos Padrão da Bolha Exchange

Na seção onde as bolhas especiais são renderizadas (por volta da linha onde há
`else if (bubble.id == 'tron_bubble')`), adicione:

```dart
} else if (bubble.id == 'exchange_bubble') {
  // Exchange não usa efeitos padrão - usa apenas _drawExchangeMoneyEffect
  // Apenas desenhar círculo transparente
  final paint = Paint()
    ..color = bubble.color.withOpacity(0.05 * opacity)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
      Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
      paint);
```

## 4. Adicionar exchange_bubble à lista de IDs especiais

Onde você vê:

```dart
final bool isSpecial = bubble.id == 'game_bubble' ||
    bubble.id == 'terlinet_word' ||
    bubble.id == 'bitcoin_bubble' ||
    bubble.id == 'canais_bubble' ||
    bubble.id == 'tron_bubble' ||
    bubble.id == 'toncoin_bubble';
```

Adicione:

```dart
final bool isSpecial = bubble.id == 'game_bubble' ||
    bubble.id == 'terlinet_word' ||
    bubble.id == 'bitcoin_bubble' ||
    bubble.id == 'canais_bubble' ||
    bubble.id == 'tron_bubble' ||
    bubble.id == 'toncoin_bubble' ||
    bubble.id == 'exchange_bubble';
```

## 5. Excluir exchange_bubble dos tratamentos padrão

Onde você vê verificações como:

```dart
if (bubble.avatarUrl.isNotEmpty && bubble.id != 'game_bubble' &&
    bubble.id != 'terlinet_word' &&
    bubble.id != 'bitcoin_bubble' &&
    bubble.id != 'canais_bubble' &&
    bubble.id != 'tron_bubble' &&
    bubble.id != 'toncoin_bubble') {
```

Adicione:

```dart
if (bubble.avatarUrl.isNotEmpty && bubble.id != 'game_bubble' &&
    bubble.id != 'terlinet_word' &&
    bubble.id != 'bitcoin_bubble' &&
    bubble.id != 'canais_bubble' &&
    bubble.id != 'tron_bubble' &&
    bubble.id != 'toncoin_bubble' &&
    bubble.id != 'exchange_bubble') {
```

## Resultado

A bolha Exchange agora terá:

- Um cifrão ($) grande no centro
- O texto "EXCHANGE" abaixo do cifrão
- 8 cifrões menores orbitando ao redor
- Efeito de brilho dourado
- Sem os efeitos neon padrão das outras bolhas especiais

A animação dos cifrões pequenos cria um efeito visual elegante de dinheiro flutuando!
