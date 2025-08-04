// lib/splash_screen.dart

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'corre_corre_game.dart';

class SplashScreen extends Component with HasGameRef<CorreCorreGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    // --- Lógica da imagem de fundo (inalterada) ---
    final splashSprite = await game.loadSprite('splash.png');
    final imageSize = splashSprite.originalSize;
    final screenSize = game.size;
    final screenAspectRatio = screenSize.x / screenSize.y;
    final imageAspectRatio = imageSize.x / imageSize.y;
    late Vector2 newSize;
    if (imageAspectRatio > screenAspectRatio) {
      newSize = Vector2(screenSize.y * imageAspectRatio, screenSize.y);
    } else {
      newSize = Vector2(screenSize.x, screenSize.x / imageAspectRatio);
    }
    add(SpriteComponent(
      sprite: splashSprite,
      size: newSize,
      anchor: Anchor.center,
      position: screenSize / 2,
    ));

    // --- Início da nova Lógica da Barra de Carregamento ---

    // 1. Define as dimensões e posição da barra.
    final double barWidth = screenSize.x * 0.7; // 70% da largura da tela
    const double barHeight = 25.0;
    final barPosition = Vector2(
      screenSize.x / 2, // Centralizada horizontalmente
      screenSize.y * 0.85, // Na parte de baixo da tela
    );

    // 2. Cria o fundo da barra (a parte "vazia").
    final backgroundBar = RectangleComponent(
      size: Vector2(barWidth, barHeight),
      position: barPosition,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.4), // Cor de fundo
      children: [
        // Adiciona um contorno branco para dar estilo
        RectangleComponent(
          size: Vector2(barWidth, barHeight),
          paint: Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        ),
      ],
    );
    add(backgroundBar);

    // 3. Cria a barra de progresso (a parte que "enche").
    final progressBar = RectangleComponent(
      size: Vector2(0, barHeight), // Começa com largura 0
      position: Vector2(
        barPosition.x - barWidth / 2, // Alinhada à esquerda do fundo
        barPosition.y,
      ),
      anchor: Anchor.centerLeft,
      paint: Paint()..color = const Color(0xFF38B000), // Cor do progresso
    );
    add(progressBar);

    // 4. Anima a largura da barra de progresso.
    // A animação durará 8 segundos, preenchendo a barra completamente.
    const double loadingDuration = 8.0;
    progressBar.add(
      SizeEffect.to(
        Vector2(barWidth, barHeight),
        EffectController(duration: loadingDuration),
      ),
    );

    // 5. Mantém o timer para navegar para o menu após o carregamento.
    add(TimerComponent(
      period: loadingDuration,
      onTick: () => game.router.pushReplacementNamed('menu'),
      removeOnFinish: true,
    ));
  }
}