// lib/player.dart

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/flame_audio.dart';

import 'corre_corre_game.dart';
import 'game_screen.dart';
import 'obstacle.dart';

const double LARGURA_REAL = 130.0;
const double ALTURA_REAL = 203.0;
const double SCALE = 0.5;
const double LARGURA_TELA = LARGURA_REAL * SCALE;
const double ALTURA_TELA = ALTURA_REAL * SCALE;
const double AJUSTE_VERTICAL = 98.0;
const double FORCA_PULO = 1000.0;

class Player extends SpriteAnimationComponent
    with HasGameRef<CorreCorreGame>, CollisionCallbacks {
  final double groundLevel;
  final GameScreen gameScreen;

  Player({
    required this.groundLevel,
    required this.gameScreen,
  }) : super(size: Vector2(LARGURA_TELA, ALTURA_TELA));

  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _jumpAnimation;

  final double _gravity = 35;
  double _velocityY = 0;
  bool _isOnGround = true;

  @override
  Future<void> onLoad() async {
    priority = 10;
    anchor = Anchor.bottomLeft;

    final runImage = await game.images.load(game.selectedCharacterSprites);
    final sheetSize = Vector2(LARGURA_REAL, ALTURA_REAL);
    final spriteSheet = SpriteSheet(image: runImage, srcSize: sheetSize);
    _idleAnimation = spriteSheet.createAnimation(row: 0, stepTime: 1, to: 1);
    _runAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.15, to: 2);

    final jumpSprite = await game.loadSprite(game.selectedJumpSprite);
    final jumpFrame = SpriteAnimationFrame(jumpSprite, 1);
    _jumpAnimation = SpriteAnimation([jumpFrame], loop: false);

    animation = _idleAnimation;
    position = Vector2(120, groundLevel + AJUSTE_VERTICAL);

    add(RectangleHitbox());
  }

  void run() {
    animation = _runAnimation;
  }

  void idle() {
    animation = _idleAnimation;
  }

  Future<void> changeToVictorySprite() async {
    final victorySprite = await game.loadSprite(game.selectedVictorySprite);
    final victoryFrame = SpriteAnimationFrame(victorySprite, 1);
    animation = SpriteAnimation([victoryFrame], loop: false);
    size = Vector2(136.0, 203.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isOnGround) {
      _velocityY += _gravity;
      position.y += _velocityY * dt;
    }

    final groundY = groundLevel + AJUSTE_VERTICAL;
    if (position.y >= groundY && gameScreen.state != GameState.gameOver) {
      position.y = groundY;
      _velocityY = 0;
      if (!_isOnGround) {
        _isOnGround = true;
        animation = _runAnimation;
      }
    }

    if (gameScreen.state == GameState.gameOver &&
        position.y > game.size.y + size.y) {
      gameScreen.onPlayerFellOffScreen();
    }
  }

  // ## MÉTODO CORRIGIDO E NO LUGAR CERTO ##
  void jump() {
    if (_isOnGround) {
      // Toca o som do salto
      FlameAudio.play('salto.mp3');

      _velocityY = -FORCA_PULO;
      _isOnGround = false;
      animation = _jumpAnimation;
    }
  }

  void die() {
    removeWhere((component) => component is RectangleHitbox);
    _velocityY = -600;
    _isOnGround = false;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Obstacle) {
      if (_velocityY > 0) {
        position.y = other.position.y - other.size.y;
        _velocityY = 0;
        _isOnGround = true;
        animation = _runAnimation;
      } else {
        if (gameScreen.state == GameState.jogando) {
          gameScreen.onPlayerDied();
        }
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Obstacle) {
      _isOnGround = false;
    }
  }

  bool get isOnMainGround {
    final expectedY = groundLevel + AJUSTE_VERTICAL;
    return _isOnGround && (position.y - expectedY).abs() < 1.0;
  }
}