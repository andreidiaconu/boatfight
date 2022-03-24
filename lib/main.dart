import 'dart:math';
import 'dart:ui';

import 'package:boatfight/buoyant_two_pane.dart';
import 'package:boatfight/half_opened_orientation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boat Fight for Surface Duo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HalfOpenedOrientation(child: BoatGame()),
    );
  }
}

class BoatGame extends StatelessWidget {
  const BoatGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final halfOpenedOrientation = HalfOpenedOrientation.of(context);
    bool undecided = halfOpenedOrientation.screenWithCameraPositionUndecided;
    final playerOne = halfOpenedOrientation.screenWithCameraPosition ==
        ScreenWithCameraPosition.uprightVertical;

    final yourBoard = GameBoard(playerOne: playerOne, info: 'This is your board. It always sits at the top',);
    final opponentBoard = GameBoard(playerOne: playerOne, info: 'This is your opponent\'s board. It always sits at the bottom',);
    final flipInstructions = Material(
      color: Colors.grey[300],
      child: const Center(
        child: Text('Place the device on a table in laptop mode.'),
      ),
    );

    return BuoyantTwoPane(
      topPane: undecided
          ? Transform.rotate(
              angle: pi,
              child: flipInstructions,
            )
          : yourBoard,
      bottomPane: undecided ? flipInstructions : opponentBoard,
    );
  }
}

class GameBoard extends StatelessWidget {
  const GameBoard({
    Key? key,
    required this.playerOne,
    required this.info,
  }) : super(key: key);

  final bool playerOne;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: playerOne ? Colors.blue[300] : Colors.orange[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(info),
          SizedBox(height: 32),
          Text('You are player'),
          Text(
            playerOne ? "1" : "2",
            style: const TextStyle(fontSize: 124),
          )
        ],
      ),
    );
  }
}

