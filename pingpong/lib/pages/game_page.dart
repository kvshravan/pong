import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final userid;
  final opponentid;
  const GamePage({Key? key, required this.userid, required this.opponentid})
      : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      child: Text(widget.opponentid + ' vs ' + widget.userid),
    ));
  }
}
