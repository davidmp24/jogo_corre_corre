// lib/menu_screen.dart

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'corre_corre_game.dart';

class MenuScreen extends Component with HasGameRef<CorreCorreGame> {
  // ALTERADO: Lógica de seleção
  int _selectedIndex = 0;
  final List<CharacterButton> _characterButtons = [];

  // NOVO: Método para lidar com eventos de teclado/joystick
  void handleKeyEvent(RawKeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      _updateSelection(_selectedIndex + 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _updateSelection(_selectedIndex - 1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select || // Botão 'X' ou 'A' do joystick
        key == LogicalKeyboardKey.space) {
      _characterButtons[_selectedIndex].onSelect();
    }
  }

  // NOVO: Método para atualizar o personagem selecionado
  void _updateSelection(int newIndex) {
    final int newValidIndex = newIndex.clamp(0, _characterButtons.length - 1);

    if (newValidIndex != _selectedIndex) {
      // ALTERADO: Toca o som de seleção de personagem
      FlameAudio.play('menu_personagem.mp3');

      _characterButtons[_selectedIndex].deselect();
      _selectedIndex = newValidIndex;
      _characterButtons[_selectedIndex].select();
    }
  }

  // A lógica de toque continua a funcionar independentemente
  void handleTap(Vector2 tapPosition) {
    for (int i = 0; i < _characterButtons.length; i++) {
      final button = _characterButtons[i];
      if (button.toRect().contains(tapPosition.toOffset())) {
        _updateSelection(i); // Atualiza o índice com base no toque
        button.onSelect(); // Inicia o jogo imediatamente ao tocar
        break;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(
      SpriteComponent(
        sprite: await game.loadSprite('background.png'),
        size: game.size,
        priority: -1,
      ),
    );

    final titleStyle = TextPaint(
      style: const TextStyle(
        fontSize: 80.0,
        fontFamily: 'PressStart2P',
        color: Colors.white,
        shadows: [
          Shadow(blurRadius: 3.0, color: Colors.black, offset: Offset(3.0, 3.0)),
        ],
      ),
    );
    final title = TextComponent(
      text: 'Corre Corre',
      textRenderer: titleStyle,
      anchor: Anchor.center,
      position: Vector2(game.size.x / 2, game.size.y * 0.20),
    );
    add(title);

    const double origW = 509.0, origH = 1024.0;
    const double btnH = 300.0;
    final ratio = origW / origH;
    final btnW = btnH * ratio;
    final Vector2 btnSize = Vector2(btnW, btnH);

    final characters = [
      // ... (sem alterações aqui)
      {
        'name': 'Davi',
        'button': 'bt_davi.png',
        'sprites': 'player_sprites.png',
        'victory': 'joia.png',
        'jump': 'jup.png'
      },
      {
        'name': 'Dino',
        'button': 'bt_dino.png',
        'sprites': 'dino_sprites.png',
        'victory': 'joia_dino.png',
        'jump': 'jump_dino.png'
      },
      {
        'name': 'Boi',
        'button': 'bt_boi.png',
        'sprites': 'boi_sprites.png',
        'victory': 'joia_boi.png',
        'jump': 'jump_boi.png'
      },
    ];

    const double yPos = 0.55;
    for (var i = 0; i < characters.length; i++) {
      final ch = characters[i];
      final button = CharacterButton(
        characterName: ch['name']!,
        buttonSprite: await game.loadSprite(ch['button']!),
        size: btnSize,
        onSelect: () {
          FlameAudio.play('som_confirmacao.wav');
          game.stopBgm(); // Garante que qualquer música de fundo pare
          game.selectedCharacterSprites = ch['sprites']!;
          game.selectedVictorySprite = ch['victory']!;
          game.selectedJumpSprite = ch['jump']!;
          game.router.pushReplacementNamed('gameplay');
        },
      );
      button.position = Vector2(
        game.size.x * (0.28 + (i * 0.22)),
        game.size.y * yPos,
      );
      add(button);
      _characterButtons.add(button); // NOVO: Adiciona o botão à lista
    }

    // NOVO: Seleciona o primeiro personagem por padrão
    if (_characterButtons.isNotEmpty) {
      _characterButtons[_selectedIndex].select();
    }
  }
}

class CharacterButton extends SpriteComponent {
  final VoidCallback onSelect;
  final String characterName;
  bool isSelected = false;

  CharacterButton({
    required Sprite buttonSprite,
    required this.onSelect,
    required this.characterName,
    super.size,
  }) : super(sprite: buttonSprite);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
  }

  void select() {
    if (isSelected) return; // Evita adicionar múltiplos efeitos
    isSelected = true;
    add(
      ScaleEffect.to(
        Vector2.all(1.15),
        EffectController(duration: 0.2),
      ),
    );
  }

  void deselect() {
    if (!isSelected) return; // Evita adicionar múltiplos efeitos
    isSelected = false;
    // Remove qualquer efeito de escala existente antes de adicionar um novo
    removeWhere((component) => component is ScaleEffect);
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.2),
      ),
    );
  }
}