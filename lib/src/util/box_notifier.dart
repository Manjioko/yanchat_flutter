import 'package:flutter/material.dart';
import 'package:yanchat01/src/index.dart';
import 'package:provider/provider.dart';

class BoxNotifier {
  static final BoxNotifier _instance = BoxNotifier._internal();

  factory BoxNotifier() => _instance;

  BoxNotifier._internal();

  static BoxNotifier get instance => _instance;

  static BoxDataNotifier? boxDataNotifier;

  BoxDataNotifier box (BuildContext context, {bool listen = false}) {
    boxDataNotifier ??= Provider.of<BoxDataNotifier>(context, listen: listen);
    return boxDataNotifier!;
  }
}