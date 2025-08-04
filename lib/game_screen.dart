// lib/game_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/parallax.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';

import 'corre_corre_game.dart';
import 'player.dart';
import 'obstacle.dart';

enum GameState { contagem, jogando, gameOver, vitoria }
enum ObstacleType {
  vaca,
  zebra,
  cavalo,
  girafa,
  dino1,
  dino2,
  dino3,
  dino4,
  dino5,
  dino6,
}

class GameScreen extends Component
    with HasGameRef<CorreCorreGame>, HasCollisionDetection {
  final Map<String, dynamic> levelData;
  GameScreen({required this.levelData});

  GameState state = GameState.contagem;
  final Random _random = Random();

  final double groundHeight = 100.0;
  late Player player;

  late TextComponent countdownText;
  int countdownValue = 3;

  late ParallaxComponent parallax;
  TimerComponent? obstacleSpawner;

  int score = 0;
  late TextComponent scoreText;
  bool isVictoryPending = false;

  TimerComponent? gameOverTimer;
  final Component gameOverUI = Component();
  final Component victoryUI = Component();

  void handleKeyEvent(RawKeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space) {
      handleTap();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _resetState();

    final bgFile = levelData['background'] as String;
    final groundFile = levelData['ground'] as String;
    parallax = await ParallaxComponent.load(
      [
        ParallaxImageData(bgFile),
        ParallaxImageData(groundFile),
      ],
      baseVelocity: Vector2.zero(),
      velocityMultiplierDelta: Vector2(1.8, 0),
      fill: LayerFill.height,
      alignment: Alignment.bottomCenter,
    );
    add(parallax);

    final groundLevel = gameRef.size.y - groundHeight;
    player = Player(
      groundLevel: groundLevel,
      gameScreen: this,
    );
    add(player);

    final scorePaint = TextPaint(
      style: const TextStyle(
        fontSize: 32,
        fontFamily: 'PressStart2P',
        color: Colors.white,
      ),
    );
    scoreText = TextComponent(
      text: 'Pontos: 0',
      textRenderer: scorePaint,
      anchor: Anchor.topRight,
      position: Vector2(gameRef.size.x - 20, 20),
    );
    add(scoreText);

    startCountdown();
  }

  void _resetState() {
    state = GameState.contagem;
    countdownValue = 3;
    score = 0;
    isVictoryPending = false;
    obstacleSpawner?.timer.stop();
    obstacleSpawner?.removeFromParent();
    obstacleSpawner = null;
    gameOverTimer?.removeFromParent();
    gameOverUI.removeAll(gameOverUI.children.toList());
    victoryUI.removeAll(victoryUI.children.toList());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isVictoryPending && player.isOnMainGround) {
      isVictoryPending = false;
      onPlayerWon();
    }
  }

  void increaseScore() {
    score++;
    scoreText.text = 'Pontos: $score';
    final pontosParaVencer = levelData['pointsToWin'] as int;
    if (score >= pontosParaVencer) {
      isVictoryPending = true;
    }
  }

  Future<void> onPlayerWon() async {
    state = GameState.vitoria;
    game.stopBgm();
    obstacleSpawner?.timer.stop();
    parallax.parallax?.baseVelocity = Vector2.zero();

    final whiteBg = RectangleComponent(
      size: gameRef.size,
      paint: Paint()..color = Colors.white.withOpacity(0),
      priority: 1000,
    );
    victoryUI.add(whiteBg);
    add(victoryUI);

    whiteBg.add(
      OpacityEffect.to(1.0, EffectController(duration: 1.5)),
    );

    player.add(
      MoveToEffect(
        Vector2(gameRef.size.x / 2, player.position.y),
        EffectController(duration: 1.5),
        onComplete: () async {
          player
            ..anchor = Anchor.center
            ..position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.65)
            ..scale.x = -player.scale.x
            ..priority = 1001;
          await player.changeToVictorySprite();

          if (gameRef.currentLevel >= gameRef.levelData.length) {
            final winPaint = TextPaint(
              style: const TextStyle(
                fontSize: 48,
                fontFamily: 'PressStart2P',
                color: Color(0xFFE53935),
              ),
            );
            final textoMissao = TextComponent(
              text: 'MISSÃO COMPLETA',
              textRenderer: winPaint,
              anchor: Anchor.center,
              position: Vector2(gameRef.size.x / 2, gameRef.size.y * 0.28),
              priority: 1001,
            );
            victoryUI.add(textoMissao);

            victoryUI.add(TimerComponent(
              period: 5.0,
              onTick: () async {
                player.removeFromParent();
                textoMissao.removeFromParent();
                whiteBg.removeFromParent();
                game.playBgm('credito.mp3');
                final creditsBg = await game.loadParallaxComponent(
                  [ParallaxImageData('fundo_fim.png')],
                  baseVelocity: Vector2(30, 0),
                  fill: LayerFill.height,
                  priority: 998,
                );
                victoryUI.add(creditsBg);
                final creditsStyle = TextPaint(
                  style: const TextStyle(
                    fontSize: 28.0,
                    fontFamily: 'PressStart2P',
                    color: Colors.white,
                    height: 1.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))],
                  ),
                );
                const String creditsContent =
                    '🎉 MISSÃO CONCLUÍDA! 🦖💨\n\n'
                    'Parabéns!🎉🎉'
                    'Você enfrentou todos os desafios, escapou do T-rex e provou ser um corredor de verdade.🦖'
                    'Seu instinto foi afiado, seus reflexos rápidos, e sua coragem inspiradora!🦖'
                    'Este jogo foi criado com muito carinho como uma homenagem ao meu filho, Davi.\n\n'
                    '"Papai te ama, Davi." 🦖'
                    'Obrigado por jogar e fazer parte dessa aventura especial.🦖'
                    'Desenvolvido em Julho de 2025.';
                final creditsTextBox = TextBoxComponent(
                  text: creditsContent,
                  textRenderer: creditsStyle,
                  align: Anchor.topCenter,
                  boxConfig: TextBoxConfig(maxWidth: game.size.x * 0.8),
                  anchor: Anchor.topCenter,
                  position: Vector2(game.size.x / 2, game.size.y),
                  priority: 1000,
                );
                victoryUI.add(creditsTextBox);
                creditsTextBox.add(
                  MoveToEffect(
                    Vector2(game.size.x / 2, -creditsTextBox.height),
                    EffectController(duration: 85.0),
                    onComplete: () {
                      victoryUI.add(TimerComponent(
                        period: 2.0,
                        onTick: gameRef.onRestart,
                        removeOnFinish: true,
                      ));
                    },
                  ),
                );
              },
              removeOnFinish: true,
            ));
          } else {
            final winPaint = TextPaint(
              style: const TextStyle(
                fontSize: 48,
                fontFamily: 'PressStart2P',
                color: Color(0xFFE53935),
              ),
            );
            final texto = TextComponent(
              text: 'MISSÃO COMPLETA',
              textRenderer: winPaint,
              anchor: Anchor.center,
              position: Vector2(gameRef.size.x / 2, gameRef.size.y * 0.28),
              priority: 1001,
            );
            victoryUI.add(texto);
            victoryUI.add(
              TimerComponent(
                period: 5.0,
                onTick: gameRef.loadNextLevel,
                removeOnFinish: true,
              ),
            );
          }
        },
      ),
    );
  }

  void onPlayerDied() {
    if (state != GameState.jogando) return;
    game.stopBgm();
    FlameAudio.play('game_over.mp3');
    state = GameState.gameOver;
    obstacleSpawner?.timer.stop();
    player.idle();
    player.die();
  }

  void onPlayerFellOffScreen() {
    if (gameOverUI.isMounted) return;
    parallax.parallax?.baseVelocity = Vector2.zero();
    showGameOverUI();
  }

  void showGameOverUI() {
    final overlay = RectangleComponent(
      size: gameRef.size,
      paint: Paint()..color = Colors.black.withOpacity(0.7),
      priority: 1000,
    );
    final overPaint = TextPaint(
      style: const TextStyle(fontSize: 60, fontFamily: 'PressStart2P', color: Colors.red),
    );
    final gameOverText = TextComponent(
      text: 'GAME OVER',
      textRenderer: overPaint,
      anchor: Anchor.center,
      position: Vector2(gameRef.size.x / 2, gameRef.size.y * 0.4),
      priority: 1001,
    );
    int restartCount = levelData['restartSeconds'] as int? ?? 10;
    final restartPaint = TextPaint(
      style: const TextStyle(fontSize: 24, fontFamily: 'PressStart2P', color: Colors.white),
    );
    final restartText = TextComponent(
      text: '$restartCount',
      textRenderer: restartPaint,
      anchor: Anchor.center,
      position: Vector2(gameRef.size.x / 2, gameRef.size.y * 0.6),
      priority: 1001,
    );
    gameOverUI.addAll([overlay, gameOverText, restartText]);
    add(gameOverUI);
    gameOverTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        restartCount--;
        if (restartCount > 0) {
          restartText.text = '$restartCount';
        } else {
          returnToMenu();
        }
      },
    );
    add(gameOverTimer!);
  }

  void restartLevel() {
    gameOverTimer?.removeFromParent();
    gameRef.restartCurrentLevel();
  }

  void returnToMenu() {
    game.stopBgm();
    gameOverTimer?.removeFromParent();
    gameRef.onRestart();
  }

  void spawnObstacle() {
    if (state != GameState.jogando) return;
    final allowed = levelData['obstacles'] as List<ObstacleType>;
    final type = allowed[_random.nextInt(allowed.length)];
    late String imageName;
    late Vector2 spriteSize;
    late double yOffset;
    const scale = 0.9;
    switch (type) {
      case ObstacleType.vaca:
        imageName = 'vaca.png';
        spriteSize = Vector2(120, 95) * scale;
        yOffset = groundHeight;
        break;
      case ObstacleType.zebra:
        imageName = 'zebra.png';
        spriteSize = Vector2(130, 100) * scale;
        yOffset = groundHeight;
        break;
      case ObstacleType.cavalo:
        imageName = 'cavalo.png';
        spriteSize = Vector2(140, 120) * scale;
        yOffset = groundHeight;
        break;
      case ObstacleType.girafa:
        imageName = 'girafa.png';
        spriteSize = Vector2(100, 160) * scale;
        yOffset = groundHeight;
        break;
      case ObstacleType.dino1:
      case ObstacleType.dino2:
      case ObstacleType.dino3:
      case ObstacleType.dino4:
      case ObstacleType.dino5:
      case ObstacleType.dino6:
        imageName = '${type.name}.png';
        spriteSize = Vector2(240, 200) * scale;
        yOffset = groundHeight - 20;
        break;
    }
    final obstacle = Obstacle(
      imageName: imageName,
      spriteSize: spriteSize,
      verticalOffset: yOffset,
      gameScreen: this,
    );
    add(obstacle);
  }

  // ## MÉTODO CORRIGIDO ##
  void startCountdown() {
    final paint = TextPaint(
      style: TextStyle(
        fontSize: 100,
        fontFamily: 'PressStart2P',
        color: Colors.red,
        shadows: const [
          Shadow(
            blurRadius: 2.0,
            color: Colors.black,
            offset: Offset(2, 2),
          ),
        ],
      ),
    );
    countdownText = TextComponent(
      text: countdownValue.toString(),
      textRenderer: paint,
      anchor: Anchor.center,
      position: gameRef.size / 2,
    );
    add(countdownText);

    // Toca o som da contagem uma vez, ANTES de iniciar o timer.
    FlameAudio.play('regressiva.mp3');

    // Adiciona o timer para atualizar o texto e iniciar o jogo.
    // A sintaxe aninhada e incorreta foi removida.
    add(
      TimerComponent(
        period: 1.0,
        repeat: true,
        onTick: () {
          countdownValue--;
          if (countdownValue > 0) {
            countdownText.text = countdownValue.toString();
          } else if (countdownValue == 0) {
            countdownText.text = 'VAI!';
          } else {
            startGame();
            // Remove este timer para que ele não continue executando.
            removeWhere((c) => c is TimerComponent && c != obstacleSpawner && c != gameOverTimer);
          }
        },
      ),
    );
  }

  // ## MÉTODO ATUALIZADO ##
  void startGame() {
    state = GameState.jogando;
    countdownText.removeFromParent();
    parallax.parallax?.baseVelocity = Vector2(100, 0);
    player.run();

    // ADICIONADO: Inicia a música de fundo com base no nível atual
    switch (game.currentLevel) {
      case 1:
        game.playBgmPlaylist(['fazenda.mp3']);
        break;
      case 2:
        game.playBgmPlaylist(['dino1.mp3', 'dino2.mp3']);
        break;
      case 3:
        game.playBgmPlaylist(['dino1.mp3', 'dino2.mp3', 'fazenda.mp3']);
        break;
      default:
      // Caso tenha mais fases, elas tocarão a música da fase 1 por padrão
        game.playBgmPlaylist(['fazenda.mp3']);
    }

    obstacleSpawner = TimerComponent(
      period: 4.0,
      repeat: true,
      onTick: spawnObstacle,
    );
    add(obstacleSpawner!);
  }

  void handleTap() {
    if (state == GameState.jogando) {
      player.jump();
    } else if (state == GameState.gameOver) {
      gameOverTimer?.removeFromParent();
      restartLevel();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    gameOverUI.removeFromParent();
    victoryUI.removeFromParent();
  }
}