// lib/obstacle.dart

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'corre_corre_game.dart';
import 'game_screen.dart';

const double AJUSTE_HORIZONTAL_SPAWN = 120.0;

class Obstacle extends SpriteComponent
    with HasGameRef<CorreCorreGame> {
  final String imageName;
  final Vector2 spriteSize;
  final double verticalOffset;
  final GameScreen gameScreen;

  bool _isPassed = false;

  Obstacle({
    required this.imageName,
    required this.spriteSize,
    required this.gameScreen,
    this.verticalOffset = 0.0,
  });

  @override
  Future<void> onLoad() async {
    anchor = Anchor.bottomLeft;
    size = spriteSize;
    sprite = await game.loadSprite(imageName);
    position = Vector2(
      game.size.x + AJUSTE_HORIZONTAL_SPAWN,
      game.size.y - gameScreen.groundHeight + verticalOffset,
    );

    final hitboxW = spriteSize.x * 0.3;
    final hitboxH = spriteSize.y * 0.2;
    final hitboxY = (spriteSize.y - hitboxH) / 2;
    add(
      RectangleHitbox(
        position: Vector2(0, hitboxY),
        size: Vector2(hitboxW, hitboxH),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameScreen.state == GameState.jogando) {
      position.x -= 200 * dt;
    }

    if (!_isPassed && position.x < gameScreen.player.position.x) {
      _isPassed = true;
      gameScreen.increaseScore();
    }

    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}
