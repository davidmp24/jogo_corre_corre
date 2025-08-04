// lib/main.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'corre_corre_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Key key = UniqueKey();
  late CorreCorreGame _game;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _game = CorreCorreGame(onRestart: restart);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Garante que o foco seja solicitado sempre que a UI for construída
    // É crucial para o RawKeyboardListener funcionar.
    FocusScope.of(context).requestFocus(_focusNode);

    // ALTERADO: Adicionado RawKeyboardListener para capturar eventos do teclado/joystick
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        // Processa o evento apenas quando a tecla é pressionada (KeyDown)
        if (event is RawKeyDownEvent) {
          _game.handleKeyEvent(event);
        }
      },
      child: GestureDetector(
        onTapDown: (details) {
          _game.handleTapDown(details.localPosition);
        },
        child: GameWidget(
          key: key,
          game: _game,
          // O FocusNode não é mais necessário aqui, pois já está no Listener
        ),
      ),
    );
  }

  void restart() {
    setState(() {
      key = UniqueKey();
      _game = CorreCorreGame(onRestart: restart);
    });
  }
}