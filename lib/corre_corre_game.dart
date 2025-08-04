// lib/corre_corre_game.dart

import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';

import 'game_screen.dart';
import 'menu_screen.dart';
import 'splash_screen.dart';

class CorreCorreGame extends FlameGame {
  final VoidCallback onRestart;
  late final RouterComponent router;

  String selectedCharacterSprites = 'player_sprites.png';
  String selectedVictorySprite = 'joia.png';
  String selectedJumpSprite = 'jup.png';

  int currentLevel = 1;
  late final List<Map<String, dynamic>> levelData;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  List<String> _bgmPlaylist = [];
  int _currentTrackIndex = 0;

  CorreCorreGame({required this.onRestart}) {
    _bgmPlayer.onPlayerComplete.listen((_) {
      _playNextInPlaylist();
    });
  }

  void playBgm(String filename, {bool loop = true}) async {
    await _bgmPlayer.stop();
    _bgmPlaylist.clear();
    _currentTrackIndex = 0;
    _bgmPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
    await _bgmPlayer.play(AssetSource(filename));
  }

  void playBgmPlaylist(List<String> tracks) async {
    await _bgmPlayer.stop();
    _bgmPlaylist = tracks;
    _currentTrackIndex = 0;
    if (_bgmPlaylist.isNotEmpty) {
      _playNextInPlaylist();
    }
  }

  void _playNextInPlaylist() async {
    if (_bgmPlaylist.isEmpty) return;
    final trackToPlay = _bgmPlaylist[_currentTrackIndex];
    _currentTrackIndex = (_currentTrackIndex + 1) % _bgmPlaylist.length;
    await _bgmPlayer.play(AssetSource(trackToPlay));
  }

  void stopBgm() {
    _bgmPlayer.stop();
  }

  void handleTapDown(Offset localPosition) {
    final tapPosition = Vector2(localPosition.dx, localPosition.dy);
    final currentScreen = router.currentRoute.children.first;

    if (currentScreen is GameScreen) {
      currentScreen.handleTap();
    } else if (currentScreen is MenuScreen) {
      currentScreen.handleTap(tapPosition);
    }
  }

  void handleKeyEvent(RawKeyEvent event) {
    final currentScreen = router.currentRoute.children.first;

    if (currentScreen is GameScreen) {
      currentScreen.handleKeyEvent(event);
    } else if (currentScreen is MenuScreen) {
      currentScreen.handleKeyEvent(event);
    }
  }

  void loadNextLevel() {
    if (currentLevel < levelData.length) {
      currentLevel++;
      router.pushReplacement(
        Route(() => GameScreen(levelData: levelData[currentLevel - 1])),
      );
    } else {
      goToMenu();
    }
  }

  void restartCurrentLevel() {
    router.pushReplacement(
      Route(() => GameScreen(levelData: levelData[currentLevel - 1])),
    );
  }

  void goToMenu() {
    currentLevel = 1;
    router.pushReplacementNamed('menu');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final soundFiles = [
      'som_confirmacao.mp3',
      'menu_personagem.mp3',
      'regressiva.mp3',
      'fazenda.mp3',
      'salto.mp3',
      'game_over.mp3',
      'dino1.mp3',
      'dino2.mp3',
      'credito.mp3',
    ];

    // ## ALTERAÇÃO AQUI ##
    // Trocamos 'FlameAudio.preload(sound)' por 'FlameAudio.audioCache.load(sound)'.
    for (final sound in soundFiles) {
      await FlameAudio.audioCache.load(sound);
    }
    // ## FIM DA ALTERAÇÃO ##

    levelData = [
      {
        'level': 1,
        'background': 'fundo_fazenda.png',
        'ground': 'chao.png',
        'obstacles': [ObstacleType.vaca, ObstacleType.zebra, ObstacleType.cavalo, ObstacleType.girafa],
        'pointsToWin': 10,
      },
      {
        'level': 2,
        'background': 'fundo_jurask.png',
        'ground': 'chao.png',
        'obstacles': [ObstacleType.dino1, ObstacleType.dino2, ObstacleType.dino3, ObstacleType.dino4, ObstacleType.dino5, ObstacleType.dino6],
        'pointsToWin': 15,
      },
      {
        'level': 3,
        'background': 'fundo_fazenda.png',
        'ground': 'chao.png',
        'obstacles': ObstacleType.values,
        'pointsToWin': 20,
      },
    ];

    add(
      router = RouterComponent(
        initialRoute: 'splash',
        routes: {
          'splash': Route(SplashScreen.new),
          'menu': Route(MenuScreen.new),
          'gameplay': Route(() => GameScreen(levelData: levelData[currentLevel - 1])),
        },
      ),
    );
  }
}