import 'package:flutter/material.dart';

class CounterLabel extends StatelessWidget {
  const CounterLabel({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text('$count', style: Theme.of(context).textTheme.headlineMedium);
  }
}
